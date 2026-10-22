import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AppOpenAICodexPlugin({
  required final String accessToken,
  final String? accountId,
  final String? sessionId,
  final List<String> models = const [],
  final ReasoningConfiguration? reasoningConfiguration,
  final String baseUrl = 'https://chatgpt.com/backend-api/codex/responses',
  final http.Client? httpClient,
  final Duration requestTimeout = const Duration(seconds: 30),
}) extends GenkitPlugin {
  final OpenAICodexCodec codec = const OpenAICodexCodec();

  @override
  String get name => 'openai_codex';

  @override
  Future<List<Action<dynamic, dynamic, dynamic, dynamic>>> init() async => [
    for (final model in models) _createModel(model),
  ];

  @override
  Action<dynamic, dynamic, dynamic, dynamic>? resolve(
    ActionType actionType,
    String name,
  ) => actionType == ActionType.model ? _createModel(name) : null;
}

const int _maximumRetryAfterSeconds = 60;

class _CodexStreamAttempt {
  _CodexStreamAttempt(this.body, this.context, this.attempt);

  final Map<String, dynamic> body;
  final ActionFnArg<ModelResponseChunk, ModelRequest, void> context;
  final int attempt;
  var sentChunks = false;

  void sendChunk(ModelResponseChunk chunk) {
    sentChunks = true;
    context.sendChunk(chunk);
  }
}

extension on AppOpenAICodexPlugin {
  Model<dynamic> _createModel(String modelName) => Model<dynamic>(
    name: '$name/$modelName',
    fn: (request, context) => _generateModel(modelName, request, context),
  );

  Future<ModelResponse> _generateModel(
    String modelName,
    ModelRequest request,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) async {
    final body = _requestBody(modelName, request, context.streamingRequested);
    if (!context.streamingRequested) {
      return await codec.complete((body) => _transport(body, context), body);
    }

    return await _streamWithRetry(body, context);
  }

  Map<String, dynamic> _requestBody(
    String modelName,
    ModelRequest request,
    bool streamingRequested,
  ) => codec.buildRequestBody(
    modelName: modelName,
    request: request,
    stream: streamingRequested,
    reasoningConfiguration: reasoningConfiguration,
  );

  Future<ModelResponse> _streamWithRetry(
    Map<String, dynamic> body,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) => _streamAttempt(body, context, 0);

  Future<ModelResponse> _streamAttempt(
    Map<String, dynamic> body,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
    int attempt,
  ) async {
    final streamAttempt = _CodexStreamAttempt(body, context, attempt);
    try {
      return await codec.stream(
        (body) => _transport(body, context),
        body,
        streamAttempt.sendChunk,
      );
    } on GenkitException catch (error, stackTrace) {
      return _retryStreamAfterFailure(streamAttempt, error, stackTrace);
    }
  }

  Future<ModelResponse> _retryStreamAfterFailure(
    _CodexStreamAttempt streamAttempt,
    GenkitException error,
    StackTrace stackTrace,
  ) {
    streamAttempt.context.cancel?.throwIfCancelled();
    final shouldRetry = _shouldRetryStream(
      error,
      streamAttempt.attempt,
      streamAttempt.sentChunks,
    );
    if (shouldRetry) {
      return _streamAttempt(
        streamAttempt.body,
        streamAttempt.context,
        streamAttempt.attempt + 1,
      );
    }

    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<ProviderTransportResponse> _transport(
    Map<String, dynamic> body,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) {
    _ensureAccessToken();
    final request = _request(body, context);
    final client = httpClient ?? http.Client();

    return _sendRequest(client, request);
  }

  void _ensureAccessToken() {
    if (accessToken.trim().isNotEmpty) return;

    throw GenkitException(
      '[openai_codex] OAuth access token is required.',
      status: .invalidArgument,
    );
  }

  http.Request _request(
    Map<String, dynamic> body,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) =>
      http.AbortableRequest(
          'POST',
          .parse(baseUrl),
          abortTrigger: context.cancel?.whenCancelled,
        )
        ..headers.addAll({
          'authorization': 'Bearer ${accessToken.trim()}',
          'content-type': 'application/json',
          'originator': 'auravibes',
          'user-agent': 'AuraVibes',
          if (accountId case final value? when value.isNotEmpty)
            'ChatGPT-Account-Id': value,
          if (sessionId case final value? when value.isNotEmpty)
            'session-id': value,
        })
        ..body = jsonEncode(body);

  Future<ProviderTransportResponse> _sendRequest(
    http.Client client,
    http.Request request,
  ) async {
    try {
      final response = await _sendProviderRequest(
        client,
        request,
        requestTimeout,
      );

      return _providerTransportResponse(
        response,
        client,
        requestTimeout: requestTimeout,
        closeClient: httpClient == null,
      );
    } on Object catch (error, stackTrace) {
      _closeProviderClient(client, httpClient == null);
      Error.throwWithStackTrace(
        _classifyProviderTransportError(error),
        stackTrace,
      );
    }
  }
}

Future<http.StreamedResponse> _sendProviderRequest(
  http.Client client,
  http.Request request,
  Duration requestTimeout,
) => client.send(request).timeout(requestTimeout);

void _closeProviderClient(http.Client client, bool closeClient) {
  if (closeClient) client.close();
}

Object _classifyProviderTransportError(Object error) => switch (error) {
  http.RequestAbortedException() => error,
  http.ClientException() => ProviderTransientFailureException(error),
  _ => error,
};

ProviderTransportResponse _providerTransportResponse(
  http.StreamedResponse response,
  http.Client client, {
  required Duration requestTimeout,
  required bool closeClient,
}) {
  final body = response.stream.timeout(requestTimeout);

  return ProviderTransportResponse(
    statusCode: response.statusCode,
    body: _classifyProviderTransportStream(
      closeClient ? _closeAfter(body, client) : body,
    ),
    retryAfter: _providerRetryAfter(response.headers['retry-after']),
  );
}

Stream<List<int>> _classifyProviderTransportStream(
  Stream<List<int>> stream,
) async* {
  try {
    yield* stream;
  } on http.RequestAbortedException {
    rethrow;
  } on http.ClientException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      ProviderTransientFailureException(error),
      stackTrace,
    );
  }
}

Duration? _providerRetryAfter(String? value) {
  final header = value?.trim();
  if (header == null || header.isEmpty) return null;

  final seconds = int.tryParse(header);
  if (seconds == null) return _providerRetryAfterDate(header);
  if (seconds > _maximumRetryAfterSeconds) {
    return const Duration(seconds: _maximumRetryAfterSeconds);
  }

  return _limitProviderRetryAfter(
    seconds <= 0 ? Duration.zero : Duration(seconds: seconds),
  );
}

Duration? _providerRetryAfterDate(String header) {
  try {
    final difference = parseHttpDate(header).difference(DateTime.now().toUtc());

    return _limitProviderRetryAfter(
      difference.isNegative ? Duration.zero : difference,
    );
  } on FormatException {
    return null;
  }
}

Duration _limitProviderRetryAfter(Duration delay) {
  const maximumDelay = Duration(seconds: 60);

  return delay > maximumDelay ? maximumDelay : delay;
}

bool _shouldRetryStream(GenkitException error, int attempt, bool sentChunks) =>
    attempt == 0 && !sentChunks && isRetryableCodexError(error);

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
