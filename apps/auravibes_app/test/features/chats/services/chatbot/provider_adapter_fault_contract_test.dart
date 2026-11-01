import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/services/chatbot/anthropic_request_exception.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart' as sdk;
import 'package:schemantic/schemantic.dart';

import 'support/provider_adapter_case.dart';
import 'support/provider_fault_client.dart';

void main() {
  test('covers every selected runtime and production plugin path', () {
    final actual = {
      for (final adapter in providerAdapterCases)
        (runtime: adapter.runtime, path: adapter.path),
    };
    expect(actual, {
      (
        runtime: ProviderRuntime.openAi,
        path: ProviderPluginPath.upstreamOpenAi,
      ),
      (
        runtime: ProviderRuntime.openAi,
        path: ProviderPluginPath.appChatCompletions,
      ),
      (
        runtime: ProviderRuntime.openRouter,
        path: ProviderPluginPath.appChatCompletions,
      ),
      (
        runtime: ProviderRuntime.openAiReasoning,
        path: ProviderPluginPath.appChatCompletions,
      ),
      (runtime: ProviderRuntime.codexOAuth, path: ProviderPluginPath.codex),
      (runtime: ProviderRuntime.anthropic, path: ProviderPluginPath.anthropic),
    });
    expect(
      actual.map((selection) => selection.runtime).toSet(),
      ProviderRuntime.values.toSet(),
    );
    expect(providerAdapterCases, hasLength(actual.length));
  });

  for (final adapter in providerAdapterCases) {
    group(adapter.name, () {
      test('decodes partial and delayed chunks exactly once', () async {
        final body = ProviderFaultBody();
        addTearDown(body.dispose);
        final harness = _Harness.create(adapter, [
          (_) async => _stream(body.stream),
        ]);
        final firstChunk = Completer<void>();
        final generation = harness.run(onText: firstChunk.complete);
        await body.listened;
        body.add(adapter.protocol.start());
        final first = adapter.protocol.text('Hello ');
        body
          ..add(first.sublist(0, 2))
          ..add(first.sublist(2));
        await firstChunk.future;
        expect(harness.text, 'Hello ');

        final globe = String.fromCharCode(0x1f30d);
        final bytes = adapter.protocol.text(globe);
        final split = bytes.indexOf(0xf0) + 2;
        body
          ..add(bytes.sublist(0, split))
          ..add([...bytes.sublist(split), ...adapter.protocol.done()]);
        await body.close();
        final result = await generation;

        expect(result.finishReason, FinishReason.stop);
        expect(result.text, 'Hello $globe');
        expect(harness.text, result.text);
        expect(harness.client.requests, hasLength(1));
        expect(harness.effects, isEmpty);
        expect(body.cancellationCount, 1);
        _expectRequest(adapter, harness.client.requests.single);
      });

      for (final timeout in [false, true]) {
        test('${timeout ? 'timeout' : 'disconnect'} before headers', () async {
          final failure = timeout
              ? TimeoutException('fixture timeout')
              : http.ClientException('fixture disconnect');
          final harness = _Harness.create(adapter, [
            (_) async => throw failure,
            (_) async => _success(adapter),
          ]);
          final result = await harness.run();

          expect(
            result.finishReason,
            adapter.retriesTransport ? FinishReason.stop : FinishReason.failed,
          );
          expect(
            harness.client.requests,
            hasLength(adapter.retriesTransport ? 2 : 1),
          );
          expect(harness.effects, isEmpty);
          if (adapter.retriesTransport) {
            _expectStableRequests(harness.client.requests);
            expect(harness.retryDelays, [Duration.zero]);
          } else {
            expect(result.cause, isNotNull);
          }
        });

        test(
          '${timeout ? 'timeout' : 'disconnect'} after output never replays',
          () async {
            final body = ProviderFaultBody();
            addTearDown(body.dispose);
            final harness = _Harness.create(adapter, [
              (_) async => _stream(body.stream),
            ]);
            final firstChunk = Completer<void>();
            final generation = harness.run(onText: firstChunk.complete);
            await body.listened;
            body.add([
              ...adapter.protocol.start(),
              ...adapter.protocol.text('partial'),
            ]);
            await firstChunk.future;
            body.fail(
              timeout
                  ? TimeoutException('fixture timeout')
                  : http.ClientException('fixture disconnect'),
            );
            final result = await generation;
            await body.cancelled;

            expect(result.finishReason, FinishReason.failed);
            expect(result.cause, isNotNull);
            expect(harness.text, 'partial');
            expect(harness.client.requests, hasLength(1));
            expect(harness.retryDelays, isEmpty);
            expect(harness.effects, isEmpty);
            expect(body.cancellationCount, 1);
          },
        );
      }

      for (final status in [401, 403]) {
        test('authentication HTTP $status never retries', () async {
          final harness = _Harness.create(adapter, [
            (_) async => _error(status),
          ]);
          final result = await harness.run();
          final failure = result.cause;

          expect(result.finishReason, FinishReason.failed);
          expect(failure, isNotNull);
          if (failure == null) fail('Expected provider HTTP failure');
          final cause = failure;
          _expectHttpCause(adapter, cause, status);
          final recovery = ProviderFailureRecovery.fromError(cause);
          expect(recovery.retryable, isFalse);
          expect(
            recovery.category,
            adapter.losesHttpMetadata
                ? ProviderFailureCategory.unknown
                : ProviderFailureCategory.authentication,
          );
          expect(harness.client.requests, hasLength(1));
          expect(harness.retryDelays, isEmpty);
          expect(harness.effects, isEmpty);
        });
      }

      for (final header in [null, 'invalid', '-1', '12', '120']) {
        test('rate limit Retry-After=$header has explicit policy', () async {
          final harness = _Harness.create(adapter, [
            (_) async => _error(429, retryAfter: header),
          ]);
          final result = await harness.run();
          final failure = result.cause;
          expect(result.finishReason, FinishReason.failed);
          expect(failure, isNotNull);
          if (failure == null) fail('Expected provider HTTP failure');
          final cause = failure;
          _expectHttpCause(adapter, cause, 429);
          final recovery = ProviderFailureRecovery.fromError(cause);
          final seconds = int.tryParse(header ?? '');
          Duration? delay;
          if (seconds != null) {
            if (seconds < 0) {
              delay = Duration.zero;
            } else if (adapter.path == ProviderPluginPath.codex &&
                seconds > 60) {
              delay = const Duration(seconds: 60);
            } else {
              delay = Duration(seconds: seconds);
            }
          }

          expect(
            recovery.category,
            adapter.losesHttpMetadata
                ? ProviderFailureCategory.unknown
                : ProviderFailureCategory.quotaRateLimit,
          );
          expect(recovery.retryAfter, adapter.losesHttpMetadata ? null : delay);
          expect(
            recovery.retryable,
            !adapter.losesHttpMetadata && delay != null,
          );
          if (adapter.retriesTransport && delay != null) {
            expect(failure, isA<AgentRateLimitRetryException>());
          } else {
            expect(failure, isNot(isA<AgentRateLimitRetryException>()));
          }
          expect(harness.client.requests, hasLength(1));
          expect(harness.retryDelays, isEmpty);
          expect(harness.effects, isEmpty);
        });
      }

      test('non-stream authentication remains non-retryable', () async {
        final harness = _Harness.create(adapter, [(_) async => _error(401)]);
        final result = await harness.run(streaming: false);
        final failure = result.cause;
        expect(result.finishReason, FinishReason.failed);
        expect(failure, isNotNull);
        if (failure == null) fail('Expected provider HTTP failure');
        final recovery = ProviderFailureRecovery.fromError(failure);
        expect(recovery.retryable, isFalse);
        expect(
          recovery.category,
          adapter.path == ProviderPluginPath.anthropic
              ? ProviderFailureCategory.unknown
              : ProviderFailureCategory.authentication,
        );
        expect(harness.client.requests, hasLength(1));
        expect(harness.effects, isEmpty);
      });

      for (final status in [500, 502, 503, 504]) {
        for (final structured in [false, true]) {
          test(
            'HTTP $status structured=$structured obeys retry rule',
            () async {
              final harness = _Harness.create(adapter, [
                (_) async => _error(status, structured: structured),
                (_) async => _success(adapter),
              ]);
              final retries =
                  adapter.retriesTransport ||
                  (adapter.path == ProviderPluginPath.codex &&
                      status == 500 &&
                      structured);
              final result = await harness.run();

              expect(
                result.finishReason,
                retries ? FinishReason.stop : FinishReason.failed,
              );
              expect(harness.client.requests, hasLength(retries ? 2 : 1));
              expect(harness.effects, isEmpty);
              if (retries) _expectStableRequests(harness.client.requests);
            },
          );
        }
      }

      test('preserves one complete tool-call identity', () async {
        final harness = _Harness.create(adapter, [
          (_) async => _stream(
            .fromIterable([
              adapter.protocol.start(),
              adapter.protocol.tool(),
              adapter.protocol.done(tool: true),
            ]),
          ),
        ]);
        final result = await harness.run();

        expect(result.toolRequests, hasLength(1));
        final tool = result.toolRequests.single;
        expect(tool.ref, 'call-contract-1');
        expect(tool.name, 'count_effect');
        expect(tool.input, {'value': 'one'});
        expect(harness.effects, isEmpty);
        expect(harness.client.requests, hasLength(1));
      });

      test('a failed tool-bearing stream has zero side effects', () async {
        final body = ProviderFaultBody();
        addTearDown(body.dispose);
        final harness = _Harness.create(adapter, [
          (_) async => _stream(body.stream),
        ]);
        final firstChunk = Completer<void>();
        final generation = harness.run(
          executeTools: true,
          onText: firstChunk.complete,
        );
        await body.listened;
        body.add([
          ...adapter.protocol.start(),
          ...adapter.protocol.text('partial'),
        ]);
        await firstChunk.future;
        body
          ..add(adapter.protocol.tool())
          ..fail(http.ClientException('disconnect before terminal event'));
        final result = await generation;

        expect(result.finishReason, FinishReason.failed);
        expect(harness.text, 'partial');
        expect(harness.effects, isEmpty);
        expect(harness.client.requests, hasLength(1));
      });

      test('a successful tool exchange applies its side effect once', () async {
        final retries =
            adapter.retriesTransport ||
            adapter.path == ProviderPluginPath.codex;
        final harness = _Harness.create(adapter, [
          if (retries) (_) async => _error(500, structured: true),
          (_) async => _stream(
            .fromIterable([
              adapter.protocol.start(),
              adapter.protocol.tool(),
              adapter.protocol.done(tool: true),
            ]),
          ),
          (_) async => _success(adapter),
        ]);
        final result = await harness.run(executeTools: true);

        expect(result.finishReason, FinishReason.stop);
        expect(harness.effects, ['call-contract-1:one']);
        expect(harness.client.requests, hasLength(retries ? 3 : 2));
        if (retries) {
          _expectStableRequests(harness.client.requests.take(2).toList());
        }
        final followUp = harness.client.requests.last.body;
        expect(RegExp('call-contract-1').allMatches(followUp), hasLength(2));
      });

      test('cancellation before headers aborts the actual transport', () async {
        final response = Completer<http.StreamedResponse>();
        final harness = _Harness.create(adapter, [(_) => response.future]);
        final cancellation = CancellationController();
        final generation = harness.run(cancellation: cancellation);
        addTearDown(() async {
          if (!response.isCompleted) response.complete(_success(adapter));
          await expectLater(generation, completes);
        });
        final request = await harness.client.requestAt(0);
        cancellation.cancel();

        // Assert before awaiting completion so a missing abort trigger fails
        // directly, with teardown releasing the pending fake response.
        expect(request.supportsAbort, isTrue);
        final result = await generation;
        expect(result.finishReason, FinishReason.aborted);
        expect(harness.client.abortCount, 1);
        expect(harness.client.requests, hasLength(1));
        expect(harness.effects, isEmpty);
      });

      test(
        'cancellation closes an idle stream and rejects later tool effects',
        () async {
          final body = ProviderFaultBody();
          addTearDown(body.dispose);
          final harness = _Harness.create(adapter, [
            (_) async => _stream(body.stream),
          ]);
          final cancellation = CancellationController();
          final firstChunk = Completer<void>();
          final generation = harness.run(
            executeTools: true,
            cancellation: cancellation,
            onText: firstChunk.complete,
          );
          addTearDown(() async {
            body.dispose();
            await expectLater(generation, completes);
          });
          await body.listened;
          body.add([
            ...adapter.protocol.start(),
            ...adapter.protocol.text('partial'),
          ]);
          await firstChunk.future;
          cancellation.cancel();

          expect(harness.client.requests.single.supportsAbort, isTrue);
          final result = await generation;
          await body.cancelled;
          body.add([
            ...adapter.protocol.text('late'),
            ...adapter.protocol.tool(),
            ...adapter.protocol.done(tool: true),
          ]);
          expect(result.finishReason, FinishReason.aborted);
          expect(harness.text, 'partial');
          expect(harness.effects, isEmpty);
          expect(body.cancellationCount, 1);
          expect(harness.client.requests, hasLength(1));
          expect(
            harness.client.closeCount,
            adapter.path == ProviderPluginPath.upstreamOpenAi ? 1 : 0,
          );
        },
      );

      if (adapter.retriesTransport) {
        for (final retryAfter in ['12', '120', 'invalid', '-1']) {
          test('server retry waits for Retry-After=$retryAfter', () async {
            final waiting = Completer<void>();
            final release = Completer<void>();
            final harness = _Harness.create(
              adapter,
              [
                (_) async => _error(503, retryAfter: retryAfter),
                (_) async => _success(adapter),
              ],
              retryWait: (_) {
                waiting.complete();

                return release.future;
              },
            );
            final generation = harness.run();
            addTearDown(() {
              if (!release.isCompleted) release.complete();
            });
            await waiting.future;
            final expected = switch (retryAfter) {
              '12' => const Duration(seconds: 12),
              '120' => const Duration(seconds: 60),
              _ => Duration.zero,
            };
            expect(harness.retryDelays, [expected]);
            expect(harness.client.requests, hasLength(1));
            release.complete();
            final result = await generation;

            expect(result.finishReason, FinishReason.stop);
            expect(harness.client.requests, hasLength(2));
            _expectStableRequests(harness.client.requests);
          });
        }

        test('cancellation during a retry wait prevents any resend', () async {
          final waiting = Completer<void>();
          final release = Completer<void>();
          final waitSettled = Completer<void>();
          final harness = _Harness.create(
            adapter,
            [(_) async => _error(503, retryAfter: '12')],
            retryWait: (_) async {
              waiting.complete();
              await release.future;
              waitSettled.complete();
            },
          );
          final cancellation = CancellationController();
          final generation = harness.run(cancellation: cancellation);
          await waiting.future;
          cancellation.cancel();
          final result = await generation;
          release.complete();
          await waitSettled.future;
          // One event turn drains the callback's queued await continuations;
          // assertions must also catch a resend after the old wait completes.
          final continuationsDrained = Completer<void>();
          Timer.run(continuationsDrained.complete);
          await continuationsDrained.future;

          expect(result.finishReason, FinishReason.aborted);
          expect(harness.retryDelays, [const Duration(seconds: 12)]);
          expect(harness.client.requests, hasLength(1));
          expect(harness.effects, isEmpty);
        });
      }

      if (adapter.retriesTransport ||
          adapter.path == ProviderPluginPath.codex) {
        test(
          'cancellation prevents an otherwise permitted server retry',
          () async {
            final body = ProviderFaultBody();
            addTearDown(body.dispose);
            final harness = _Harness.create(adapter, [
              (_) async => http.StreamedResponse(body.stream, 500),
            ]);
            final cancellation = CancellationController();
            final generation = harness.run(cancellation: cancellation);
            await body.listened;
            cancellation.cancel();
            final result = await generation;
            await body.cancelled;
            body.add(utf8.encode('{"error":{"type":"server_error"}}'));

            expect(result.finishReason, FinishReason.aborted);
            expect(harness.client.requests, hasLength(1));
            expect(harness.retryDelays, isEmpty);
            expect(harness.effects, isEmpty);
          },
        );

        test('stops after its one permitted server retry', () async {
          final harness = _Harness.create(adapter, [
            (_) async => _error(500, structured: true),
            (_) async => _error(500, structured: true),
          ]);
          final result = await harness.run();

          expect(result.finishReason, FinishReason.failed);
          expect(harness.client.requests, hasLength(2));
          expect(harness.effects, isEmpty);
          _expectStableRequests(harness.client.requests);
        });

        test('enforces a zero header deadline without a real sleep', () async {
          final response = Completer<http.StreamedResponse>();
          final attempts = <ProviderFaultAttempt>[
            (_) => response.future,
            (_) => response.future,
          ];
          final harness = _Harness.create(
            adapter,
            attempts,
            requestTimeout: .zero,
          );
          addTearDown(() {
            if (!response.isCompleted) response.complete(_success(adapter));
          });
          final result = await harness.run();

          expect(result.finishReason, FinishReason.failed);
          expect(result.cause, isA<TimeoutException>());
          expect(
            harness.client.requests,
            hasLength(adapter.retriesTransport ? 2 : 1),
          );
          expect(harness.effects, isEmpty);
        });
      }
    });
  }
}

final class _Harness(
  final ProviderAdapterCase adapter,
  final ProviderFaultClient client,
  final Genkit ai,
  final Tool<Map<String, Object?>, Object?> tool,
  final List<Duration> retryDelays,
  final List<String> effects,
) {
  factory create(
    ProviderAdapterCase adapter,
    List<ProviderFaultAttempt> attempts, {
    Future<void> Function(Duration)? retryWait,
    Duration requestTimeout = const Duration(seconds: 30),
  }) {
    final client = ProviderFaultClient(attempts);
    final retryDelays = <Duration>[];
    final effects = <String>[];
    final ai = adapter.createGenkit(
      client,
      requestTimeout: requestTimeout,
      retryWait: (delay) {
        retryDelays.add(delay);

        return retryWait?.call(delay) ?? Future.value();
      },
    );
    final tool = ai.defineTool<Map<String, Object?>, Object?>(
      name: 'count_effect',
      description: 'Count one fixture effect.',
      inputSchema: SchemanticType.from<Map<String, Object?>>(
        jsonSchema: const {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
          'required': ['value'],
          'additionalProperties': false,
        },
        parse: (value) => value as Map<String, Object?>,
      ),
      fn: (input, context) async {
        effects.add(
          '${context.toolRequest?.toolRequest.ref}:${input['value']}',
        );

        return const ToolResponseResult<Object?>('effect applied');
      },
    );
    addTearDown(client.close);

    return _Harness(adapter, client, ai, tool, retryDelays, effects);
  }

  final List<String> _text = [];

  String get text => _text.join();

  Future<GenerateResult<Object?>> run({
    bool executeTools = false,
    bool streaming = true,
    CancellationController? cancellation,
    void Function()? onText,
  }) => http.runWithClient(
    () => ai.generate<Object?, Object?>(
      model: modelRef<Object?>(adapter.modelName),
      messages: [
        Message(
          role: .user,
          content: [TextPart(text: 'Run the contract.')],
        ),
      ],
      tools: [tool],
      returnToolRequests: !executeTools,
      cancel: cancellation?.token,
      onChunk: streaming
          ? (chunk) {
              if (chunk.text.isEmpty) return;
              _text.add(chunk.text);
              if (_text.length == 1) onText?.call();
            }
          : null,
    ),
    () => client,
  );
}

http.StreamedResponse _stream(Stream<List<int>> stream) =>
    http.StreamedResponse(
      stream,
      200,
      headers: const {'content-type': 'text/event-stream'},
    );

http.StreamedResponse _success(ProviderAdapterCase adapter) =>
    _stream(.value(adapter.protocol.success('ready')));

http.StreamedResponse _error(
  int status, {
  bool structured = false,
  String? retryAfter,
}) => http.StreamedResponse(
  .value(
    utf8.encode(
      jsonEncode({
        'type': 'error',
        'error': {
          'type': structured ? 'server_error' : 'invalid_request_error',
          'message': 'fixture provider error',
        },
      }),
    ),
  ),
  status,
  headers: {'content-type': 'application/json', 'retry-after': ?retryAfter},
);

void _expectRequest(ProviderAdapterCase adapter, ProviderFaultRequest request) {
  expect(request.method, 'POST');
  expect(request.url.host, 'provider.invalid');
  expect(request.url.path, switch (adapter.path) {
    .codex => '/responses',
    .anthropic => '/v1/messages',
    _ => '/v1/chat/completions',
  });
  expect(request.json['model'], 'contract-model');
  expect(request.json['stream'], isTrue);
}

void _expectStableRequests(List<ProviderFaultRequest> requests) {
  expect(requests, hasLength(2));
  final first = requests.firstOrNull;
  if (first == null) fail('Expected a first provider request');
  final last = requests.last;
  expect(last.method, first.method);
  expect(last.url, first.url);
  expect(last.json, first.json);
  expect(last.headers, first.headers);
}

void _expectHttpCause(ProviderAdapterCase adapter, Object error, int status) {
  switch (adapter.path) {
    case .anthropic:
      expect(
        error,
        isA<AnthropicRequestException>().having(
          (failure) => failure.code,
          'redacted code',
          'provider_failure',
        ),
      );
    case .upstreamOpenAi:
      expect(error, isA<GenkitException>());
      final genkit = error as GenkitException;
      expect(genkit.status, StatusCode.internal);
      expect(
        genkit.cause,
        isA<sdk.ApiException>().having(
          (failure) => failure.statusCode,
          'upstream HTTP status',
          status,
        ),
      );
    case .appChatCompletions:
      final providerError = switch (error) {
        AgentRateLimitRetryException(:final providerException) =>
          providerException,
        _ => error,
      };
      expect(
        providerError,
        isA<ProviderHttpFailureException>().having(
          (failure) => failure.httpStatusCode,
          'HTTP status',
          status,
        ),
      );
    case .codex:
      expect(
        error,
        isA<ProviderHttpFailureException>().having(
          (failure) => failure.httpStatusCode,
          'HTTP status',
          status,
        ),
      );
  }
}
