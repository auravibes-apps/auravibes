import 'dart:async';

import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_agent/src/agent_stream_service.dart';
import 'package:test/test.dart';

void main() {
  test(
    'creates assistant message, streams chunks, and persists completion',
    () async {
      final cancellationRuntime = AgentCancellationRuntime()..start('c1');
      final persistenceSink = _MemorySink<_Chunk>();
      final uiSink = _MemorySink<_Chunk>();
      final calls = <String>[];
      final usecase = AgentStreamService<_Chunk>(
        agentCancellationRuntime: cancellationRuntime,
        provider: _FakeAgentStreamProvider(
          persistenceSink: persistenceSink,
          uiSink: uiSink,
          calls: calls,
        ),
      );

      final result = await usecase.call(
        conversationId: 'c1',
        responseStream: Stream.fromIterable([
          const _Chunk('a'),
          const _Chunk('b'),
        ]),
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
}

class _Chunk {
  const _Chunk(this.text);

  final String text;
}

class _FakeAgentStreamProvider implements AgentStreamProvider<_Chunk> {
  const _FakeAgentStreamProvider({
    required this.persistenceSink,
    required this.uiSink,
    required this.calls,
  });

  final _MemorySink<_Chunk> persistenceSink;
  final _MemorySink<_Chunk> uiSink;
  final List<String> calls;

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
  Future<void> markPendingUsersErrored(List<String> messageIds) async {}

  @override
  Future<void> persistStoppedAssistantMessage(
    String? messageId,
    _Chunk? result,
  ) async {}

  @override
  Future<void> persistCompletedAssistantMessage(
    String messageId,
    _Chunk result,
  ) async {
    calls.add('complete:$messageId:${result.text}');
  }

  @override
  Future<void> markAssistantErrored(String messageId) async {}

  @override
  _Chunk concatChunks(_Chunk current, _Chunk delta) {
    return _Chunk(current.text + delta.text);
  }

  @override
  bool shouldCreateAssistantMessage(_Chunk chunk) => chunk.text.isNotEmpty;

  @override
  bool hasToolCalls(_Chunk chunk) => false;

  @override
  void trackResponseStreamError(Object error, StackTrace stackTrace) {}

  @override
  void trackCancellationStreamError(Object error, StackTrace stackTrace) {}
}

class _MemorySink<T> implements AgentChunkSink<T> {
  final items = <T>[];

  @override
  void add(T chunk) {
    items.add(chunk);
  }

  @override
  Future<void> close() async {}
}
