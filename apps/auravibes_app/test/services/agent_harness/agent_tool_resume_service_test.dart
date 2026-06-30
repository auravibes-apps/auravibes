import 'package:auravibes_agent/auravibes_agent.dart'
    show AgentIterationContext, AgentIterationDecision, AgentIterationOrigin;
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_resume_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('AgentToolResumeService', () {
    var messageRepository = MockMessageRepository();
    var conversationRepository = MockConversationRepository();
    var toolExecutionService = MockAgentToolExecutionService();
    var agentService = MockAgentService();
    var usecase = AgentToolResumeService(
      messageRepository: messageRepository,
      conversationRepository: conversationRepository,
      toolExecutionService: toolExecutionService,
      agentService: agentService,
    );

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
      toolExecutionService = MockAgentToolExecutionService();
      agentService = MockAgentService();

      usecase = AgentToolResumeService(
        messageRepository: messageRepository,
        conversationRepository: conversationRepository,
        toolExecutionService: toolExecutionService,
        agentService: agentService,
      );
    });

    test('returns early when message not found', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => null,
      );

      await expectLater(usecase.call(messageId: messageId), completes);

      expect(
        () => verifyNever(
          () => conversationRepository.getConversationById(any()),
        ),
        returnsNormally,
      );
      expect(
        () => verifyNever(
          () => toolExecutionService.call(
            conversationId: any(named: 'conversationId'),
            workspaceId: any(named: 'workspaceId'),
          ),
        ),
        returnsNormally,
      );
    });

    test('returns early when conversation not found', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(
        () => conversationRepository.getConversationById(conversationId),
      ).thenAnswer((_) async => null);

      await expectLater(usecase.call(messageId: messageId), completes);

      expect(
        () => verifyNever(
          () => toolExecutionService.call(
            conversationId: any(named: 'conversationId'),
            workspaceId: any(named: 'workspaceId'),
          ),
        ),
        returnsNormally,
      );
    });

    test('returns early when decision is not continueIteration', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(
        () => conversationRepository.getConversationById(conversationId),
      ).thenAnswer((_) async => conversation);
      when(
        () => toolExecutionService.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ),
      ).thenAnswer((_) async => AgentIterationDecision.waitForToolApproval);

      await expectLater(usecase.call(messageId: messageId), completes);

      expect(
        () => verifyNever(
          () => agentService.call(
            conversationId: any(named: 'conversationId'),
            context: any(named: 'context'),
          ),
        ),
        returnsNormally,
      );
    });

    test('invokes AgentService on continueIteration', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(
        () => conversationRepository.getConversationById(conversationId),
      ).thenAnswer((_) async => conversation);
      when(
        () => toolExecutionService.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ),
      ).thenAnswer((_) async => AgentIterationDecision.continueIteration);
      when(
        () => agentService.call(
          conversationId: any(named: 'conversationId'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => AgentIterationDecision.done);

      await usecase.call(messageId: messageId);

      expect(
        () => verify(
          () => agentService.call(
            conversationId: conversationId,
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.toolResume,
            ),
          ),
        ).called(1),
        returnsNormally,
      );
    });

    test('fetches message by correct messageId', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => null,
      );

      await usecase.call(messageId: messageId);

      expect(
        () =>
            verify(() => messageRepository.getMessageById(messageId)).called(1),
        returnsNormally,
      );
    });

    test('fetches conversation using message conversationId', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(
        () => conversationRepository.getConversationById(conversationId),
      ).thenAnswer((_) async => null);

      await usecase.call(messageId: messageId);

      expect(
        () => verify(
          () => conversationRepository.getConversationById(conversationId),
        ).called(1),
        returnsNormally,
      );
    });

    test('passes correct workspaceId to runAllowedTools', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(
        () => conversationRepository.getConversationById(conversationId),
      ).thenAnswer((_) async => conversation);
      when(
        () => toolExecutionService.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
        ),
      ).thenAnswer((_) async => AgentIterationDecision.waitForToolApproval);

      await usecase.call(messageId: messageId);

      expect(
        () => verify(
          () => toolExecutionService.call(
            conversationId: conversationId,
            workspaceId: workspaceId,
          ),
        ).called(1),
        returnsNormally,
      );
    });
  });
}
