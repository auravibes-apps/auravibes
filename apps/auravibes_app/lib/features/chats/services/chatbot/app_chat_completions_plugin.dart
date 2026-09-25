import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

class AppChatCompletionsPlugin extends GenkitPlugin {
  new({
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.codec,
    this.models = const [],
    this.headers,
    this.httpClient,
    this.requestTimeout = const Duration(seconds: 30),
    this.retryWait,
  }) {
    if (name.isEmpty || name.contains('/')) {
      throw GenkitException(
        'Plugin name must be non-empty and must not contain "/". Got: "$name"',
        status: .INVALID_ARGUMENT,
      );
    }
  }

  @override
  final String name;
  final String baseUrl;
  final String apiKey;
  final ChatCompletionsCodec codec;
  final List<ChatCompletionsModelDefinition> models;
  final Map<String, String>? headers;
  final http.Client? httpClient;
  final Duration requestTimeout;
  final Future<void> Function(Duration)? retryWait;

  @override
  Future<List<Action<dynamic, dynamic, dynamic, dynamic>>> init() async => [
    for (final model in models) _createModel(model.name, model.info),
  ];

  @override
  Action<dynamic, dynamic, dynamic, dynamic>? resolve(
    ActionType actionType,
    String name,
  ) => actionType == ActionType.model ? _createModel(name, null) : null;
}

extension on AppChatCompletionsPlugin {
  Model<dynamic> _createModel(String modelName, ModelInfo? info) =>
      Model<dynamic>(
        name: '$name/$modelName',
        fn: (request, context) => _generateModel(modelName, request, context),
        metadata: {'model': ?info?.toJson()},
      );

  Future<ModelResponse> _generateModel(
    String modelName,
    ModelRequest? request,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) {
    if (request == null) {
      return Future<ModelResponse>.error(ArgumentError.notNull('request'));
    }

    final body = codec.buildRequestBody(
      modelName: modelName,
      request: request,
      stream: context.streamingRequested,
    );

    return _generateWithRetry(this, body, context);
  }

  Future<ProviderTransportResponse> _transport(
    Map<String, dynamic> body, {
    required ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
    required void Function(http.StreamedResponse) onResponse,
  }) {
    if (apiKey.trim().isEmpty) {
      throw GenkitException(
        '[$name] API key is required.',
        status: .INVALID_ARGUMENT,
      );
    }
    final request = _request(body, context);
    final client = httpClient ?? http.Client();

    return _sendRequest(client, request, onResponse);
  }

  http.Request _request(
    Map<String, dynamic> body,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) {
    final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

    return http.AbortableRequest(
        'POST',
        Uri.parse(normalized).resolve('chat/completions'),
        abortTrigger: context.cancel?.whenCancelled,
      )
      ..headers.addAll({
        'authorization': 'Bearer ${apiKey.trim()}',
        'content-type': 'application/json',
        ...?headers,
      })
      ..body = jsonEncode(body);
  }

  Future<ProviderTransportResponse> _sendRequest(
    http.Client client,
    http.Request request,
    void Function(http.StreamedResponse) onResponse,
  ) async {
    final stopwatch = Stopwatch()..start();
    final response = await _sendWithTimeout(client, request);
    onResponse(response);

    return _transportResponse(response, client, stopwatch);
  }

  Future<http.StreamedResponse> _sendWithTimeout(
    http.Client client,
    http.Request request,
  ) async {
    try {
      return await client.send(request).timeout(requestTimeout);
    } on Object {
      _closeOwnedClient(client);
      rethrow;
    }
  }

  void _closeOwnedClient(http.Client client) {
    if (httpClient == null) client.close();
  }

  ProviderTransportResponse _transportResponse(
    http.StreamedResponse response,
    http.Client client,
    Stopwatch stopwatch,
  ) => ProviderTransportResponse(
    statusCode: response.statusCode,
    body: _responseBody(response.stream, client, stopwatch),
    contentLength: response.contentLength,
  );

  Stream<List<int>> _responseBody(
    Stream<List<int>> source,
    http.Client client,
    Stopwatch stopwatch,
  ) {
    final body = _untilDeadline(
      source.timeout(requestTimeout),
      stopwatch,
      requestTimeout,
    );

    return httpClient == null ? _closeAfter(body, client) : body;
  }
}

const _maxProviderRetryDelay = Duration(seconds: 60);
const _retryableProviderStatuses = {500, 502, 503, 504};

final class _ProviderRetryState {
  int? statusCode;
  Duration? retryAfter;
  bool hasEmittedChunk = false;

  Duration? delayFor(
    Object error, {
    required bool canRetry,
    required ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  }) {
    context.cancel?.throwIfCancelled();
    if (!canRetry || hasEmittedChunk) return null;

    return _retryDelayFor(error, statusCode, retryAfter);
  }

  void captureResponse(http.StreamedResponse response) {
    statusCode = response.statusCode;
    retryAfter = _retryAfterDelay(response.headers['retry-after']);
  }
}

Duration? _retryDelayFor(Object error, int? statusCode, Duration? retryAfter) {
  if (_retryableProviderStatuses.contains(statusCode)) {
    final delay = retryAfter ?? .zero;
    if (delay <= .zero) return .zero;

    return delay > _maxProviderRetryDelay ? _maxProviderRetryDelay : delay;
  }
  if (error is http.ClientException || error is TimeoutException) {
    return .zero;
  }

  return null;
}

Future<ModelResponse> _generateWithRetry(
  AppChatCompletionsPlugin plugin,
  Map<String, dynamic> body,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
) async {
  var canRetry = true;
  while (true) {
    final attempt = _ProviderRetryState();
    try {
      return await _generateModelAttempt(plugin, body, context, attempt);
    } on Object catch (error, stackTrace) {
      final delay = attempt.delayFor(
        error,
        canRetry: canRetry,
        context: context,
      );
      if (delay == null) {
        final retryAfter = attempt.retryAfter;
        if (error is GenkitException &&
            attempt.statusCode == 429 &&
            retryAfter != null) {
          return await Future<ModelResponse>.error(
            AgentRateLimitRetryException(
              providerException: error,
              retryAfter: retryAfter,
            ),
            stackTrace,
          );
        }
        rethrow;
      }
      canRetry = false;
      await _waitForRetry(delay, context, plugin.retryWait);
    }
  }
}

Future<ModelResponse> _generateModelAttempt(
  AppChatCompletionsPlugin plugin,
  Map<String, dynamic> body,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  _ProviderRetryState attempt,
) {
  if (context.streamingRequested) {
    return _streamModelAttempt(plugin, body, context, attempt);
  }

  return _completeModelAttempt(plugin, body, context, attempt);
}

Future<ModelResponse> _streamModelAttempt(
  AppChatCompletionsPlugin plugin,
  Map<String, dynamic> body,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  _ProviderRetryState attempt,
) => plugin.codec.stream(
  _providerTransport(plugin, context, attempt),
  body,
  (chunk) => _sendModelChunk(context, attempt, chunk),
);

Future<ModelResponse> _completeModelAttempt(
  AppChatCompletionsPlugin plugin,
  Map<String, dynamic> body,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  _ProviderRetryState attempt,
) => plugin.codec.complete(_providerTransport(plugin, context, attempt), body);

typedef _ProviderTransport = Future<ProviderTransportResponse> Function(
  Map<String, dynamic> body,
);

_ProviderTransport _providerTransport(
  AppChatCompletionsPlugin plugin,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  _ProviderRetryState attempt,
) =>
    (body) => plugin._transport(
      body,
      context: context,
      onResponse: attempt.captureResponse,
    );

void _sendModelChunk(
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  _ProviderRetryState attempt,
  ModelResponseChunk chunk,
) {
  attempt.hasEmittedChunk = true;
  context.sendChunk(chunk);
}

Duration? _retryAfterDelay(String? value) {
  final header = value?.trim();
  if (header == null || header.isEmpty) return null;

  final seconds = int.tryParse(header);
  if (seconds == null) return _retryAfterDateDelay(header);

  return seconds < 0 ? .zero : Duration(seconds: seconds);
}

Duration? _retryAfterDateDelay(String header) {
  try {
    final delay = http_parser.parseHttpDate(header).difference(.now());

    return delay.isNegative ? .zero : delay;
  } on FormatException {
    return null;
  }
}

Future<void> _waitForRetry(
  Duration delay,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  Future<void> Function(Duration)? retryWait,
) {
  if (retryWait case final wait?) {
    return _waitForRetryCallback(delay, context, wait);
  }

  return _waitForRetryTimer(delay, context);
}

Future<void> _waitForRetryCallback(
  Duration delay,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  Future<void> Function(Duration) wait,
) async {
  final waiting = wait(delay);
  final cancellation = context.cancel;
  if (cancellation == null) {
    await waiting;

    return;
  }
  await Future.any<void>([waiting, cancellation.whenCancelled]);
  cancellation.throwIfCancelled();
}

Future<void> _waitForRetryTimer(
  Duration delay,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
) {
  if (context.cancel == null) return Future<void>.delayed(delay);

  return _waitForCancellableRetryTimer(delay, context);
}

Future<void> _waitForCancellableRetryTimer(
  Duration delay,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
) async {
  final cancellation = context.cancel;
  if (cancellation == null) return;
  final completed = Completer<void>();
  final timer = Timer(delay, completed.complete);
  final removeCancellationListener = cancellation.onCancel(completed.complete);
  try {
    await completed.future;
  } finally {
    _cleanupRetryTimer(timer, removeCancellationListener);
  }
  cancellation.throwIfCancelled();
}

void _cleanupRetryTimer(Timer timer, void Function() removeListener) {
  timer.cancel();
  removeListener();
}

Stream<List<int>> _untilDeadline(
  Stream<List<int>> source,
  Stopwatch stopwatch,
  Duration requestTimeout,
) async* {
  if (stopwatch.elapsed >= requestTimeout) _throwProviderRequestTimeout();

  final iterator = StreamIterator<List<int>>(source);
  try {
    yield* _readUntilDeadline(iterator, stopwatch, requestTimeout);
  } finally {
    final _ = await iterator.cancel();
  }
}

Stream<List<int>> _readUntilDeadline(
  StreamIterator<List<int>> iterator,
  Stopwatch stopwatch,
  Duration requestTimeout,
) async* {
  while (await _moveNextBeforeDeadline(iterator, stopwatch, requestTimeout)) {
    yield iterator.current;
  }
}

Future<bool> _moveNextBeforeDeadline(
  StreamIterator<List<int>> iterator,
  Stopwatch stopwatch,
  Duration requestTimeout,
) {
  final remaining = requestTimeout - stopwatch.elapsed;
  if (remaining <= .zero) _throwProviderRequestTimeout();

  return iterator.moveNext().timeout(
    remaining,
    onTimeout: _throwProviderRequestTimeout,
  );
}

Never _throwProviderRequestTimeout() =>
    throw TimeoutException('Provider request timed out.');

Stream<List<int>> _closeAfter(
  Stream<List<int>> stream,
  http.Client client,
) async* {
  try {
    yield* stream;
  } finally {
    client.close();
  }
}
