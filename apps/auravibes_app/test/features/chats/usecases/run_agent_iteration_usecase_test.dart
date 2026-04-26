import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/send_queue_runtime_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/continue_agent_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'run_agent_iteration_usecase_test.mocks.dart';

@GenerateMocks([
  ContinueAgentUsecase,
  RunAllowedToolsUsecase,
  ConversationRepository,
  MessageRepository,
])
void main() {
  group('RunAgentIterationUsecase', () {
    late MockContinueAgentUsecase continueAgentUsecase;
    late MockRunAllowedToolsUsecase runAllowedToolsUsecase;
    late MockConversationRepository conversationRepository;
    late MockMessageRepository messageRepository;
    late ProviderContainer container;
    late AgentCancellationRuntime agentCancellationRuntime;
    late RunAgentIterationUsecase usecase;

    setUp(() {
      continueAgentUsecase = MockContinueAgentUsecase();
      runAllowedToolsUsecase = MockRunAllowedToolsUsecase();
      conversationRepository = MockConversationRepository();
      messageRepository = MockMessageRepository();
      container = ProviderContainer();
      agentCancellationRuntime = AgentCancellationRuntime();
      usecase = RunAgentIterationUsecase(
        continueAgentUsecase: continueAgentUsecase,
        runAllowedToolsUsecase: runAllowedToolsUsecase,
        conversationRepository: conversationRepository,
        messageRepository: messageRepository,
        sendQueueRuntime: container.read(conversationSendQueueRuntimeProvider),
        agentCancellationRuntime: agentCancellationRuntime,
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

      when(messageRepository.createMessage(any)).thenAnswer(
        (_) async => MessageEntity(
          id: 'queued-user-1',
          conversationId: 'conversation-1',
          content: 'Queued follow-up',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('returns done when the agent response has no tool calls', () async {
      when(
        continueAgentUsecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
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
          ackMessageIds: ['user-1'],
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
            ackMessageIds: ['user-1'],
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
          ackMessageIds: ['user-1'],
        ),
      );

      verify(
        continueAgentUsecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        ),
      ).called(1);
    });

    test(
      'continues with drafts queued during a tool-free continuation',
      () async {
        var callCount = 0;
        when(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: anyNamed('context'),
          ),
        ).thenAnswer((invocation) async {
          final context =
              invocation.namedArguments[#context] as AgentIterationContext?;
          callCount += 1;

          if (callCount == 1) {
            expect(
              context,
              const AgentIterationContext(
                origin: .userMessage,
                ackMessageIds: ['user-1'],
              ),
            );
            container
                .read(conversationSendQueueProvider.notifier)
                .enqueue(
                  conversationId: 'conversation-1',
                  content: 'Queued during stream',
                );

            return const ContinueAgentResult(
              messageId: 'assistant-1',
              hasToolCalls: false,
            );
          }

          expect(
            context,
            const AgentIterationContext(
              origin: .userMessage,
              ackMessageIds: ['queued-user-1'],
            ),
          );

          return const ContinueAgentResult(
            messageId: 'assistant-2',
            hasToolCalls: false,
          );
        });

        final result = await usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        expect(callCount, 2);
        verify(messageRepository.createMessage(any)).called(1);
        expect(
          container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
      },
    );

    test(
      'continues looping while tool execution requests another iteration',
      () async {
        var callCount = 0;
        when(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: anyNamed('context'),
          ),
        ).thenAnswer((invocation) async {
          final context =
              invocation.namedArguments[#context] as AgentIterationContext?;
          callCount += 1;

          if (callCount == 2) {
            expect(
              context,
              const AgentIterationContext(
                origin: .userMessage,
                ackMessageIds:
                    [], // ignore: avoid_redundant_argument_values - Explicit empty ack expectation for review clarity.
              ),
            );
          }

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
            context: anyNamed('context'),
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
      'stops before the next loop iteration and clears queued drafts',
      () async {
        var callCount = 0;
        when(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: anyNamed('context'),
          ),
        ).thenAnswer((_) async {
          callCount += 1;
          return ContinueAgentResult(
            messageId: 'assistant-$callCount',
            hasToolCalls: true,
          );
        });
        when(
          runAllowedToolsUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer((_) async {
          container
              .read(conversationSendQueueProvider.notifier)
              .enqueue(
                conversationId: 'conversation-1',
                content: 'Queued follow-up',
              );
          agentCancellationRuntime.requestStop('conversation-1');
          return AgentIterationDecision.continueIteration;
        });

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result, AgentIterationDecision.done);
        expect(callCount, 1);
        expect(
          container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
        verify(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: anyNamed('context'),
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

    test(
      'includes queued drafts in the same iteration context',
      () async {
        container
            .read(conversationSendQueueProvider.notifier)
            .enqueue(
              conversationId: 'conversation-1',
              content: 'Queued follow-up',
            );

        when(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1', 'queued-user-1'],
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
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        verify(messageRepository.createMessage(any)).called(1);
        verify(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1', 'queued-user-1'],
            ),
          ),
        ).called(1);
        expect(
          container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
      },
    );

    test(
      'adds queued drafts before the next continuation after tool execution',
      () async {
        var callCount = 0;
        when(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: anyNamed('context'),
          ),
        ).thenAnswer((invocation) async {
          final ctx =
              invocation.namedArguments[#context] as AgentIterationContext?;
          callCount += 1;

          if (callCount == 1) {
            return const ContinueAgentResult(
              messageId: 'assistant-1',
              hasToolCalls: true,
            );
          }
          if (callCount == 2) {
            expect(
              ctx?.ackMessageIds,
              ['queued-user-1'],
              reason: 'queued draft should be acked before the next iteration',
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
        ).thenAnswer((_) async {
          container
              .read(conversationSendQueueProvider.notifier)
              .enqueue(
                conversationId: 'conversation-1',
                content: 'Queued follow-up',
              );
          return AgentIterationDecision.continueIteration;
        });

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result, AgentIterationDecision.done);
        verify(messageRepository.createMessage(any)).called(1);
        expect(callCount, 2);
        expect(
          container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
      },
    );

    test(
      'drains multiple queued drafts in one iteration before returning done',
      () async {
        container
            .read(conversationSendQueueProvider.notifier)
            .enqueue(
              conversationId: 'conversation-1',
              content: 'Queued follow-up 1',
            );
        container
            .read(conversationSendQueueProvider.notifier)
            .enqueue(
              conversationId: 'conversation-1',
              content: 'Queued follow-up 2',
            );

        var callCount = 0;
        when(
          continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: anyNamed('context'),
          ),
        ).thenAnswer((invocation) async {
          final context =
              invocation.namedArguments[#context] as AgentIterationContext?;
          callCount += 1;

          if (callCount == 1) {
            expect(context?.ackMessageIds, [
              'user-1',
              'queued-user-1',
              'queued-user-2',
            ]);
          }

          return ContinueAgentResult(
            messageId: 'assistant-$callCount',
            hasToolCalls: false,
          );
        });

        var createdCount = 0;
        when(messageRepository.createMessage(any)).thenAnswer((_) async {
          createdCount += 1;
          return MessageEntity(
            id: 'queued-user-$createdCount',
            conversationId: 'conversation-1',
            content: 'Queued follow-up $createdCount',
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sending,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          );
        });

        final result = await usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        expect(callCount, 1);
        verify(messageRepository.createMessage(any)).called(2);
        expect(
          container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
      },
    );
  });
}
