// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/continue_agent_result.dart';
import 'package:auravibes_app/features/chats/usecases/maybe_auto_compact_conversation_usecase.dart';
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
  MaybeAutoCompactConversationUsecase,
])
void main() {
  group('RunAgentIterationUsecase', () {
    var fixture = _RunAgentIterationUsecaseFixture();

    setUp(() {
      fixture = _RunAgentIterationUsecaseFixture();

      when(
        fixture.conversationRepository.getConversationById('conversation-1'),
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

      when(fixture.messageRepository.createMessage(any)).thenAnswer(
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
      fixture.container.dispose();
    });

    test('returns done when the agent response has no tool calls', () async {
      when(
        fixture.continueAgentUsecase.call(
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

      final result = await fixture.usecase.call(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
          ackMessageIds: ['user-1'],
        ),
      );

      expect(result, AgentIterationDecision.done);
      final _ = verifyNever(
        fixture.runAllowedToolsUsecase.call(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
        ),
      );
    });

    test('forwards the iteration context to every continuation call', () async {
      when(
        fixture.continueAgentUsecase.call(
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

      final _ = await fixture.usecase.call(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
          ackMessageIds: ['user-1'],
        ),
      );

      expect(
        () => verify(
          fixture.continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1'],
            ),
          ),
        ).called(1),
        returnsNormally,
      );
    });

    test(
      'continues with drafts queued during a tool-free continuation',
      () async {
        var callCount = 0;
        when(
          fixture.continueAgentUsecase.call(
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
            final _ = fixture.container
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

        final result = await fixture.usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        expect(callCount, 2);
        verify(fixture.messageRepository.createMessage(any)).called(1);
        expect(
          fixture.container
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
          fixture.continueAgentUsecase.call(
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
          fixture.runAllowedToolsUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

        final result = await fixture.usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        verify(
          fixture.continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: anyNamed('context'),
          ),
        ).called(2);
        verify(
          fixture.runAllowedToolsUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).called(1);
      },
    );

    test('waits and retries when the model hits a rate limit', () async {
      var callCount = 0;
      when(
        fixture.continueAgentUsecase.call(
          conversationId: 'conversation-1',
          context: anyNamed('context'),
        ),
      ).thenAnswer((_) async {
        callCount += 1;
        if (callCount == 1) {
          throw Exception('RateLimitException(429): RESOURCE_EXHAUSTED');
        }

        return const ContinueAgentResult(
          messageId: 'assistant-2',
          hasToolCalls: false,
        );
      });

      final result = await fixture.usecase.call(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
          ackMessageIds: ['user-1'],
        ),
      );

      expect(result, AgentIterationDecision.done);
      expect(callCount, 2);
      expect(fixture.rateLimitRetryRuntime.retryAt('conversation-1'), isNull);
      verify(
        fixture.continueAgentUsecase.call(
          conversationId: 'conversation-1',
          context: anyNamed('context'),
        ),
      ).called(2);
      final _ = verifyNever(
        fixture.runAllowedToolsUsecase.call(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
        ),
      );
    });

    test('uses known retry delay from rate-limit errors', () async {
      final startTime = DateTime(2026);
      var currentTime = startTime;
      final delays = <Duration>[];
      fixture.usecase = RunAgentIterationUsecase(
        continueAgentUsecase: fixture.continueAgentUsecase,
        runAllowedToolsUsecase: fixture.runAllowedToolsUsecase,
        maybeAutoCompactConversationUsecase:
            fixture.maybeAutoCompactConversationUsecase,
        conversationRepository: fixture.conversationRepository,
        messageRepository: fixture.messageRepository,
        sendQueueRuntime: fixture.container.read(
          conversationSendQueueRuntimeProvider,
        ),
        agentCancellationRuntime: fixture.agentCancellationRuntime,
        rateLimitRetryRuntime: fixture.rateLimitRetryRuntime,
        now: () => currentTime,
        sleep: (delay) {
          delays.add(delay);
          expect(
            fixture.rateLimitRetryRuntime.retryAt('conversation-1'),
            startTime.add(const Duration(seconds: 3)),
          );
          currentTime = currentTime.add(delay);

          return Future<void>.value();
        },
      );

      var callCount = 0;
      when(
        fixture.continueAgentUsecase.call(
          conversationId: 'conversation-1',
          context: anyNamed('context'),
        ),
      ).thenAnswer((_) async {
        callCount += 1;
        if (callCount == 1) {
          throw Exception(
            'RateLimitException(429): try again in 3 seconds',
          );
        }

        return const ContinueAgentResult(
          messageId: 'assistant-2',
          hasToolCalls: false,
        );
      });

      final result = await fixture.usecase.call(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
          ackMessageIds: ['user-1'],
        ),
      );

      expect(result, AgentIterationDecision.done);
      expect(callCount, 2);
      expect(delays, [
        const Duration(seconds: 1),
        const Duration(seconds: 1),
        const Duration(seconds: 1),
      ]);
      expect(fixture.rateLimitRetryRuntime.retryAt('conversation-1'), isNull);
    });

    test(
      'stops before the next loop iteration and clears queued drafts',
      () async {
        var callCount = 0;
        when(
          fixture.continueAgentUsecase.call(
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
          fixture.runAllowedToolsUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer((_) async {
          final _ = fixture.container
              .read(conversationSendQueueProvider.notifier)
              .enqueue(
                conversationId: 'conversation-1',
                content: 'Queued follow-up',
              );
          fixture.agentCancellationRuntime.requestStop('conversation-1');

          return AgentIterationDecision.continueIteration;
        });

        final result = await fixture.usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        expect(callCount, 1);
        expect(
          fixture.container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
        verify(
          fixture.continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: anyNamed('context'),
          ),
        ).called(1);
      },
    );

    test(
      'marks queued drafts sent when stopped after dequeue',
      () async {
        final _ = fixture.container
            .read(conversationSendQueueProvider.notifier)
            .enqueue(
              conversationId: 'conversation-1',
              content: 'Queued follow-up',
            );
        when(
          fixture.messageRepository.createMessage(any),
        ).thenAnswer((_) async {
          fixture.agentCancellationRuntime.requestStop('conversation-1');

          return MessageEntity(
            id: 'queued-user-1',
            conversationId: 'conversation-1',
            content: 'Queued follow-up',
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sending,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          );
        });
        when(fixture.messageRepository.patchMessage(any, any)).thenAnswer(
          (_) async => MessageEntity(
            id: 'queued-user-1',
            conversationId: 'conversation-1',
            content: 'Queued follow-up',
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sent,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
        );

        final result = await fixture.usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        final _ = verifyNever(
          fixture.continueAgentUsecase.call(
            conversationId: anyNamed('conversationId'),
            context: anyNamed('context'),
          ),
        );
        final capturedPatches = verify(
          fixture.messageRepository.patchMessage(captureAny, captureAny),
        ).captured;
        expect(capturedPatches.whereType<String>(), [
          'user-1',
          'queued-user-1',
        ]);
        expect(
          capturedPatches.whereType<MessagePatch>().map(
            (patch) => patch.status,
          ),
          everyElement(MessageStatus.sent),
        );
      },
    );

    test(
      'returns the tool decision when execution must pause for approval',
      () async {
        when(
          fixture.continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1'],
            ),
          ),
        ).thenAnswer(
          (_) async => const ContinueAgentResult(
            messageId: 'assistant-1',
            hasToolCalls: true,
          ),
        );
        when(
          fixture.runAllowedToolsUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer((_) async => AgentIterationDecision.waitForToolApproval);

        final result = await fixture.usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
      },
    );

    test(
      'includes queued drafts in the same iteration context',
      () async {
        final _ = fixture.container
            .read(conversationSendQueueProvider.notifier)
            .enqueue(
              conversationId: 'conversation-1',
              content: 'Queued follow-up',
            );

        when(
          fixture.continueAgentUsecase.call(
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

        final result = await fixture.usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        verify(fixture.messageRepository.createMessage(any)).called(1);
        verify(
          fixture.continueAgentUsecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1', 'queued-user-1'],
            ),
          ),
        ).called(1);
        expect(
          fixture.container
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
          fixture.continueAgentUsecase.call(
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
          fixture.runAllowedToolsUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer((_) async {
          final _ = fixture.container
              .read(conversationSendQueueProvider.notifier)
              .enqueue(
                conversationId: 'conversation-1',
                content: 'Queued follow-up',
              );

          return AgentIterationDecision.continueIteration;
        });

        final result = await fixture.usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        verify(fixture.messageRepository.createMessage(any)).called(1);
        expect(callCount, 2);
        expect(
          fixture.container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
      },
    );

    test(
      'drains multiple queued drafts in one iteration before returning done',
      () async {
        final _ = fixture.container
            .read(conversationSendQueueProvider.notifier)
            .enqueue(
              conversationId: 'conversation-1',
              content: 'Queued follow-up 1',
            );
        final _ = fixture.container
            .read(conversationSendQueueProvider.notifier)
            .enqueue(
              conversationId: 'conversation-1',
              content: 'Queued follow-up 2',
            );

        var callCount = 0;
        when(
          fixture.continueAgentUsecase.call(
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
        when(
          fixture.messageRepository.createMessage(any),
        ).thenAnswer((_) async {
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

        final result = await fixture.usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        expect(result, AgentIterationDecision.done);
        expect(callCount, 1);
        verify(fixture.messageRepository.createMessage(any)).called(2);
        expect(
          fixture.container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
      },
    );

    group('compaction integration', () {
      test(
        'triggers auto compaction before the first AI call',
        () async {
          when(
            fixture.continueAgentUsecase.call(
              conversationId: 'conversation-1',
              context: anyNamed('context'),
            ),
          ).thenAnswer(
            (_) async => const ContinueAgentResult(
              messageId: 'assistant-1',
              hasToolCalls: false,
            ),
          );

          final _ = await fixture.usecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1'],
            ),
          );

          expect(
            () => verifyInOrder([
              fixture.maybeAutoCompactConversationUsecase.call(
                conversationId: 'conversation-1',
              ),
              fixture.continueAgentUsecase.call(
                conversationId: 'conversation-1',
                context: anyNamed('context'),
              ),
            ]),
            returnsNormally,
          );
        },
      );

      test(
        'triggers auto compaction in every loop iteration before the AI call',
        () async {
          var callCount = 0;
          when(
            fixture.continueAgentUsecase.call(
              conversationId: 'conversation-1',
              context: anyNamed('context'),
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
            fixture.runAllowedToolsUsecase.call(
              conversationId: 'conversation-1',
              workspaceId: 'workspace-1',
            ),
          ).thenAnswer(
            (_) async => AgentIterationDecision.continueIteration,
          );

          final _ = await fixture.usecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1'],
            ),
          );

          expect(
            () => verify(
              fixture.maybeAutoCompactConversationUsecase.call(
                conversationId: 'conversation-1',
              ),
            ).called(2),
            returnsNormally,
          );
        },
      );

      test(
        'propagates compaction failure to stop agent loop',
        () async {
          when(
            fixture.maybeAutoCompactConversationUsecase.call(
              conversationId: 'conversation-1',
            ),
          ).thenThrow(Exception('compaction error'));

          await expectLater(
            fixture.usecase.call(
              conversationId: 'conversation-1',
              context: const AgentIterationContext(
                origin: AgentIterationOrigin.userMessage,
                ackMessageIds: ['user-1'],
              ),
            ),
            throwsA(isA<Exception>()),
          );
          expect(
            () => verifyNever(
              fixture.continueAgentUsecase.call(
                conversationId: anyNamed('conversationId'),
                context: anyNamed('context'),
              ),
            ),
            returnsNormally,
          );
        },
      );

      test(
        'runs compaction after queued drafts drain but before AI call',
        () async {
          final _ = fixture.container
              .read(conversationSendQueueProvider.notifier)
              .enqueue(
                conversationId: 'conversation-1',
                content: 'Queued follow-up',
              );

          when(
            fixture.continueAgentUsecase.call(
              conversationId: 'conversation-1',
              context: anyNamed('context'),
            ),
          ).thenAnswer(
            (_) async => const ContinueAgentResult(
              messageId: 'assistant-1',
              hasToolCalls: false,
            ),
          );

          final _ = await fixture.usecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1'],
            ),
          );

          expect(
            () => verifyInOrder([
              fixture.messageRepository.createMessage(any),
              fixture.maybeAutoCompactConversationUsecase.call(
                conversationId: 'conversation-1',
              ),
              fixture.continueAgentUsecase.call(
                conversationId: 'conversation-1',
                context: anyNamed('context'),
              ),
            ]),
            returnsNormally,
          );
        },
      );

      test(
        'skips compaction and AI call when cancelled after drain',
        () async {
          final _ = fixture.container
              .read(conversationSendQueueProvider.notifier)
              .enqueue(
                conversationId: 'conversation-1',
                content: 'Queued follow-up',
              );
          when(
            fixture.messageRepository.createMessage(any),
          ).thenAnswer((_) async {
            fixture.agentCancellationRuntime.requestStop('conversation-1');

            return MessageEntity(
              id: 'queued-user-1',
              conversationId: 'conversation-1',
              content: 'Queued follow-up',
              messageType: MessageType.text,
              isUser: true,
              status: MessageStatus.sending,
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
            );
          });
          when(fixture.messageRepository.patchMessage(any, any)).thenAnswer(
            (_) async => MessageEntity(
              id: 'queued-user-1',
              conversationId: 'conversation-1',
              content: 'Queued follow-up',
              messageType: MessageType.text,
              isUser: true,
              status: MessageStatus.sent,
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
            ),
          );

          final _ = await fixture.usecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1'],
            ),
          );

          final _ = verifyNever(
            fixture.maybeAutoCompactConversationUsecase.call(
              conversationId: 'conversation-1',
            ),
          );
          final _ = verifyNever(
            fixture.continueAgentUsecase.call(
              conversationId: 'conversation-1',
              context: anyNamed('context'),
            ),
          );
          final capturedPatches = verify(
            fixture.messageRepository.patchMessage(captureAny, captureAny),
          ).captured;
          expect(capturedPatches.whereType<String>(), [
            'user-1',
            'queued-user-1',
          ]);
          expect(
            capturedPatches.whereType<MessagePatch>().map(
              (patch) => patch.status,
            ),
            everyElement(MessageStatus.sent),
          );
        },
      );
    });

    test('provider returns usecase with maybeAutoCompact wired', () {
      final container = ProviderContainer(
        overrides: [
          maybeAutoCompactConversationUsecaseProvider.overrideWith(
            (ref) => MockMaybeAutoCompactConversationUsecase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final usecase = container.read(runAgentIterationUsecaseProvider);

      expect(usecase, isA<RunAgentIterationUsecase>());
    });
  });
}

class _RunAgentIterationUsecaseFixture {
  factory _RunAgentIterationUsecaseFixture() {
    final continueAgentUsecase = MockContinueAgentUsecase();
    final runAllowedToolsUsecase = MockRunAllowedToolsUsecase();
    final conversationRepository = MockConversationRepository();
    final messageRepository = MockMessageRepository();
    final maybeAutoCompactConversationUsecase =
        MockMaybeAutoCompactConversationUsecase();
    final container = ProviderContainer();
    final agentCancellationRuntime = AgentCancellationRuntime();
    final rateLimitRetryRuntime = container.read(
      conversationRateLimitRetryRuntimeProvider,
    );

    return _RunAgentIterationUsecaseFixture._(
      continueAgentUsecase: continueAgentUsecase,
      runAllowedToolsUsecase: runAllowedToolsUsecase,
      conversationRepository: conversationRepository,
      messageRepository: messageRepository,
      maybeAutoCompactConversationUsecase: maybeAutoCompactConversationUsecase,
      container: container,
      agentCancellationRuntime: agentCancellationRuntime,
      rateLimitRetryRuntime: rateLimitRetryRuntime,
      usecase: RunAgentIterationUsecase(
        continueAgentUsecase: continueAgentUsecase,
        runAllowedToolsUsecase: runAllowedToolsUsecase,
        maybeAutoCompactConversationUsecase:
            maybeAutoCompactConversationUsecase,
        conversationRepository: conversationRepository,
        messageRepository: messageRepository,
        sendQueueRuntime: container.read(conversationSendQueueRuntimeProvider),
        agentCancellationRuntime: agentCancellationRuntime,
        rateLimitRetryRuntime: rateLimitRetryRuntime,
        rateLimitRetryDelay: Duration.zero,
      ),
    );
  }

  _RunAgentIterationUsecaseFixture._({
    required this.continueAgentUsecase,
    required this.runAllowedToolsUsecase,
    required this.conversationRepository,
    required this.messageRepository,
    required this.maybeAutoCompactConversationUsecase,
    required this.container,
    required this.agentCancellationRuntime,
    required this.rateLimitRetryRuntime,
    required this.usecase,
  });

  final MockContinueAgentUsecase continueAgentUsecase;
  final MockRunAllowedToolsUsecase runAllowedToolsUsecase;
  final MockConversationRepository conversationRepository;
  final MockMessageRepository messageRepository;
  final MockMaybeAutoCompactConversationUsecase
  maybeAutoCompactConversationUsecase;
  final ProviderContainer container;
  final AgentCancellationRuntime agentCancellationRuntime;
  final ConversationRateLimitRetryRuntime rateLimitRetryRuntime;
  RunAgentIterationUsecase usecase;

  void dispose() {
    container.dispose();
  }
}
