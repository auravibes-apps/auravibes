import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as sdk;
import 'package:auravibes_app/features/chats/services/chatbot/anthropic_message_codec.dart';
import 'package:auravibes_app/features/chats/services/chatbot/anthropic_request_encoder.dart';
import 'package:genkit/plugin.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:http/http.dart' as http;

class AppAnthropicPlugin extends GenkitPlugin {
  new({
    required this.apiKey,
    required this.encoder,
    this.baseUrl,
    this.headers = const {},
    this.httpClient,
  });

  final String apiKey;
  final AnthropicRequestEncoder encoder;
  final String? baseUrl;
  final Map<String, String> headers;
  final http.Client? httpClient;

  @override
  String get name => 'anthropic';

  @override
  Action<dynamic, dynamic, dynamic, dynamic>? resolve(
    ActionType actionType,
    String name,
  ) => actionType != ActionType.model
      ? null
      : Model(
          name: 'anthropic/$name',
          fn: (request, context) => _generate(name, request, context),
          customOptions: AnthropicOptions.$schema,
        );

  Future<ModelResponse> _generate(
    String model,
    ModelRequest? request,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) async {
    if (request == null) {
      throw const AnthropicRequestException('missing_request');
    }
    final encoded = encoder.encode(model, request);
    final client = _createClient();
    try {
      final message = await _request(client, encoded, context);

      return _response(message);
    } on sdk.ApiException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const AnthropicRequestException('provider_failure'),
        stackTrace,
      );
    } finally {
      client.close();
    }
  }

  sdk.AnthropicClient _createClient() => sdk.AnthropicClient.withApiKey(
    apiKey,
    baseUrl: baseUrl,
    defaultHeaders: headers,
    httpClient: httpClient,
  );
}

Future<sdk.Message> _stream(
  sdk.AnthropicClient client,
  AnthropicEncodedRequest request,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
) async {
  final accumulator = sdk.MessageStreamAccumulator();
  await for (final event in client.messages.createStream(
    request.request,
    betas: request.betas,
    abortTrigger: context.cancel?.whenCancelled,
  )) {
    accumulator.add(event);
    _emitEvent(event, context.sendChunk);
  }

  return accumulator.toMessage();
}

Future<sdk.Message> _request(
  sdk.AnthropicClient client,
  AnthropicEncodedRequest request,
  ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
) async {
  if (context.streamingRequested) {
    return await _stream(client, request, context);
  }
  try {
    return await client.messages.create(
      request.request,
      betas: request.betas,
      abortTrigger: context.cancel?.whenCancelled,
    );
  } on FormatException catch (_, stackTrace) {
    Error.throwWithStackTrace(
      const AnthropicRequestException('invalid_response'),
      stackTrace,
    );
  }
}

void _emitEvent(
  sdk.MessageStreamEvent event,
  void Function(ModelResponseChunk) sendChunk,
) {
  if (event is sdk.ErrorEvent) {
    throw const AnthropicRequestException('stream_failure');
  }
  if (event case sdk.ContentBlockDeltaEvent(:final index, :final delta)) {
    final parts = _deltaParts(delta);
    if (parts.isNotEmpty) {
      sendChunk(.new(index: index, content: parts));
    }
  }
}

List<Part> _deltaParts(sdk.ContentBlockDelta delta) => switch (delta) {
  sdk.TextDelta(:final text) => [TextPart(text: text)],
  sdk.ThinkingDelta(:final thinking) => [ReasoningPart(reasoning: thinking)],
  sdk.InputJsonDelta() ||
  sdk.SignatureDelta() ||
  sdk.CitationsDelta() ||
  sdk.CompactionDelta() ||
  sdk.UnknownContentBlockDelta() => const [],
};

ModelResponse _response(sdk.Message message) => ModelResponse(
  message: AnthropicMessageCodec.decode(message),
  finishReason: switch (message.stopReason) {
    sdk.StopReason.maxTokens ||
    sdk.StopReason.modelContextWindowExceeded => FinishReason.length,
    sdk.StopReason.refusal => FinishReason.blocked,
    null => FinishReason.unknown,
    _ => FinishReason.stop,
  },
  usage: _usage(message.usage),
);

GenerationUsage _usage(sdk.Usage usage) => GenerationUsage(
  inputTokens: usage.inputTokens.toDouble(),
  outputTokens: usage.outputTokens.toDouble(),
  totalTokens: (usage.inputTokens + usage.outputTokens).toDouble(),
);
