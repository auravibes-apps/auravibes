import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/continue_agent_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'run_agent_iteration_usecase_test.mocks.dart';

@GenerateMocks([
  ContinueAgentUsecase,
  RunAllowedToolsUsecase,
  ConversationRepository,
])
void main() {
  group('RunAgentIterationUsecase', () {
    late MockContinueAgentUsecase continueAgentUsecase;
    late MockRunAllowedToolsUsecase runAllowedToolsUsecase;
    late MockConversationRepository conversationRepository;
    late RunAgentIterationUsecase usecase;

    setUp(() {
      continueAgentUsecase = MockContinueAgentUsecase();
      runAllowedToolsUsecase = MockRunAllowedToolsUsecase();
      conversationRepository = MockConversationRepository();
      usecase = RunAgentIterationUsecase(
        continueAgentUsecase: continueAgentUsecase,
        runAllowedToolsUsecase: runAllowedToolsUsecase,
        conversationRepository: conversationRepository,
      );

      when(
        conversationRepository.getConversationById('conversation-1'),
      ).thenAnswer(
        (_) async => ConversationEntity(
          id: 'conversation-1',
          title: 'Conversation 1',
          workspaceId: 'workspace-1',
          isPinned: false,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      );
    });

    test('returns done when the agent response has no tool calls', () async {
      when(
        continueAgentUsecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageId: 'user-1',
          ),
        ),
      ).thenAnswer(
        (_) async => const ContinueAgentResult(
          messageId: 'assistant-1',
          hasToolCalls: false,
        ),
      );

      final result = await usecase.call(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
          ackMessageId: 'user-1',
        ),
      );

      expect(result, AgentIterationDecision.done);
      verifyNever(
        runAllowedToolsUsecase.call(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
        ),
      );
    });

    test('forwards the iteration context to every continuation call', () async {
      when(
        continueAgentUsecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageId: 'user-1',
          ),
        ),
      ).thenAnswer(
        (_) async => const ContinueAgentResult(
          messageId: 'assistant-1',
          hasToolCalls: false,
        ),
      );

      await usecase.call(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
          ackMessageId: 'user-1',
        ),
      );

      verify(
        continueAgentUsecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageId: 'user-1',
          ),
        ),
      ).called(1);
    });

    test(
      'continues looping while tool execution requests another iteration',
      () async {
        var callCount = 0;
        when(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer((_) async {
          callCount += 1;

          if (callCount == 1) {
            return const ContinueAgentResult(
              messageId: 'assistant-1',
              hasToolCalls: true,
            );
          }

          return const ContinueAgentResult(
            messageId: 'assistant-2',
            hasToolCalls: false,
          );
        });
        when(
          runAllowedToolsUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result, AgentIterationDecision.done);
        verify(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).called(2);
        verify(
          runAllowedToolsUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).called(1);
      },
    );

    test(
      'returns the tool decision when execution must pause for approval',
      () async {
        when(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => const ContinueAgentResult(
            messageId: 'assistant-1',
            hasToolCalls: true,
          ),
        );
        when(
          runAllowedToolsUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer((_) async => AgentIterationDecision.waitForToolApproval);

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result, AgentIterationDecision.waitForToolApproval);
      },
    );
  });
}
