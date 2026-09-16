import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/stop_conversation_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _ConversationRepository extends Mock implements ConversationRepository;

class _MessageRepository extends Mock implements MessageRepository;

void _noop(Object? value) {
  if (value == null) return;
}

void _noopPair(Object? first, Object? second) {
  if (identical(first, second)) return;
}

void main() {
  test('stops active descendants before the parent', () async {
    final conversationRepository = _ConversationRepository();
    final messageRepository = _MessageRepository();
    when(() => conversationRepository.getChildConversations(any()))
        .thenAnswer((_) async => const []);
    when(() => messageRepository.getMessagesByConversation(any()))
        .thenAnswer((_) async => const []);

    final cancellationRuntime = AgentCancellationRuntime();
    final stopped = <String>[];
    final sendQueueRuntime = ConversationSendQueueRuntime(
      enqueue: ({required conversationId, required draft}) =>
          throw StateError('not used'),
      dequeueAll: (_) => const [],
      clear: stopped.add,
    );
    final streamingRuntime = ConversationStreamingRuntime(
      start: _noop,
      isStreaming: (_) => false,
      remove: stopped.add,
    );
    final retryRuntime = ConversationRateLimitRetryRuntime(
      start: _noopPair,
      retryAt: (_) => null,
      clear: stopped.add,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final activeSubAgents = container.read(
      activeSubAgentRuntimeProvider.notifier,
    );
    final _ = activeSubAgents.start(parentId: 'root', childId: 'child');

    final usecase = StopConversationUsecase(
      conversationRepository: conversationRepository,
      messageRepository: messageRepository,
      cancellationRuntime: cancellationRuntime,
      sendQueueRuntime: sendQueueRuntime,
      streamingRuntime: streamingRuntime,
      retryRuntime: retryRuntime,
      activeSubAgents: activeSubAgents,
    );

    await usecase.call('root');

    expect(stopped, ['child', 'child', 'child', 'root', 'root', 'root']);
    verify(() => messageRepository.getMessagesByConversation('child'))
        .called(1);
    verify(() => messageRepository.getMessagesByConversation('root')).called(1);
    expect(activeSubAgents.childrenOf('root'), isEmpty);
  });
}
