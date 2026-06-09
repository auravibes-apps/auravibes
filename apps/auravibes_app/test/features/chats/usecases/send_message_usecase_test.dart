// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: missing-test-assertion
// Required: Tests verify usecase behavior through queue side effects.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'send_message_usecase_test.mocks.dart';

@GenerateMocks([
  RunAgentIterationUsecase,
  MessageRepository,
  GetConversationBusyStateUsecase,
])
void main() {
  group('SendMessageUsecase', () {
    var fixture = _SendMessageUsecaseFixture.create();

    setUp(() {
      fixture.dispose();
      fixture = _SendMessageUsecaseFixture.create();

      when(fixture.messageRepository.createMessage(any)).thenAnswer(
        (_) async => MessageEntity(
          id: 'user-1',
          conversationId: 'conversation-1',
          content: 'Hello',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      );
      when(
        fixture.runAgentIterationUsecase.call(
          conversationId: anyNamed('conversationId'),
          context: anyNamed('context'),
        ),
      ).thenAnswer((_) async => AgentIterationDecision.done);
      when(
        fixture.getConversationBusyStateUsecase.call(
          conversationId: anyNamed('conversationId'),
        ),
      ).thenAnswer(
        (_) async => const ConversationBusyState(
          isStreaming: false,
          hasPendingTools: false,
        ),
      );
    });

    tearDown(() {
      fixture.dispose();
    });

    test('forwards the created user message id as the ack target', () async {
      await fixture.usecase.call(
        conversationId: 'conversation-1',
        content: 'Hello',
      );

      verify(
        fixture.runAgentIterationUsecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        ),
      ).called(1);
    });

    test(
      'queues the draft instead of persisting when the conversation is busy',
      () async {
        when(
          fixture.getConversationBusyStateUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => const ConversationBusyState(
            isStreaming: true,
            hasPendingTools: false,
          ),
        );

        await fixture.usecase.call(
          conversationId: 'conversation-1',
          content: 'Queued hello',
        );

        final _ = verifyNever(fixture.messageRepository.createMessage(any));
        final _ = verifyNever(
          fixture.runAgentIterationUsecase.call(
            conversationId: anyNamed('conversationId'),
            context: anyNamed('context'),
          ),
        );
        expect(
          fixture.container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1')
              ?.content,
          'Queued hello',
        );
      },
    );
  });
}

class _SendMessageUsecaseFixture {
  _SendMessageUsecaseFixture({
    required this.runAgentIterationUsecase,
    required this.messageRepository,
    required this.getConversationBusyStateUsecase,
    required this.container,
    required this.usecase,
  });

  factory _SendMessageUsecaseFixture.create() {
    final runAgentIterationUsecase = MockRunAgentIterationUsecase();
    final messageRepository = MockMessageRepository();
    final getConversationBusyStateUsecase =
        MockGetConversationBusyStateUsecase();
    final container = ProviderContainer();
    final queueNotifier = container.read(
      conversationSendQueueProvider.notifier,
    );

    return _SendMessageUsecaseFixture(
      runAgentIterationUsecase: runAgentIterationUsecase,
      messageRepository: messageRepository,
      getConversationBusyStateUsecase: getConversationBusyStateUsecase,
      container: container,
      usecase: SendMessageUsecase(
        runAgentIterationUsecase: runAgentIterationUsecase,
        messageRepository: messageRepository,
        getConversationBusyStateUsecase: getConversationBusyStateUsecase,
        sendQueueRuntime: ConversationSendQueueRuntime(
          enqueue: queueNotifier.enqueue,
          dequeueAll: queueNotifier.dequeueAll,
          clear: queueNotifier.clear,
        ),
      ),
    );
  }

  final MockRunAgentIterationUsecase runAgentIterationUsecase;
  final MockMessageRepository messageRepository;
  final MockGetConversationBusyStateUsecase getConversationBusyStateUsecase;
  final ProviderContainer container;
  final SendMessageUsecase usecase;
  var _isDisposed = false;

  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    container.dispose();
  }
}
