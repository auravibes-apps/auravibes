import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'send_message_usecase_test.mocks.dart';

@GenerateMocks([
  RunAgentIterationUsecase,
  MessageRepository,
])
void main() {
  group('SendMessageUsecase', () {
    late MockRunAgentIterationUsecase runAgentIterationUsecase;
    late MockMessageRepository messageRepository;
    late SendMessageUsecase usecase;

    setUp(() {
      runAgentIterationUsecase = MockRunAgentIterationUsecase();
      messageRepository = MockMessageRepository();
      usecase = SendMessageUsecase(
        runAgentIterationUsecase: runAgentIterationUsecase,
        messageRepository: messageRepository,
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
            ackMessageId: 'user-1',
          ),
        ),
      ).called(1);
    });
  });
}
