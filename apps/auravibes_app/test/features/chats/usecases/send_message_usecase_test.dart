import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
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
    late MockRunAgentIterationUsecase runAgentIterationUsecase;
    late MockMessageRepository messageRepository;
    late MockGetConversationBusyStateUsecase getConversationBusyStateUsecase;
    late ProviderContainer container;
    late SendMessageUsecase usecase;

    setUp(() {
      runAgentIterationUsecase = MockRunAgentIterationUsecase();
      messageRepository = MockMessageRepository();
      getConversationBusyStateUsecase = MockGetConversationBusyStateUsecase();
      container = ProviderContainer();
      usecase = SendMessageUsecase(
        runAgentIterationUsecase: runAgentIterationUsecase,
        messageRepository: messageRepository,
        getConversationBusyStateUsecase: getConversationBusyStateUsecase,
        conversationSendQueueNotifier: container.read(
          conversationSendQueueProvider.notifier,
        ),
      );

      when(messageRepository.createMessage(any)).thenAnswer(
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
        runAgentIterationUsecase.call(
          conversationId: anyNamed('conversationId'),
          context: anyNamed('context'),
        ),
      ).thenAnswer((_) async => AgentIterationDecision.done);
      when(
        getConversationBusyStateUsecase.call(
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
      container.dispose();
    });

    test('forwards the created user message id as the ack target', () async {
      await usecase.call(
        conversationId: 'conversation-1',
        content: 'Hello',
      );

      verify(
        runAgentIterationUsecase.call(
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
          getConversationBusyStateUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => const ConversationBusyState(
            isStreaming: true,
            hasPendingTools: false,
          ),
        );

        await usecase.call(
          conversationId: 'conversation-1',
          content: 'Queued hello',
        );

        verifyNever(messageRepository.createMessage(any));
        verifyNever(
          runAgentIterationUsecase.call(
            conversationId: anyNamed('conversationId'),
            context: anyNamed('context'),
          ),
        );
        expect(
          container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1')
              ?.content,
          'Queued hello',
        );
      },
    );
  });
}
