import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_resume_service.dart';

import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AgentIterationContext, AgentIterationDecision;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:riverpod/riverpod.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('AgentToolResumeService', () {
    var messageRepository = MockMessageRepository();
    var conversationRepository = MockConversationRepository();
    var toolExecutionService = MockAgentToolExecutionService();
    var agentLoop = MockAgentLoopRunner();
    var usecase = AgentToolResumeService(
      messageRepository: messageRepository,
      conversationRepository: conversationRepository,
      toolExecutionService: toolExecutionService,
      agentLoop: agentLoop,
    );

    const messageId = 'message-1';
    const conversationId = 'conversation-1';
    const workspaceId = 'workspace-1';

    final message = MessageEntity(
      id: messageId,
      conversationId: conversationId,
      content: 'assistant',
      messageType: .text,
      isUser: false,
      status: .sent,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );

    final conversation = ConversationEntity(
      id: conversationId,
      title: 'Test',
      workspaceId: workspaceId,
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );

    setUp(() {
      messageRepository = MockMessageRepository();
      conversationRepository = MockConversationRepository();
      toolExecutionService = MockAgentToolExecutionService();
      agentLoop = MockAgentLoopRunner();

      usecase = AgentToolResumeService(
        messageRepository: messageRepository,
        conversationRepository: conversationRepository,
        toolExecutionService: toolExecutionService,
        agentLoop: agentLoop,
      );
    });

    test('returns early when message not found', () async {
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => null);

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
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => message);
      when(() => conversationRepository.getConversationById(conversationId))
          .thenAnswer((_) async => null);

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
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => message);
      when(() => conversationRepository.getConversationById(conversationId))
          .thenAnswer((_) async => conversation);
      when(
        () => toolExecutionService.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ),
      ).thenAnswer((_) async => AgentIterationDecision.waitForToolApproval);

      await expectLater(usecase.call(messageId: messageId), completes);

      expect(
        () => verifyNever(
          () => agentLoop.call(
            conversationId: any(named: 'conversationId'),
            context: any(named: 'context'),
          ),
        ),
        returnsNormally,
      );
    });

    test(
      'resumes an awaiting child as running before shared agent loop',
      () async {
        when(() => messageRepository.getMessageById(messageId))
            .thenAnswer((_) async => message);
        when(() => conversationRepository.getConversationById(conversationId))
            .thenAnswer((_) async => conversation);
        when(
          () => toolExecutionService.call(
            conversationId: conversationId,
            workspaceId: workspaceId,
          ),
        ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        final activeSubAgents = container.read(
          activeSubAgentRuntimeProvider.notifier,
        );
        activeSubAgents.start(parentId: 'parent-1', childId: conversationId);
        activeSubAgents.markAwaitingApproval(conversationId);
        usecase = AgentToolResumeService(
          messageRepository: messageRepository,
          conversationRepository: conversationRepository,
          toolExecutionService: toolExecutionService,
          agentLoop: agentLoop,
          activeSubAgents: activeSubAgents,
        );

        ActiveSubAgentStatus? statusAtContinuation;
        when(
          () => agentLoop.call(
            conversationId: conversationId,
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {
          statusAtContinuation = activeSubAgents.statusOf(conversationId);
          return AgentIterationDecision.done;
        });

        await usecase.call(messageId: messageId);

        expect(statusAtContinuation, ActiveSubAgentStatus.running);
        expect(
          activeSubAgents.statusOf(conversationId),
          ActiveSubAgentStatus.completed,
        );
        expect(
          () => verify(
            () => agentLoop.call(
              conversationId: conversationId,
              context: const AgentIterationContext(origin: .toolResume),
            ),
          ).called(1),
          returnsNormally,
        );
      },
    );

    test('continues an active conversation only once', () async {
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => message);
      when(() => conversationRepository.getConversationById(conversationId))
          .thenAnswer((_) async => conversation);
      when(
        () => toolExecutionService.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ),
      ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

      final loopStarted = Completer<void>();
      final loopFinished = Completer<AgentIterationDecision>();
      when(
        () => agentLoop.call(
          conversationId: conversationId,
          context: const AgentIterationContext(origin: .toolResume),
        ),
      ).thenAnswer((_) {
        if (!loopStarted.isCompleted) loopStarted.complete();

        return loopFinished.future;
      });

      final first = usecase.call(messageId: messageId);
      final second = usecase.call(messageId: messageId);
      await loopStarted.future;

      expect(
        () => verify(
          () => agentLoop.call(
            conversationId: conversationId,
            context: const AgentIterationContext(origin: .toolResume),
          ),
        ).called(1),
        returnsNormally,
      );

      loopFinished.complete(AgentIterationDecision.done);
      final _ = await Future.wait([first, second]);
    });

    test('fetches message by correct messageId', () async {
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => null);

      await usecase.call(messageId: messageId);

      expect(
        () =>
            verify(() => messageRepository.getMessageById(messageId)).called(1),
        returnsNormally,
      );
    });

    test('fetches conversation using message conversationId', () async {
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => message);
      when(() => conversationRepository.getConversationById(conversationId))
          .thenAnswer((_) async => null);

      await usecase.call(messageId: messageId);

      expect(
        () => verify(
          () => conversationRepository.getConversationById(conversationId),
        ).called(1),
        returnsNormally,
      );
    });

    test('passes correct workspaceId to runAllowedTools', () async {
      when(() => messageRepository.getMessageById(messageId))
          .thenAnswer((_) async => message);
      when(() => conversationRepository.getConversationById(conversationId))
          .thenAnswer((_) async => conversation);
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
