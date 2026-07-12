import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart';
import 'package:test/test.dart';

void main() {
  test('OpenRouter builds and parses chat completions', () async {
    final codec = ChatCompletionsCodec(
      errorLabel: 'OpenRouter',
      customize: (modelName, config) {
        final options = OpenRouterOptions.fromJson(config);
        return (
          model: modelName,
          extraBody: {
            ...options.toSamplingBody(),
            if (options.reasoningMaxTokens != null)
              'reasoning': {'max_tokens': options.reasoningMaxTokens},
          },
        );
      },
    );
    final body = codec.buildRequestBody(
      modelName: 'model',
      request: ModelRequest(
        messages: [
          Message(
            role: Role.user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
        config: OpenRouterOptions(reasoningMaxTokens: 10).toJson(),
      ),
      stream: false,
    );
    final response = await codec.complete(
      (_) async => _response({
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {'role': 'assistant', 'content': 'Answer.'},
          },
        ],
      }),
      body,
    );

    expect(body['reasoning'], {'max_tokens': 10});
    expect(body['messages'], [
      {'role': 'user', 'content': 'Hi'},
    ]);
    expect(response.message?.text, 'Answer.');
  });

  test('OpenAI-compatible codec maps version and thinking options', () {
    final codec = ChatCompletionsCodec(
      errorLabel: 'OpenAI-compatible',
      customize: (modelName, config) {
        final options = OpenAICompatReasoningOptions.fromJson(config);
        return (
          model: options.version ?? modelName,
          extraBody: {
            ...options.toSamplingBody(),
            if (options.reasoningType != null)
              'thinking': {'type': options.reasoningType},
          },
        );
      },
    );
    final body = codec.buildRequestBody(
      modelName: 'alias',
      request: ModelRequest(
        messages: const [],
        config: OpenAICompatReasoningOptions(
          version: 'model-version',
          reasoningType: 'enabled',
        ).toJson(),
      ),
      stream: false,
    );

    expect(body['model'], 'model-version');
    expect(body['thinking'], {'type': 'enabled'});
  });

  test('Codex builds and streams responses', () async {
    const codec = OpenAICodexCodec();
    final body = codec.buildRequestBody(
      modelName: 'gpt-5.5',
      request: ModelRequest(
        messages: [
          Message(
            role: Role.user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
      ),
      stream: true,
    );
    final chunks = <ModelResponseChunk>[];
    final response = await codec.stream(
      (_) async => ProviderTransportResponse(
        statusCode: 200,
        body: Stream.fromIterable([
          utf8.encode(
            'data: {"type":"response.output_text.delta","delta":"Hi"}\n',
          ),
          utf8.encode('data: {"type":"response.completed"}\n'),
        ]),
      ),
      body,
      chunks.add,
    );

    expect(body['store'], false);
    expect(chunks.single.text, 'Hi');
    expect(response.message?.text, 'Hi');
  });
}

ProviderTransportResponse _response(Map<String, Object?> body) {
  return ProviderTransportResponse(
    statusCode: 200,
    body: Stream.value(utf8.encode(jsonEncode(body))),
  );
}
