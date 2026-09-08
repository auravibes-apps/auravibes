import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/provider_http_transport.dart';
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
        status: StatusCodes.INVALID_ARGUMENT,
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

  Model<dynamic> _createModel(String modelName, ModelInfo? info) {
    return Model<dynamic>(
      name: '$name/$modelName',
      fn: (request, context) async {
        if (request == null) throw ArgumentError.notNull('request');
        final body = codec.buildRequestBody(
          modelName: modelName,
          request: request,
          stream: context.streamingRequested,
        );
        final transport = _transport;

        return context.streamingRequested
            ? await codec.stream(transport, body, context.sendChunk)
            : await codec.complete(transport, body);
      },
      metadata: {'model': ?info?.toJson()},
    );
  }

  Future<ProviderTransportResponse> _transport(
    Map<String, dynamic> body,
  ) async {
    if (apiKey.trim().isEmpty) {
      throw GenkitException(
        '[$name] API key is required.',
        status: StatusCodes.INVALID_ARGUMENT,
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

    return await sendProviderRequest(
      request,
      requestTimeout: requestTimeout,
      httpClient: httpClient,
    );
  }
}
