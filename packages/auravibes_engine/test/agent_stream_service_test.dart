import 'dart:async';
import 'dart:math';

import 'package:auravibes_engine/src/agent_stream_service.dart';
import 'package:test/test.dart';

import 'support/fake_cancellation_effects.dart';

void main() {
  test(
    'creates assistant message, streams chunks, and persists completion',
    () async {
      final cancellationRuntime = FakeCancellationEffects()..start('c1');
      final persistenceSink = _MemorySink<_Chunk>();
      final uiSink = _MemorySink<_Chunk>();
      final calls = <String>[];
      final usecase = AgentStreamService<_Chunk>(
        cancellationEffects: cancellationRuntime,
        provider: _FakeAgentStreamProvider(
          persistenceSink: persistenceSink,
          uiSink: uiSink,
          calls: calls,
        ),
      );

      final result = await usecase.call(
        conversationId: 'c1',
        responseStream: .fromIterable([const _Chunk('a'), const _Chunk('b')]),
        pendingUserMessageIds: const ['u1'],
      );

      expect(result.messageId, 'm1');
      expect(result.hasToolCalls, isFalse);
      expect(persistenceSink.items.map((chunk) => chunk.text), ['a', 'ab']);
      expect(uiSink.items.map((chunk) => chunk.text), ['a', 'ab']);
      expect(calls, [
        'start:c1',
        'sent:u1',
        'create:a',
        'message-stream:m1',
        'message-remove:m1',
        'complete:m1:ab',
        'remove:c1',
      ]);
    },
  );

  test(
    'completes as no-op when stream is empty without pending users',
    () async {
      final calls = <String>[];
      final usecase = AgentStreamService<_Chunk>(
        cancellationEffects: FakeCancellationEffects()..start('c1'),
        provider: _FakeAgentStreamProvider(
          persistenceSink: _MemorySink<_Chunk>(),
          uiSink: _MemorySink<_Chunk>(),
          calls: calls,
        ),
      );

      final result = await usecase.call(
        conversationId: 'c1',
        responseStream: const Stream<_Chunk>.empty(),
        pendingUserMessageIds: const [],
        allowEmptyResult: true,
      );

      expect(result.messageId, isEmpty);
      expect(result.hasToolCalls, isFalse);
      expect(calls, ['start:c1', 'remove:c1']);
    },
  );

  test(
    'throws when stream completes without result for pending users',
    () async {
      final usecase = AgentStreamService<_Chunk>(
        cancellationEffects: FakeCancellationEffects()..start('c1'),
        provider: _FakeAgentStreamProvider(
          persistenceSink: _MemorySink<_Chunk>(),
          uiSink: _MemorySink<_Chunk>(),
          calls: <String>[],
        ),
      );

      expect(
        () => usecase.call(
          conversationId: 'c1',
          responseStream: const Stream<_Chunk>.empty(),
          pendingUserMessageIds: const ['u1'],
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'marks pending users errored when stream fails before message',
    () async {
      final calls = <String>[];
      final usecase = AgentStreamService<_Chunk>(
        cancellationEffects: FakeCancellationEffects()..start('c1'),
        provider: _FakeAgentStreamProvider(
          persistenceSink: _MemorySink<_Chunk>(),
          uiSink: _MemorySink<_Chunk>(),
          calls: calls,
        ),
      );

      await expectLater(
        usecase.call(
          conversationId: 'c1',
          responseStream: .error(StateError('boom')),
          pendingUserMessageIds: const ['u1'],
        ),
        throwsA(isA<StateError>()),
      );

      expect(calls, ['start:c1', 'response-error', 'errored:u1', 'remove:c1']);
    },
  );

  test(
    'marks assistant errored when processing fails after creation',
    () async {
      final calls = <String>[];
      final usecase = AgentStreamService<_Chunk>(
        cancellationEffects: FakeCancellationEffects()..start('c1'),
        provider: _FakeAgentStreamProvider(
          persistenceSink: _MemorySink<_Chunk>(),
          uiSink: _MemorySink<_Chunk>(),
          calls: calls,
          throwOnConcat: true,
        ),
      );

      await expectLater(
        usecase.call(
          conversationId: 'c1',
          responseStream: .fromIterable([const _Chunk('a'), const _Chunk('b')]),
          pendingUserMessageIds: const [],
        ),
        throwsA(isA<StateError>()),
      );

      expect(calls, [
        'start:c1',
        'create:a',
        'message-stream:m1',
        'errored:',
        'assistant-error:m1',
        'remove:c1',
        'message-remove:m1',
      ]);
    },
  );

  test(
    'persists stopped message when cancellation is requested mid-stream',
    () async {
      final calls = <String>[];
      final cancellationRuntime = FakeCancellationEffects()..start('c1');
      final usecase = AgentStreamService<_Chunk>(
        cancellationEffects: cancellationRuntime,
        provider: _FakeAgentStreamProvider(
          persistenceSink: _MemorySink<_Chunk>(),
          uiSink: _MemorySink<_Chunk>(),
          calls: calls,
          onStartMessageStreaming: (_) => cancellationRuntime.requestStop('c1'),
        ),
      );

      final result = await usecase.call(
        conversationId: 'c1',
        responseStream: .fromIterable([const _Chunk('a'), const _Chunk('b')]),
        pendingUserMessageIds: const ['u1'],
      );

      expect(result.messageId, 'm1');
      expect(result.hasToolCalls, isFalse);
      expect(calls, [
        'start:c1',
        'sent:u1',
        'create:a',
        'message-stream:m1',
        'stopped:m1:a',
        'remove:c1',
        'message-remove:m1',
      ]);
    },
  );

  test(
    'seeded completion races settle once and ignore late stream chunks',
    () async {
      final terminalKinds = <String>{};
      for (var seed = 1; seed <= 16; seed++) {
        final trace = <String>[];
        try {
          final conversationId = 'conversation-$seed';
          final cancellationRuntime = FakeCancellationEffects();
          final cancellationScope = cancellationRuntime.start(conversationId);
          final responseStream = StreamController<_Chunk>();
          final firstChunkPersisted = Completer<void>();
          final completionStarted = Completer<void>();
          final completionRelease = Completer<void>();
          final persistenceSink = _MemorySink<_Chunk>(
            onAdd: (chunk) {
              if (chunk.text == 'first' && !firstChunkPersisted.isCompleted) {
                firstChunkPersisted.complete();
              }
            },
          );
          final uiSink = _MemorySink<_Chunk>();
          final calls = <String>[];
          final usecase = AgentStreamService<_Chunk>(
            cancellationEffects: cancellationRuntime,
            provider: _FakeAgentStreamProvider(
              persistenceSink: persistenceSink,
              uiSink: uiSink,
              calls: calls,
              onPersistCompleted: (_, _) async {
                completionStarted.complete();
                await completionRelease.future;
              },
            ),
          );

          trace.add('start:$conversationId');
          final run = usecase.call(
            conversationId: conversationId,
            responseStream: responseStream.stream,
            pendingUserMessageIds: const [],
          );
          responseStream.add(const _Chunk('first'));
          await firstChunkPersisted.future;
          trace.add('persist:first');

          if (seed.isEven) {
            trace.add('close');
            await responseStream.close();
            await completionStarted.future;
            trace.add('completion-persistence-pending');
            for (var request = 0; request < 2; request++) {
              trace.add('cancel');
              cancellationScope.requestStop();
            }
            completionRelease.complete();
          } else {
            final events = ['close', 'cancel', 'cancel']
              ..shuffle(Random(seed));
            final raceStart = Completer<void>();
            final scheduledEvents = events.map((event) async {
              await raceStart.future;
              trace.add(event);
              if (event == 'cancel') {
                cancellationScope.requestStop();
                if (!responseStream.isClosed) {
                  responseStream.add(const _Chunk('late'));
                  trace.add('emit:late');
                }
              } else {
                await responseStream.close();
              }
            }).toList();
            raceStart.complete();
            await Future.wait(scheduledEvents);
          }
          final result = await run;
          await cancellationScope.cleanupCompletion;
          final terminalWrites = calls
              .where(
                (call) =>
                    call.startsWith('stopped:') || call.startsWith('complete:'),
              )
              .toList();

          expect(result.messageId, 'm1');
          expect(result.hasToolCalls, isFalse);
          expect(terminalWrites, hasLength(1));
          terminalKinds.add(
            terminalWrites.single.startsWith('stopped:')
                ? 'stopped'
                : 'completed',
          );
          expect(persistenceSink.items.map((chunk) => chunk.text), ['first']);
          expect(uiSink.items.map((chunk) => chunk.text), ['first']);
          expect(
            calls.where((call) => call == 'start:$conversationId').toList(),
            ['start:$conversationId'],
          );
          expect(
            calls.where((call) => call == 'remove:$conversationId').toList(),
            ['remove:$conversationId'],
          );
        } on Object catch (error, stackTrace) {
          Error.throwWithStackTrace(
            StateError('seed=$seed events=${trace.join(' -> ')}\n$error'),
            stackTrace,
          );
        }
      }
      expect(terminalKinds, {'stopped', 'completed'});
    },
  );

  test(
    'keeps cancellation pending until stopped-message cleanup finishes',
    () async {
      final cancellationRuntime = FakeCancellationEffects()..start('c1');
      final cleanupRelease = Completer<void>();
      final messageStreamingStarted = Completer<void>();
      final usecase = AgentStreamService<_Chunk>(
        cancellationEffects: cancellationRuntime,
        provider: _FakeAgentStreamProvider(
          persistenceSink: _MemorySink<_Chunk>(),
          uiSink: _MemorySink<_Chunk>(),
          calls: <String>[],
          onStartMessageStreaming: (_) {
            messageStreamingStarted.complete();
            cancellationRuntime.requestStop('c1');
          },
          onPersistStopped: (_, _) => cleanupRelease.future,
        ),
      );

      final run = usecase.call(
        conversationId: 'c1',
        responseStream: .fromIterable([const _Chunk('a')]),
        pendingUserMessageIds: const [],
      );
      await messageStreamingStarted.future;
      final scope = cancellationRuntime.scope('c1');
      expect(scope, isNotNull);
      final cleanup = scope!.cleanupCompletion;
      var completed = false;
      final wait = cleanup.then((_) => completed = true);
      await Future<void>.delayed(.zero);
      expect(completed, isFalse);

      cleanupRelease.complete();
      await run;
      await wait;
      expect(completed, isTrue);
    },
  );
}

class const _Chunk(final String text);

class const _FakeAgentStreamProvider({
  required final _MemorySink<_Chunk> persistenceSink,
  required final _MemorySink<_Chunk> uiSink,
  required final List<String> calls,
  final bool throwOnConcat = false,
  final void Function(String messageId)? onStartMessageStreaming,
  final Future<void> Function(String messageId, _Chunk result)?
  onPersistCompleted,
  final Future<void> Function(String? messageId, _Chunk? result)?
  onPersistStopped,
}) implements AgentStreamProvider<_Chunk> {
  @override
  void startConversationStreaming(String conversationId) {
    calls.add('start:$conversationId');
  }

  @override
  void removeConversationStreaming(String conversationId) {
    calls.add('remove:$conversationId');
  }

  @override
  AgentChunkSink<_Chunk> createPersistenceSink(
    CurrentAgentMessageId currentMessageId,
  ) {
    return persistenceSink;
  }

  @override
  AgentChunkSink<_Chunk> createUiStreamingSink(String messageId) => uiSink;

  @override
  Future<String> createAssistantMessage({
    required String conversationId,
    required _Chunk chunk,
  }) async {
    calls.add('create:${chunk.text}');

    return 'm1';
  }

  @override
  Future<void> startMessageStreaming(String messageId) async {
    calls.add('message-stream:$messageId');
    onStartMessageStreaming?.call(messageId);
  }

  @override
  Future<void> removeMessageStreaming(String messageId) async {
    calls.add('message-remove:$messageId');
  }

  @override
  Future<void> markPendingUsersSent(List<String> messageIds) async {
    calls.add('sent:${messageIds.join(',')}');
  }

  @override
  Future<void> markPendingUsersErrored(List<String> messageIds) async {
    calls.add('errored:${messageIds.join(',')}');
  }

  @override
  Future<void> persistStoppedAssistantMessage(
    String? messageId,
    _Chunk? result,
  ) async {
    calls.add('stopped:$messageId:${result?.text}');
    await onPersistStopped?.call(messageId, result);
  }

  @override
  Future<void> persistCompletedAssistantMessage(
    String messageId,
    _Chunk result,
  ) async {
    calls.add('complete:$messageId:${result.text}');
    await onPersistCompleted?.call(messageId, result);
  }

  @override
  Future<void> markAssistantErrored(String messageId) async {
    calls.add('assistant-error:$messageId');
  }

  @override
  _Chunk concatChunks(_Chunk current, _Chunk delta) {
    if (throwOnConcat) {
      throw StateError('concat failed');
    }

    return _Chunk(current.text + delta.text);
  }

  @override
  bool shouldCreateAssistantMessage(_Chunk chunk) => chunk.text.isNotEmpty;

  @override
  bool hasToolCalls(_Chunk chunk) => false;

  @override
  void trackResponseStreamError(Object error, StackTrace stackTrace) {
    calls.add('response-error');
  }

  @override
  void trackCancellationStreamError(Object error, StackTrace stackTrace) {}
}

class _MemorySink<T>({final void Function(T)? onAdd})
    implements AgentChunkSink<T> {
  final items = <T>[];

  @override
  void add(T chunk) {
    items.add(chunk);
    onAdd?.call(chunk);
  }

  @override
  Future<void> close() async {}
}
