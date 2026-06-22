// Required: Tests keep compact return flow.
// Required: Tests use protocol numeric fixtures.
// Required: Test fakes keep related fields near constructors.
// Required: Tests keep helper functions and fakes top-level.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_genkit_providers/auravibes_genkit_providers.dart';
import 'package:auravibes_genkit_providers/src/chat_completions_provider.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  test('sends OpenRouter chat request and maps response', () async {
    Map<String, dynamic>? capturedBody;
    Map<String, String>? capturedHeaders;
    Uri? capturedUri;
    final client = _FakeClient((request) async {
      capturedBody = await _readBody(request);
      capturedHeaders = request.headers;
      capturedUri = request.url;

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
        openRouter(
          apiKey: 'key',
          models: const [
            ChatCompletionsModelDefinition(name: 'anthropic/claude-sonnet-4'),
          ],
          httpClient: client,
        ),
      ],
    );

    final response = await ai.generate<OpenRouterOptions, Object?>(
      model: openRouter.model('anthropic/claude-sonnet-4'),
      returnToolRequests: true,
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
      config: OpenRouterOptions(
        temperature: 0.2,
        reasoning: const OpenRouterReasoningConfig(maxTokens: 10),
      ),
    );

    expect(
      capturedUri,
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
    );
    expect(capturedHeaders?['authorization'], 'Bearer key');
    expect(capturedBody?['model'], 'anthropic/claude-sonnet-4');
    expect(capturedBody?['temperature'], 0.2);
    expect(capturedBody?['reasoning'], {'max_tokens': 10});
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

  test('serializes tool responses and tool calls', () async {
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
        openRouter(
          apiKeyProvider: () => ' key ',
          models: const [
            ChatCompletionsModelDefinition(name: 'anthropic/claude-sonnet-4'),
          ],
          httpClient: client,
        ),
      ],
    );

    final response = await ai.generate<OpenRouterOptions, Object?>(
      model: openRouter.model('anthropic/claude-sonnet-4'),
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
        Message(
          role: Role.tool,
          content: [
            ToolResponsePart(
              toolResponse: ToolResponse(
                ref: 'call-1',
                name: 'lookup',
                output: {'value': 1},
              ),
            ),
          ],
        ),
      ],
    );

    expect(capturedBody?['messages'], [
      {
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
      },
      {'role': 'tool', 'tool_call_id': 'call-1', 'content': '{"value":1}'},
    ]);
    final message = response.rawResponse.message ?? fail('message missing');
    expect(
      message.content.map((part) => part.toolRequest).nonNulls.single.name,
      'lookup',
    );
    expect(response.rawResponse.finishReason, FinishReason.length);
  });

  test('streams reasoning, text, usage, and tool call deltas', () async {
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
                  'delta': {
                    'content': 'Answer',
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
        openRouter(
          apiKey: 'key',
          models: const [
            ChatCompletionsModelDefinition(name: 'anthropic/claude-sonnet-4'),
          ],
          httpClient: client,
        ),
      ],
    );

    final stream = ai.generateStream<OpenRouterOptions, Object?>(
      model: openRouter.model('anthropic/claude-sonnet-4'),
      returnToolRequests: true,
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
    );

    final chunks = await stream.toList();
    final result = await stream.onResult;

    expect(capturedBody?['stream_options'], {'include_usage': true});
    final firstChunk = chunks.firstOrNull ?? fail('first chunk missing');
    expect(
      firstChunk.content.map((part) => part.reasoning).nonNulls.single,
      'Think',
    );
    final message = result.message ?? fail('message missing');
    expect(message.text, 'Answer');
    expect(
      message.content.map((part) => part.toolRequest).nonNulls.single.input,
      {'query': 'weather'},
    );
    expect(result.usage?.totalTokens, 7);
    expect(result.finishReason, FinishReason.stop);
  });

  test('throws for invalid plugin configuration and API failures', () async {
    expect(
      () => openRouter(apiKey: 'key', name: 'bad/name'),
      throwsA(isA<GenkitException>()),
    );
    expect(
      () => openRouter(apiKey: 'key', apiKeyProvider: () => 'key'),
      throwsA(isA<GenkitException>()),
    );

    final ai = Genkit(
      plugins: [
        openRouter(
          apiKey: 'key',
          models: const [
            ChatCompletionsModelDefinition(name: 'anthropic/claude-sonnet-4'),
          ],
          httpClient: _FakeClient((request) async {
            return _jsonResponse({'error': 'bad'}, statusCode: 400);
          }),
        ),
      ],
    );

    expect(
      () => ai.generate<OpenRouterOptions, Object?>(
        model: openRouter.model('anthropic/claude-sonnet-4'),
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

  test('throws GenkitException for non-json API failures', () async {
    final ai = Genkit(
      plugins: [
        openRouter(
          apiKey: 'key',
          models: const [
            ChatCompletionsModelDefinition(name: 'anthropic/claude-sonnet-4'),
          ],
          httpClient: _FakeClient((request) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode('bad gateway')),
              502,
            );
          }),
        ),
      ],
    );

    expect(
      () => ai.generate<OpenRouterOptions, Object?>(
        model: openRouter.model('anthropic/claude-sonnet-4'),
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

  test('times out when non-streaming request does not respond', () {
    final ai = Genkit(
      plugins: [_timeoutProvider()],
    );

    expect(
      () => ai.generate<OpenRouterOptions, Object?>(
        model: openRouter.model('anthropic/claude-sonnet-4'),
        messages: [
          Message(
            role: Role.user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('times out when streaming request does not respond', () {
    final ai = Genkit(
      plugins: [_timeoutProvider()],
    );

    final stream = ai.generateStream<OpenRouterOptions, Object?>(
      model: openRouter.model('anthropic/claude-sonnet-4'),
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
    );

    expect(stream.onResult, throwsA(isA<TimeoutException>()));
  });
}

ChatCompletionsPlugin _timeoutProvider() {
  return ChatCompletionsPlugin(
    name: 'openrouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    errorLabel: 'OpenRouter',
    customize: (modelName, config) => (
      model: modelName,
      extraBody: const <String, dynamic>{},
    ),
    apiKey: 'key',
    models: const [
      ChatCompletionsModelDefinition(name: 'anthropic/claude-sonnet-4'),
    ],
    httpClient: _NeverRespondingClient(),
    requestTimeout: const Duration(milliseconds: 1),
  );
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

class _NeverRespondingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Completer<http.StreamedResponse>().future;
  }
}
