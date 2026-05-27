import 'dart:convert';

import 'package:auravibes_genkit_openai_compat/auravibes_genkit_openai_compat.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  test('sends thinking config and maps reasoning response', () async {
    Map<String, dynamic>? capturedBody;
    final client = _FakeClient((request) async {
      capturedBody = await _readBody(request);
      return _jsonResponse({
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {
              'role': 'assistant',
              'reasoning_content': 'Think first.',
              'content': 'Answer.',
            },
          },
        ],
        'usage': {
          'prompt_tokens': 3,
          'completion_tokens': 4,
          'total_tokens': 7,
        },
      });
    });
    final ai = Genkit(
      plugins: [
        openAICompatReasoning(
          apiKey: 'key',
          baseUrl: 'https://api.z.ai/api/paas/v4',
          models: const [OpenAICompatModelDefinition(name: 'glm-4.5')],
          httpClient: client,
        ),
      ],
    );

    final response = await ai.generate<OpenAICompatReasoningOptions, dynamic>(
      model: openAICompatReasoning.model('glm-4.5'),
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
      config: OpenAICompatReasoningOptions(
        reasoning: const OpenAICompatReasoningConfig(),
      ),
    );

    expect(capturedBody?['thinking'], {'type': 'enabled'});
    expect(capturedBody?['messages'], [
      {'role': 'user', 'content': 'Hi'},
    ]);
    expect(
      response.rawResponse.message!.content
          .map((part) => part.reasoning)
          .nonNulls
          .single,
      'Think first.',
    );
    expect(response.text, 'Answer.');
    expect(response.usage?.totalTokens, 7);
  });

  test('does not send thinking config unless reasoning is enabled', () async {
    Map<String, dynamic>? capturedBody;
    final client = _FakeClient((request) async {
      capturedBody = await _readBody(request);
      return _jsonResponse({
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {'role': 'assistant', 'content': 'Answer.'},
          },
        ],
      });
    });
    final ai = Genkit(
      plugins: [
        openAICompatReasoning(
          apiKey: 'key',
          baseUrl: 'https://api.z.ai/api/paas/v4',
          models: const [OpenAICompatModelDefinition(name: 'glm-4.5')],
          httpClient: client,
        ),
      ],
    );

    await ai.generate<OpenAICompatReasoningOptions, dynamic>(
      model: openAICompatReasoning.model('glm-4.5'),
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
      config: OpenAICompatReasoningOptions(temperature: 0.2),
    );

    expect(capturedBody, isNot(contains('thinking')));
  });

  test('serializes multiple tool responses as separate messages', () async {
    Map<String, dynamic>? capturedBody;
    final client = _FakeClient((request) async {
      capturedBody = await _readBody(request);
      return _jsonResponse({
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {'role': 'assistant', 'content': 'Answer.'},
          },
        ],
      });
    });
    final ai = Genkit(
      plugins: [
        openAICompatReasoning(
          apiKey: 'key',
          baseUrl: 'https://api.z.ai/api/paas/v4',
          models: const [OpenAICompatModelDefinition(name: 'glm-4.5')],
          httpClient: client,
        ),
      ],
    );

    await ai.generate<OpenAICompatReasoningOptions, dynamic>(
      model: openAICompatReasoning.model('glm-4.5'),
      messages: [
        Message(
          role: Role.tool,
          content: [
            ToolResponsePart(
              toolResponse: ToolResponse(
                ref: 'call-1',
                name: 'first_tool',
                output: {'value': 1},
              ),
            ),
            ToolResponsePart(
              toolResponse: ToolResponse(
                ref: 'call-2',
                name: 'second_tool',
                output: {'value': 2},
              ),
            ),
          ],
        ),
      ],
    );

    expect(capturedBody?['messages'], [
      {'role': 'tool', 'tool_call_id': 'call-1', 'content': '{"value":1}'},
      {'role': 'tool', 'tool_call_id': 'call-2', 'content': '{"value":2}'},
    ]);
  });

  test('streams reasoning_content as ReasoningPart chunks', () async {
    Map<String, dynamic>? capturedBody;
    final client = _FakeClient((request) async {
      capturedBody = await _readBody(request);
      return http.StreamedResponse(
        Stream.fromIterable([
          utf8.encode(
            'data: {"choices":[{"delta":{"reasoning_content":"Think"}}]}\n\n',
          ),
          utf8.encode(
            'data: ${jsonEncode({
              'choices': [
                {
                  'delta': {'content': 'Answer'},
                  'finish_reason': 'stop',
                },
              ],
            })}\n\n',
          ),
          utf8.encode(
            'data: ${jsonEncode({
              'choices': <Map<String, dynamic>>[],
              'usage': {
                'prompt_tokens': 3,
                'completion_tokens': 4,
                'total_tokens': 7,
              },
            })}\n\n',
          ),
          utf8.encode('data: [DONE]\n\n'),
        ]),
        200,
      );
    });
    final ai = Genkit(
      plugins: [
        openAICompatReasoning(
          apiKey: 'key',
          baseUrl: 'https://api.z.ai/api/paas/v4',
          models: const [OpenAICompatModelDefinition(name: 'glm-4.5')],
          httpClient: client,
        ),
      ],
    );

    final stream = ai.generateStream<OpenAICompatReasoningOptions, dynamic>(
      model: openAICompatReasoning.model('glm-4.5'),
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
      config: OpenAICompatReasoningOptions(
        reasoning: const OpenAICompatReasoningConfig(),
      ),
    );

    final chunks = await stream.toList();
    final result = await stream.onResult;

    expect(capturedBody?['stream_options'], {'include_usage': true});
    expect(
      chunks.firstOrNull!.content.map((part) => part.reasoning).nonNulls.single,
      'Think',
    );
    expect(chunks.last.text, 'Answer');
    expect(
      result.message!.content.map((part) => part.reasoning).nonNulls.single,
      'Think',
    );
    expect(result.message!.text, 'Answer');
    expect(result.usage?.totalTokens, 7);
  });
}

Future<Map<String, dynamic>> _readBody(http.BaseRequest request) async {
  return jsonDecode(await request.finalize().bytesToString())
      as Map<String, dynamic>;
}

http.StreamedResponse _jsonResponse(Map<String, dynamic> body) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    200,
    headers: {'content-type': 'application/json'},
  );
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return handler(request);
  }
}
