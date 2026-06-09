// Required: Tests keep compact return flow.
// ignore_for_file: no-magic-number
// Required: Tests use protocol numeric fixtures.
// ignore_for_file: member-ordering
// Required: Test fakes keep related fields near constructors.
// ignore_for_file: prefer-correct-identifier-length
// Required: Tests mirror Genkit `ai` naming convention.
// ignore_for_file: prefer-static-class
// Required: Tests keep helper functions and fakes top-level.

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

    final response = await ai.generate<OpenAICompatReasoningOptions, Object?>(
      model: openAICompatReasoning.model('glm-4.5'),
      returnToolRequests: true,
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
    final message = response.rawResponse.message ?? fail('message missing');
    expect(
      message.content.map((part) => part.reasoning).nonNulls.single,
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

    final _ = await ai.generate<OpenAICompatReasoningOptions, Object?>(
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

    final _ = await ai.generate<OpenAICompatReasoningOptions, Object?>(
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

  test('maps assistant tool calls from non-streaming responses', () async {
    Map<String, dynamic>? capturedBody;
    final client = _FakeClient((request) async {
      capturedBody = await _readBody(request);

      return _jsonResponse({
        'choices': [
          {
            'finish_reason': 'length',
            'message': {
              'role': 'assistant',
              'tool_calls': [
                {
                  'id': 'call-1',
                  'type': 'function',
                  'function': {
                    'name': 'lookup',
                    'arguments': '{"query":"weather"}',
                  },
                },
              ],
            },
          },
        ],
      });
    });
    final ai = Genkit(
      plugins: [
        openAICompatReasoning(
          apiKeyProvider: () => ' key ',
          baseUrl: 'https://api.z.ai/api/paas/v4/',
          models: const [OpenAICompatModelDefinition(name: 'glm-4.5')],
          httpClient: client,
        ),
      ],
    );

    final response = await ai.generate<OpenAICompatReasoningOptions, Object?>(
      model: openAICompatReasoning.model('glm-4.5'),
      returnToolRequests: true,
      messages: [
        Message(
          role: Role.model,
          content: [
            TextPart(text: 'Need a tool.'),
            ToolRequestPart(
              toolRequest: ToolRequest(
                ref: 'previous-call',
                name: 'lookup',
                input: {'query': 'forecast'},
              ),
            ),
          ],
        ),
      ],
    );

    final sentMessages = capturedBody?['messages'] as List<dynamic>?;
    expect(sentMessages?.single, {
      'role': 'assistant',
      'content': 'Need a tool.',
      'tool_calls': [
        {
          'id': 'previous-call',
          'type': 'function',
          'function': {
            'name': 'lookup',
            'arguments': '{"query":"forecast"}',
          },
        },
      ],
    });
    final message = response.rawResponse.message ?? fail('message missing');
    expect(
      message.content.map((part) => part.toolRequest).nonNulls.single.name,
      'lookup',
    );
    expect(response.rawResponse.finishReason, FinishReason.length);
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
              'choices': <Map<String, Object?>>[],
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

    final stream = ai.generateStream<OpenAICompatReasoningOptions, Object?>(
      model: openAICompatReasoning.model('glm-4.5'),
      returnToolRequests: true,
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
    final firstChunk = chunks.firstOrNull ?? fail('first chunk missing');
    expect(
      firstChunk.content.map((part) => part.reasoning).nonNulls.single,
      'Think',
    );
    expect(chunks.last.text, 'Answer');
    final message = result.message ?? fail('message missing');
    expect(
      message.content.map((part) => part.reasoning).nonNulls.single,
      'Think',
    );
    expect(message.text, 'Answer');
    expect(result.usage?.totalTokens, 7);
  });

  test('streams tool call deltas into final tool requests', () async {
    final client = _FakeClient((request) async {
      return http.StreamedResponse(
        Stream.fromIterable([
          utf8.encode(
            'data: ${jsonEncode({
              'choices': [
                {
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'id': 'call-1',
                        'function': {'name': 'lookup', 'arguments': '{'},
                      },
                    ],
                  },
                },
              ],
            })}\n\n',
          ),
          utf8.encode(
            'data: ${jsonEncode({
              'choices': [
                {
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'function': {'arguments': '"query":"weather"}'},
                      },
                    ],
                  },
                  'finish_reason': 'tool_calls',
                },
              ],
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

    final stream = ai.generateStream<OpenAICompatReasoningOptions, Object?>(
      model: openAICompatReasoning.model('glm-4.5'),
      returnToolRequests: true,
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
    );

    await stream.drain<void>();
    final result = await stream.onResult;
    final message = result.message ?? fail('message missing');
    final toolRequest = message.content
        .map((part) => part.toolRequest)
        .nonNulls
        .single;

    expect(toolRequest.ref, 'call-1');
    expect(toolRequest.name, 'lookup');
    expect(toolRequest.input, {'query': 'weather'});
    expect(result.finishReason, FinishReason.stop);
  });

  test('throws for invalid plugin configuration and API failures', () async {
    expect(
      () => openAICompatReasoning(apiKey: 'key', baseUrl: '', name: 'bad/name'),
      throwsA(isA<GenkitException>()),
    );
    expect(
      () => openAICompatReasoning(
        apiKey: 'key',
        apiKeyProvider: () => 'key',
        baseUrl: '',
      ),
      throwsA(isA<GenkitException>()),
    );

    final ai = Genkit(
      plugins: [
        openAICompatReasoning(
          apiKey: 'key',
          baseUrl: 'https://api.z.ai/api/paas/v4',
          models: const [OpenAICompatModelDefinition(name: 'glm-4.5')],
          httpClient: _FakeClient((request) async {
            return _jsonResponse({'error': 'bad'}, statusCode: 400);
          }),
        ),
      ],
    );

    expect(
      () => ai.generate<OpenAICompatReasoningOptions, Object?>(
        model: openAICompatReasoning.model('glm-4.5'),
        messages: [
          Message(
            role: Role.user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
      ),
      throwsA(isA<GenkitException>()),
    );
  });
}

Future<Map<String, Object?>> _readBody(http.BaseRequest request) async {
  return jsonDecode(await request.finalize().bytesToString())
      as Map<String, Object?>;
}

http.StreamedResponse _jsonResponse(
  Map<String, Object?> body, {
  int statusCode = 200,
}) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    statusCode,
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
