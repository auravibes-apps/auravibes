import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

class AppOpenAICodexPlugin({
  required final String accessToken,
  final String? accountId,
  final String? sessionId,
  final List<String> models = const [],
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

extension on AppOpenAICodexPlugin {
  Model<dynamic> _createModel(String modelName) => Model<dynamic>(
    name: '$name/$modelName',
    fn: (request, context) => _generateModel(modelName, request, context),
  );

  Future<ModelResponse> _generateModel(
    String modelName,
    ModelRequest? request,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) async {
    if (request == null) throw ArgumentError.notNull('request');

    final body = _requestBody(modelName, request, context.streamingRequested);
    if (!context.streamingRequested) {
      return await codec.complete(_transport, body);
    }

    return _streamWithRetry(body, context);
  }

  Map<String, dynamic> _requestBody(
    String modelName,
    ModelRequest request,
    bool streamingRequested,
  ) => codec.buildRequestBody(
    modelName: modelName,
    request: request,
    stream: streamingRequested,
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
    var sentChunks = false;
    try {
      return await codec.stream(_transport, body, (chunk) {
        sentChunks = true;
        context.sendChunk(chunk);
      });
    } on GenkitException catch (error) {
      if (!isRetryableCodexError(error) || attempt > 0 || sentChunks) {
        rethrow;
      }

      return _streamAttempt(body, context, attempt + 1);
    }
  }

  Future<ProviderTransportResponse> _transport(
    Map<String, dynamic> body,
  ) async {
    _ensureAccessToken();
    final request = _request(body);
    final client = httpClient ?? http.Client();
    return _sendRequest(client, request);
  }

  void _ensureAccessToken() {
    if (accessToken.trim().isNotEmpty) return;

    throw GenkitException(
      '[openai_codex] OAuth access token is required.',
      status: .INVALID_ARGUMENT,
    );
  }

  http.Request _request(Map<String, dynamic> body) =>
      http.Request('POST', .parse(baseUrl))
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
      final response = await client.send(request).timeout(requestTimeout);

      return ProviderTransportResponse(
        statusCode: response.statusCode,
        body: httpClient == null
            ? _closeAfter(response.stream, client)
            : response.stream,
      );
    } on Object {
      if (httpClient == null) client.close();
      rethrow;
    }
  }
}

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
