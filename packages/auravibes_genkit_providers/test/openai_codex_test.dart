// Required: Tests keep compact return flow.
// Required: Test fakes keep related fields near constructors.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_genkit_providers/auravibes_genkit_providers.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  test('posts to Codex responses endpoint with OAuth headers', () async {
    Uri? capturedUri;
    Map<String, String>? capturedHeaders;
    Map<String, dynamic>? capturedBody;
    final client = _FakeClient((request) async {
      capturedUri = request.url;
      capturedHeaders = request.headers;
      capturedBody = await _readBody(request);

      return _jsonResponse({
        'status': 'completed',
        'output_text': 'Answer.',
        'usage': {
          'input_tokens': 3,
          'output_tokens': 4,
          'total_tokens': 7,
        },
      });
    });
    final ai = Genkit(
      plugins: [
        OpenAICodexProvider(
          accessTokenProvider: () => 'oauth-token',
          accountId: 'account-1',
          sessionId: 'session-1',
          models: const ['gpt-5.5'],
          httpClient: client,
        ),
      ],
    );

    final response = await ai.generate<Object?, Object?>(
      model: openAICodexModel('gpt-5.5'),
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
    );

    expect(
      capturedUri,
      Uri.parse('https://chatgpt.com/backend-api/codex/responses'),
    );
    expect(capturedHeaders?['authorization'], 'Bearer oauth-token');
    expect(capturedHeaders?['ChatGPT-Account-Id'], 'account-1');
    expect(capturedHeaders?['session-id'], 'session-1');
    expect(capturedHeaders?['originator'], 'auravibes');
    expect(capturedHeaders?['user-agent'], 'AuraVibes');
    expect(capturedBody?['model'], 'gpt-5.5');
    expect(capturedBody?['input'], [
      {'role': 'user', 'content': 'Hi'},
    ]);
    expect(capturedBody?['instructions'], isNotEmpty);
    expect(capturedBody?['store'], false);
    expect(capturedBody?['reasoning'], {'effort': 'medium', 'summary': 'auto'});
    expect(capturedBody?['text'], {'verbosity': 'low'});
    expect(capturedBody?['include'], ['reasoning.encrypted_content']);
    expect(response.text, 'Answer.');
    expect(response.usage?.totalTokens, 7);
  });

  test('streams Responses text deltas', () async {
    final client = _FakeClient((request) async {
      return http.StreamedResponse(
        Stream.fromIterable([
          utf8.encode(
            'data: {"type":"response.output_text.delta","delta":"Hel"}\n\n',
          ),
          utf8.encode(
            'data: {"type":"response.output_text.delta","delta":"lo"}\n\n',
          ),
          utf8.encode(
            'data: ${jsonEncode({
              'type': 'response.completed',
              'response': {
                'usage': {
                  'input_tokens': 1,
                  'output_tokens': 2,
                  'total_tokens': 3,
                },
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
        OpenAICodexProvider(
          accessTokenProvider: () => 'oauth-token',
          models: const ['gpt-5.5'],
          httpClient: client,
        ),
      ],
    );

    final stream = ai.generateStream<Object?, Object?>(
      model: openAICodexModel('gpt-5.5'),
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
    );

    final chunks = await stream.toList();
    final result = await stream.onResult;

    expect(chunks.map((chunk) => chunk.text).join(), 'Hello');
    expect(result.text, 'Hello');
    expect(result.usage?.totalTokens, 3);
  });

  test('retries transient server errors before streaming chunks', () async {
    var requests = 0;
    final client = _FakeClient((request) async {
      requests++;
      if (requests == 1) {
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              'data: ${jsonEncode({
                'type': 'response.failed',
                'response': {
                  'error': {'code': 'server_error', 'message': 'retry'},
                },
              })}\n\n',
            ),
          ),
          200,
        );
      }

      return http.StreamedResponse(
        Stream.fromIterable([
          utf8.encode(
            'data: {"type":"response.output_text.delta","delta":"Ok"}\n\n',
          ),
          utf8.encode('data: {"type":"response.completed"}\n\n'),
        ]),
        200,
      );
    });
    final ai = Genkit(
      plugins: [
        OpenAICodexProvider(
          accessTokenProvider: () => 'oauth-token',
          models: const ['gpt-5.5'],
          httpClient: client,
        ),
      ],
    );

    final stream = ai.generateStream<Object?, Object?>(
      model: openAICodexModel('gpt-5.5'),
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
    );

    expect((await stream.toList()).map((chunk) => chunk.text).join(), 'Ok');
    expect(requests, 2);
  });

  test('sends tool call history before tool outputs', () async {
    Map<String, dynamic>? capturedBody;
    final ai = Genkit(
      plugins: [
        OpenAICodexProvider(
          accessTokenProvider: () => 'oauth-token',
          models: const ['gpt-5.5'],
          httpClient: _FakeClient((request) async {
            capturedBody = await _readBody(request);

            return _jsonResponse({
              'status': 'completed',
              'output_text': 'Done.',
            });
          }),
        ),
      ],
    );

    final response = await ai.generate<Object?, Object?>(
      model: openAICodexModel('gpt-5.5'),
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Use tool')],
        ),
        Message(
          role: Role.model,
          content: [
            ToolRequestPart(
              toolRequest: ToolRequest(
                ref: 'call_1',
                name: 'read_file',
                input: {'path': 'README.md'},
              ),
            ),
          ],
        ),
        Message(
          role: Role.tool,
          content: [
            ToolResponsePart(
              toolResponse: ToolResponse(
                ref: 'call_1',
                name: 'read_file',
                output: 'content',
              ),
            ),
          ],
        ),
      ],
    );

    expect(response.text, 'Done.');
    expect(capturedBody?['input'], [
      {'role': 'user', 'content': 'Use tool'},
      {'role': 'assistant', 'content': ''},
      {
        'type': 'function_call',
        'call_id': 'call_1',
        'name': 'read_file',
        'arguments': '{"path":"README.md"}',
      },
      {
        'type': 'function_call_output',
        'call_id': 'call_1',
        'output': '"content"',
      },
    ]);
  });

  test('preserves backend error body', () {
    final ai = Genkit(
      plugins: [
        OpenAICodexProvider(
          accessTokenProvider: () => 'oauth-token',
          httpClient: _FakeClient((request) async {
            return _jsonResponse({'error': 'bad'}, statusCode: 403);
          }),
        ),
      ],
    );

    expect(
      () => ai.generate<Object?, Object?>(
        model: openAICodexModel('gpt-5.5'),
        messages: [
          Message(
            role: Role.user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
      ),
      throwsA(
        isA<GenkitException>().having(
          (error) => error.details,
          'details',
          contains('bad'),
        ),
      ),
    );
  });

  test('parses nested output text', () async {
    final ai = Genkit(
      plugins: [
        OpenAICodexProvider(
          accessTokenProvider: () => 'oauth-token',
          httpClient: _FakeClient((request) async {
            return _jsonResponse({
              'status': 'incomplete',
              'output': [
                {
                  'content': [
                    {'text': 'Hello '},
                    {'output_text': 'there'},
                  ],
                },
              ],
            });
          }),
        ),
      ],
    );

    final response = await ai.generate<Object?, Object?>(
      model: openAICodexModel('gpt-5.5'),
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
    );

    expect(response.text, 'Hello there');
    expect(response.finishReason, FinishReason.length);
  });

  test('streams failed events with compact error details', () {
    final ai = Genkit(
      plugins: [
        OpenAICodexProvider(
          accessTokenProvider: () => 'oauth-token',
          httpClient: _FakeClient((request) async {
            return http.StreamedResponse(
              Stream.fromIterable([
                utf8.encode(
                  'data: ${jsonEncode({
                    'type': 'response.failed',
                    'error': {'message': 'bad'},
                  })}\n\n',
                ),
              ]),
              200,
            );
          }),
        ),
      ],
    );

    expect(
      () async {
        final stream = ai.generateStream<Object?, Object?>(
          model: openAICodexModel('gpt-5.5'),
          messages: [
            Message(
              role: Role.user,
              content: [TextPart(text: 'Hi')],
            ),
          ],
        );
        await stream.drain<void>();
      },
      throwsA(
        isA<GenkitException>()
            .having((error) => error.message, 'message', contains('bad'))
            .having((error) => error.details, 'details', contains('bad'))
            .having(
              (error) => error.stackTrace,
              'stackTrace',
              isNotNull,
            ),
      ),
    );
  });

  test('streams nested failed events without encrypted content', () {
    const requestId = 'c3579012-0e03-40fc-a77a-198de40f6bca';
    final ai = Genkit(
      plugins: [
        OpenAICodexProvider(
          accessTokenProvider: () => 'oauth-token',
          httpClient: _FakeClient((request) async {
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  'data: ${jsonEncode({
                    'type': 'response.failed',
                    'response': {
                      'id': 'resp_1',
                      'status': 'failed',
                      'model': 'gpt-5.5',
                      'error': {
                        'code': 'server_error',
                        'message': 'Include request ID $requestId',
                      },
                      'output': [
                        {
                          'encrypted_content': 'secret-encrypted-content',
                        },
                      ],
                    },
                  })}\n\n',
                ),
              ),
              200,
            );
          }),
        ),
      ],
    );

    expect(
      () async {
        final stream = ai.generateStream<Object?, Object?>(
          model: openAICodexModel('gpt-5.5'),
          messages: [
            Message(
              role: Role.user,
              content: [TextPart(text: 'Hi')],
            ),
          ],
        );
        await stream.drain<void>();
      },
      throwsA(
        isA<GenkitException>()
            .having((error) => error.message, 'message', contains(requestId))
            .having((error) => error.details, 'details', contains('resp_1'))
            .having(
              (error) => error.details,
              'details',
              isNot(contains('secret-encrypted-content')),
            ),
      ),
    );
  });

  test('streams malformed events with raw payload details', () {
    final ai = Genkit(
      plugins: [
        OpenAICodexProvider(
          accessTokenProvider: () => 'oauth-token',
          httpClient: _FakeClient((request) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode('data: {not-json}\n\n')),
              200,
            );
          }),
        ),
      ],
    );

    expect(
      () async {
        final stream = ai.generateStream<Object?, Object?>(
          model: openAICodexModel('gpt-5.5'),
          messages: [
            Message(
              role: Role.user,
              content: [TextPart(text: 'Hi')],
            ),
          ],
        );
        await stream.drain<void>();
      },
      throwsA(
        isA<GenkitException>()
            .having(
              (error) => error.message,
              'message',
              contains('stream parse error'),
            )
            .having((error) => error.details, 'details', '{not-json}')
            .having(
              (error) => error.underlyingException,
              'underlyingException',
              isNotNull,
            ),
      ),
    );
  });

  test('rejects missing OAuth token', () {
    final ai = Genkit(
      plugins: [
        OpenAICodexProvider(accessTokenProvider: () => '  '),
      ],
    );

    expect(
      () => ai.generate<Object?, Object?>(
        model: openAICodexModel('gpt-5.5'),
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

Future<Map<String, dynamic>> _readBody(http.BaseRequest request) async {
  return jsonDecode(await request.finalize().bytesToString())
      as Map<String, dynamic>;
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
