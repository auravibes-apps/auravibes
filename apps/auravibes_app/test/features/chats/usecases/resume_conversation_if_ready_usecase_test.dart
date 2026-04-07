import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/resume_conversation_if_ready_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'resume_conversation_if_ready_usecase_test.mocks.dart';

@GenerateMocks([
  MessageRepository,
  ConversationRepository,
  RunAllowedToolsUsecase,
  RunAgentIterationUsecase,
])
void main() {
  group('ResumeConversationIfReadyUsecase', () {
    late MockMessageRepository messageRepository;
    late MockConversationRepository conversationRepository;
    late MockRunAllowedToolsUsecase runAllowedToolsUsecase;
    late MockRunAgentIterationUsecase runAgentIterationUsecase;
    late ResumeConversationIfReadyUsecase usecase;

    const messageId = 'message-1';
    const conversationId = 'conversation-1';
    const workspaceId = 'workspace-1';

    final message = MessageEntity(
      id: messageId,
      conversationId: conversationId,
      content: 'assistant',
      messageType: MessageType.text,
      isUser: false,
      status: MessageStatus.sent,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final conversation = ConversationEntity(
      id: conversationId,
      title: 'Test',
      workspaceId: workspaceId,
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    setUp(() {
      messageRepository = MockMessageRepository();
      conversationRepository = MockConversationRepository();
      runAllowedToolsUsecase = MockRunAllowedToolsUsecase();
      runAgentIterationUsecase = MockRunAgentIterationUsecase();

      usecase = ResumeConversationIfReadyUsecase(
        messageRepository: messageRepository,
        conversationRepository: conversationRepository,
        runAllowedToolsUsecase: runAllowedToolsUsecase,
        runAgentIterationUsecase: runAgentIterationUsecase,
      );
    });

    test('returns early when message not found', () async {
      when(messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => null,
      );

      await usecase.call(messageId: messageId);

      verifyNever(conversationRepository.getConversationById(any));
      verifyNever(
        runAllowedToolsUsecase.call(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
        ),
      );
    });

    test('returns early when conversation not found', () async {
      when(messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(
        conversationRepository.getConversationById(conversationId),
      ).thenAnswer((_) async => null);

      await usecase.call(messageId: messageId);

      verifyNever(
        runAllowedToolsUsecase.call(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
        ),
      );
    });

    test('returns early when decision is not continueIteration', () async {
      when(messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(
        conversationRepository.getConversationById(conversationId),
      ).thenAnswer((_) async => conversation);
      when(
        runAllowedToolsUsecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ),
      ).thenAnswer((_) async => AgentIterationDecision.waitForToolApproval);

      await usecase.call(messageId: messageId);

      verifyNever(
        runAgentIterationUsecase.call(
          conversationId: anyNamed('conversationId'),
          context: anyNamed('context'),
        ),
      );
    });

    test('invokes RunAgentIterationUsecase on continueIteration', () async {
      when(messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(
        conversationRepository.getConversationById(conversationId),
      ).thenAnswer((_) async => conversation);
      when(
        runAllowedToolsUsecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ),
      ).thenAnswer((_) async => AgentIterationDecision.continueIteration);
      when(
        runAgentIterationUsecase.call(
          conversationId: anyNamed('conversationId'),
          context: anyNamed('context'),
        ),
      ).thenAnswer((_) async => AgentIterationDecision.done);

      await usecase.call(messageId: messageId);

      verify(
        runAgentIterationUsecase.call(
          conversationId: conversationId,
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.toolResume,
          ),
        ),
      ).called(1);
    });
  });
}
