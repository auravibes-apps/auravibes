import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/plugin.dart';
import 'package:test/test.dart';

import '../support/provider_fault_fixture.dart';

void main() {
  test('fixture snapshots requests and rejects unscripted attempts', () async {
    final fixture = ProviderFaultFixture([
      () async => const ProviderTransportResponse(
        statusCode: 200,
        body: const Stream.empty(),
      ),
    ]);
    final request = <String, dynamic>{
      'messages': [
        {'content': 'original'},
      ],
    };
    await fixture.send(request);
    (request['messages'] as List).clear();
    (fixture.requests.single['messages'] as List).clear();

    expect(fixture.requests.single['messages'], [
      {'content': 'original'},
    ]);
    expect(() => fixture.send(const {}), throwsStateError);
  });

  test('fixture observes subscription cancellation once', () async {
    final body = ProviderFaultBody();
    addTearDown(body.dispose);
    final subscription = body.stream.listen((_) {});
    await body.listened;
    await subscription.cancel();
    await body.cancelled;
    await subscription.cancel();

    expect(body.cancellationCount, 1);
  });

  for (final adapter in _adapters) {
    group(adapter.name, () {
      test('decodes partial and delayed UTF-8/SSE chunks once', () async {
        final body = ProviderFaultBody();
        addTearDown(body.dispose);
        final fixture = _fixture(body);
        final chunks = <ModelResponseChunk>[];
        final firstChunk = Completer<void>();
        final pending = adapter.stream(fixture.send, const {}, (chunk) {
          chunks.add(chunk);
          if (!firstChunk.isCompleted) firstChunk.complete();
        });
        await body.listened;
        final bytes = adapter.text('Hello ').toList();
        body
          ..add(bytes.sublist(0, 2))
          ..add(bytes.sublist(2));
        await firstChunk.future;
        expect(chunks.map((chunk) => chunk.text).join(), 'Hello ');

        final unicode = adapter.text('\u{1f30d}');
        final split = unicode.indexOf(0xf0) + 2;
        body
          ..add(unicode.sublist(0, split))
          ..add([...unicode.sublist(split), ...adapter.done()]);
        await body.close();
        final response = await pending;

        expect(response.message?.text, 'Hello \u{1f30d}');
        expect(chunks.map((chunk) => chunk.text).join(), 'Hello \u{1f30d}');
        expect(fixture.requests, hasLength(1));
        expect(body.cancellationCount, 1);
      });

      for (final failure in <Object>[
        const ProviderTransientFailureException('disconnected'),
        TimeoutException('fixture timeout'),
      ]) {
        test('preserves emitted prefix after ${failure.runtimeType}', () async {
          final body = ProviderFaultBody();
          addTearDown(body.dispose);
          final fixture = _fixture(body);
          final chunks = <ModelResponseChunk>[];
          final firstChunk = Completer<void>();
          final pending = adapter.stream(fixture.send, const {}, (chunk) {
            chunks.add(chunk);
            if (!firstChunk.isCompleted) firstChunk.complete();
          });
          final assertion = expectLater(pending, throwsA(same(failure)));
          await body.listened;
          body.add(adapter.text('partial'));
          await firstChunk.future;
          body.fail(failure);
          await assertion;
          await body.cancelled;

          expect(chunks.map((chunk) => chunk.text).join(), 'partial');
          expect(fixture.requests, hasLength(1));
          expect(body.cancellationCount, 1);
        });
      }

      for (final status in [401, 403, 429, 500, 502, 503, 504]) {
        test('retains structured HTTP $status metadata', () async {
          final fixture = ProviderFaultFixture([
            () async => ProviderTransportResponse(
              statusCode: status,
              retryAfter: status == 429 ? const Duration(seconds: 12) : null,
              body: Stream.value(
                utf8.encode('{"error":{"type":"server_error"}}'),
              ),
            ),
          ]);
          Object? failure;
          try {
            await adapter.stream(fixture.send, const {}, (_) {});
          } on Object catch (error) {
            failure = error;
          }
          expect(failure, isA<ProviderHttpFailureException>());
          final recovery = ProviderFailureRecovery.fromError(failure!);

          expect(recovery.httpStatusCode, status);
          expect(recovery.retryable, status != 401 && status != 403);
          expect(
            recovery.category,
            status == 401 || status == 403
                ? ProviderFailureCategory.authentication
                : status == 429
                ? ProviderFailureCategory.quotaRateLimit
                : ProviderFailureCategory.transientOutage,
          );
          expect(
            recovery.retryAfter,
            status == 429 ? const Duration(seconds: 12) : null,
          );
          expect(fixture.requests, hasLength(1));
        });
      }

      test('does not infer a rate-limit delay without Retry-After', () async {
        final fixture = ProviderFaultFixture([
          () async => ProviderTransportResponse(
            statusCode: 429,
            body: Stream.value(utf8.encode('{}')),
          ),
        ]);

        await expectLater(
          adapter.stream(fixture.send, const {}, (_) {}),
          throwsA(
            isA<ProviderHttpFailureException>().having(
              (error) => ProviderFailureRecovery.fromError(error).retryable,
              'retryable',
              isFalse,
            ),
          ),
        );
      });

      test('retains tool identity through fragmentation and replay', () async {
        final bytes = adapter.tool();
        final fixture = ProviderFaultFixture([
          () async => ProviderTransportResponse(
            statusCode: 200,
            body: Stream.fromIterable([
              bytes.sublist(0, bytes.length ~/ 2),
              bytes.sublist(bytes.length ~/ 2),
              adapter.done(),
            ]),
          ),
        ]);
        final response = await adapter.stream(fixture.send, const {}, (_) {});
        final requests = response.message!.content
            .whereType<ToolRequestPart>()
            .map((part) => part.toolRequest)
            .toList();
        expect(requests, hasLength(1));
        final tool = requests.single;
        expect(tool.ref, 'call-contract-1');
        expect(tool.name, 'count_effect');
        expect(tool.input, {'value': 'one'});

        final replay = adapter.build(
          ModelRequest(
            messages: [
              response.message!,
              Message(
                role: .tool,
                content: [
                  ToolResponsePart(
                    toolResponse: ToolResponse(
                      name: tool.name,
                      ref: tool.ref,
                      output: 'done',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        final encoded = jsonEncode(replay);
        expect(RegExp('call-contract-1').allMatches(encoded), hasLength(2));
        expect(fixture.requests, hasLength(1));
      });
    });
  }
}

ProviderFaultFixture _fixture(ProviderFaultBody body) => ProviderFaultFixture([
  () async => ProviderTransportResponse(statusCode: 200, body: body.stream),
]);

typedef _StreamCodec = Future<ModelResponse> Function(
  ProviderTransport,
  Map<String, dynamic>,
  void Function(ModelResponseChunk),
);

final class _CodecCase {
  const new(this.name, this.stream, this.build, {this.codex = false});

  final String name;
  final _StreamCodec stream;
  final Map<String, dynamic> Function(ModelRequest) build;
  final bool codex;

  List<int> text(String text) => _event(
    codex
        ? {'type': 'response.output_text.delta', 'delta': text}
        : {
            'choices': [
              {
                'index': 0,
                'delta': {'content': text},
              },
            ],
          },
  );

  List<int> done() => codex
      ? _event({'type': 'response.completed'})
      : utf8.encode('data: [DONE]\n\n');

  List<int> tool() => codex
      ? [
          ..._event({
            'type': 'response.output_item.done',
            'item': {
              'type': 'function_call',
              'call_id': 'call-contract-1',
              'name': 'count_effect',
              'arguments': '{"value":"one"}',
            },
          }),
          // The final response repeats the authoritative output snapshot.
          ..._event({
            'type': 'response.completed',
            'response': {
              'output': [
                {
                  'type': 'function_call',
                  'call_id': 'call-contract-1',
                  'name': 'count_effect',
                  'arguments': '{"value":"one"}',
                },
              ],
            },
          }),
        ]
      : [
          ..._event({
            'choices': [
              {
                'index': 0,
                'delta': {
                  'tool_calls': [
                    {
                      'index': 0,
                      'id': 'call-contract-1',
                      'type': 'function',
                      'function': {
                        'name': 'count_effect',
                        'arguments': '{"value":',
                      },
                    },
                  ],
                },
              },
            ],
          }),
          ..._event({
            'choices': [
              {
                'index': 0,
                'delta': {
                  'tool_calls': [
                    {
                      'index': 0,
                      'function': {'arguments': '"one"}'},
                    },
                  ],
                },
                'finish_reason': 'tool_calls',
              },
            ],
          }),
        ];
}

List<int> _event(Map<String, Object?> event) =>
    utf8.encode('data: ${jsonEncode(event)}\n\n');

final List<_CodecCase> _adapters = [
  for (final runtime in [
    ProviderRuntime.openAi,
    ProviderRuntime.openRouter,
    ProviderRuntime.openAiReasoning,
  ])
    _chatCase(runtime),
  _CodecCase(
    'codexOAuth',
    const OpenAICodexCodec().stream,
    (request) => const OpenAICodexCodec().buildRequestBody(
      modelName: 'contract-model',
      request: request,
      stream: true,
    ),
    codex: true,
  ),
];

_CodecCase _chatCase(ProviderRuntime runtime) {
  final codec = ChatCompletionsCodec(
    errorLabel: runtime.name,
    customize: (model, config) => switch (runtime) {
      ProviderRuntime.openAiReasoning => (
        model: model,
        extraBody: OpenAICompatReasoningOptions.fromJson(config)
            .toReasoningBody(),
      ),
      ProviderRuntime.openRouter => (
        model: model,
        extraBody: OpenRouterOptions.fromJson(config).toSamplingBody(),
      ),
      _ => (
        model: model,
        extraBody: OpenAICompatChatOptions.fromJson(config).toSamplingBody(),
      ),
    },
  );
  return _CodecCase(
    runtime.name,
    codec.stream,
    (request) => codec.buildRequestBody(
      modelName: 'contract-model',
      request: request,
      stream: true,
    ),
  );
}
