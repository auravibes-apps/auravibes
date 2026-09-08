import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/provider_http_transport.dart';
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

  Model<dynamic> _createModel(String modelName) {
    return Model<dynamic>(
      name: '$name/$modelName',
      fn: (request, context) async {
        if (request == null) throw ArgumentError.notNull('request');
        final body = codec.buildRequestBody(
          modelName: modelName,
          request: request,
          stream: context.streamingRequested,
        );
        if (!context.streamingRequested) {
          return await codec.complete(_transport, body);
        }

        var sentChunks = false;
        for (var attempt = 0; ; attempt++) {
          try {
            return await codec.stream(_transport, body, (chunk) {
              sentChunks = true;
              context.sendChunk(chunk);
            });
          } on GenkitException catch (error) {
            if (!isRetryableCodexError(error) || attempt > 0 || sentChunks) {
              rethrow;
            }
          }
        }
      },
    );
  }

  Future<ProviderTransportResponse> _transport(
    Map<String, dynamic> body,
  ) async {
    if (accessToken.trim().isEmpty) {
      throw GenkitException(
        '[openai_codex] OAuth access token is required.',
        status: StatusCodes.INVALID_ARGUMENT,
      );
    }
    final request = http.Request('POST', Uri.parse(baseUrl))
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

    return await sendProviderRequest(
      request,
      requestTimeout: requestTimeout,
      httpClient: httpClient,
    );
  }
}
