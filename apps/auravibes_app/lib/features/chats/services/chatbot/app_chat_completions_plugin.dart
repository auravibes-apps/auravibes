import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

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

  Future<dynamic> _generateModel(
    String modelName,
    dynamic request,
    dynamic context,
  ) async {
    if (request == null) throw ArgumentError.notNull('request');
    final body = codec.buildRequestBody(
      modelName: modelName,
      request: request,
      stream: context.streamingRequested,
    );
    final transport = _transport;

    return context.streamingRequested
        ? codec.stream(transport, body, context.sendChunk)
        : codec.complete(transport, body);
  }

  Future<ProviderTransportResponse> _transport(
    Map<String, dynamic> body,
  ) async {
    if (apiKey.trim().isEmpty) {
      throw GenkitException(
        '[$name] API key is required.',
        status: .INVALID_ARGUMENT,
      );
    }
    final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final request =
        http.Request('POST', Uri.parse(normalized).resolve('chat/completions'))
          ..headers.addAll({
            'authorization': 'Bearer ${apiKey.trim()}',
            'content-type': 'application/json',
            ...?headers,
          })
          ..body = jsonEncode(body);
    final client = httpClient ?? http.Client();
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
