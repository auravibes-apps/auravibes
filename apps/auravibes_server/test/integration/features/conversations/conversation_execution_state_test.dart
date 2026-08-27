import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_engine_host.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_job_dispatcher.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_job_leases.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_worker.dart';
import 'package:auravibes_server/src/features/conversations/usecases/conversation_usecases.dart';
import 'package:auravibes_server/src/features/conversations/repositories/conversation_repository.dart'
    as conversation_repo;
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'ConversationExecutionState',
    (sessionBuilder, endpoints) {
      Future<_ExecutionFixture> prepareExecution({
        bool continueConversation = true,
      }) async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final database = session.build();
        await AuthUser.db.insertRow(
          database,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          database,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.com',
            passwordHash: 'unused',
          ),
        );
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              database,
              name: 'Workspace',
              ownerUserId: userId,
              now: DateTime.now().toUtc(),
            );
        final now = DateTime.now().toUtc();
        final conversation = await Conversation.db.insertRow(
          database,
          Conversation(
            workspaceId: workspace.id!,
            stableId: 'conversation-1',
            title: 'Conversation',
            isPinned: false,
            revision: 1,
            projectionRevision: 1,
            eventSequence: 0,
            executionState: 'idle',
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (continueConversation) {
          await endpoints.conversation.queueConversationMessage(
            session,
            QueueConversationMessageRequest(
              workspaceId: workspace.id!,
              requestId: 'queue-1',
              conversationId: conversation.stableId,
              expectedProjectionRevision: 1,
              clientMessageId: 'message-1',
              content: 'First',
              attachmentIds: const [],
            ),
          );
          final snapshot = await endpoints.conversation.continueConversation(
            session,
            ContinueConversationRequest(
              workspaceId: workspace.id!,
              requestId: 'continue-1',
              conversationId: conversation.stableId,
              expectedProjectionRevision: 2,
            ),
          );
          expect(snapshot.conversation.executionState, 'running');
          expect(snapshot.activeExecution!.claimedMessageIds, ['message-1']);
          expect(snapshot.pendingMessages, isEmpty);
          await ProviderAdmissionLock.db.deleteWhere(
            database,
            where: (table) => table.key.equals('global'),
          );
        }
        return _ExecutionFixture(
          session: session,
          database: database,
          userId: userId,
          workspaceId: workspace.id!,
          conversationDatabaseId: conversation.id!,
          conversationId: conversation.stableId,
        );
      }

      ConversationJobDispatcher dispatcherFor(
        _ExecutionFixture fixture,
        _CountingCompletingHost host,
        Completer<void> drained,
      ) => ConversationJobDispatcher(
        drain: (isActive) async {
          await runConversationWorker(
            fixture.database,
            isActive: isActive,
            worker: ConversationWorker(host: host),
          );
          if (!drained.isCompleted) drained.complete();
        },
        onError: (error, stackTrace) => fail('$error\n$stackTrace'),
        recoveryInterval: const Duration(milliseconds: 1),
      );

      Future<({ConversationTurn turn, List<String> toolCallIds})>
      stageAwaitingApproval(
        _ExecutionFixture fixture, {
        required int calls,
      }) async {
        final now = DateTime.now().toUtc();
        final conversation = (await Conversation.db.findById(
          fixture.database,
          fixture.conversationDatabaseId,
        ))!;
        final turn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        ))!;
        final assistant = (await ConversationMessage.db.findById(
          fixture.database,
          turn.assistantMessageId!,
        ))!;
        final execution = (await ConversationExecution.db.findById(
          fixture.database,
          conversation.activeExecutionId!,
        ))!;
        final initialJob = (await ConversationJob.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.turnId.equals(turn.id),
        ))!;
        await ConversationJob.db.updateRow(
          fixture.database,
          initialJob.copyWith(status: 'completed', updatedAt: now),
        );
        await ConversationTurn.db.updateRow(
          fixture.database,
          turn.copyWith(
            status: ConversationStatuses.awaitingApproval,
            revision: 2,
            updatedAt: now,
          ),
        );
        await ConversationMessage.db.updateRow(
          fixture.database,
          assistant.copyWith(
            status: ConversationStatuses.awaitingApproval,
            updatedAt: now,
          ),
        );
        await ConversationExecution.db.updateRow(
          fixture.database,
          execution.copyWith(
            status: ConversationStatuses.awaitingApproval,
            updatedAt: now,
          ),
        );
        await Conversation.db.updateRow(
          fixture.database,
          conversation.copyWith(
            executionState: ConversationStatuses.awaitingApproval,
            updatedAt: now,
          ),
        );
        final toolCallIds = <String>[];
        for (var index = 0; index < calls; index++) {
          final stableId = 'tool-call-${index + 1}';
          toolCallIds.add(stableId);
          await ConversationToolCall.db.insertRow(
            fixture.database,
            ConversationToolCall(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationDatabaseId,
              turnId: turn.id!,
              messageId: assistant.id!,
              stableId: stableId,
              name: 'tool',
              argumentsJson: '{}',
              argumentsDigest: 'digest-${index + 1}',
              status: 'pending',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
        return (turn: turn, toolCallIds: toolCallIds);
      }

      ConversationUseCases decisionUseCases() => ConversationUseCases(
        conversation_repo.ConversationRepository(),
        publishConversationJob: (_, _) async {},
      );

      test(
        'Skip queues a continuation that replays the denied tool result',
        () async {
          final fixture = await prepareExecution();
          final staged = await stageAwaitingApproval(fixture, calls: 1);

          await decisionUseCases().submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: SubmitToolDecisionRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'skip-1',
              turnId: staged.turn.requestId,
              toolCallId: staged.toolCallIds.single,
              argumentsDigest: 'digest-1',
              expectedTurnRevision: 2,
              decision: 'deny',
            ),
          );

          final call = (await ConversationToolCall.db.findFirstRow(
            fixture.database,
            where: (table) => table.stableId.equals(staged.toolCallIds.single),
          ))!;
          final turn = (await ConversationTurn.db.findById(
            fixture.database,
            staged.turn.id!,
          ))!;
          final continuation = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) => table.requestId.equals('skip-1'),
          ))!;
          expect(call.status, 'denied');
          expect(turn.status, ConversationStatuses.queued);
          expect(continuation.status, ConversationJobStatuses.queued);
          expect(continuation.payloadJson, contains(fixture.userId));
        },
      );

      test(
        'recovery terminalizes only a stale running tool without reexecution',
        () async {
          final fixture = await prepareExecution();
          final staged = await stageAwaitingApproval(fixture, calls: 1);
          final existing = (await ConversationToolCall.db.findFirstRow(
            fixture.database,
            where: (table) => table.stableId.equals(staged.toolCallIds.single),
          ))!;
          await ConversationToolCall.db.updateRow(
            fixture.database,
            existing.copyWith(
              status: 'running',
              decision: 'approve',
              updatedAt: DateTime.now().toUtc().subtract(
                serverToolRunningRecoveryTimeout,
              ),
            ),
          );
          var executions = 0;
          final runtime = ServerToolRuntime(
            executor: (_, _, _, _) async {
              executions++;
              return {'unexpected': true};
            },
          );

          await runtime.handle(
            fixture.database,
            turn: staged.turn,
            messageId: existing.messageId,
            request: ServerToolRequest(
              id: existing.stableId,
              name: existing.name,
              arguments: const {},
            ),
          );

          final recovered = (await ConversationToolCall.db.findById(
            fixture.database,
            existing.id!,
          ))!;
          expect(executions, 0);
          expect(recovered.status, 'executionError');
          expect(recovered.resultJson, contains('interrupted'));
        },
      );

      test('active running tool remains owned and non-terminal', () async {
        final fixture = await prepareExecution();
        final staged = await stageAwaitingApproval(fixture, calls: 1);
        final existing = (await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals(staged.toolCallIds.single),
        ))!;
        await ConversationToolCall.db.updateRow(
          fixture.database,
          existing.copyWith(
            status: 'running',
            decision: 'approve',
            revision: 2,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        var executions = 0;

        await ServerToolRuntime(
          executor: (_, _, _, _) async {
            executions++;
            return {'unexpected': true};
          },
        ).handle(
          fixture.database,
          turn: staged.turn,
          messageId: existing.messageId,
          request: ServerToolRequest(
            id: existing.stableId,
            name: existing.name,
            arguments: const {},
          ),
        );

        final active = (await ConversationToolCall.db.findById(
          fixture.database,
          existing.id!,
        ))!;
        expect(executions, 0);
        expect(active.status, 'running');
        expect(active.revision, 2);
      });

      test(
        'removed approved tool resolves its existing durable call',
        () async {
          final fixture = await prepareExecution();
          final staged = await stageAwaitingApproval(fixture, calls: 1);
          final existing = (await ConversationToolCall.db.findFirstRow(
            fixture.database,
            where: (table) => table.stableId.equals(staged.toolCallIds.single),
          ))!;
          await ConversationToolCall.db.updateRow(
            fixture.database,
            existing.copyWith(
              status: 'approved',
              decision: 'approve',
              updatedAt: DateTime.now().toUtc(),
            ),
          );

          await ServerToolRuntime().handle(
            fixture.database,
            turn: staged.turn,
            messageId: existing.messageId,
            request: ServerToolRequest(
              id: existing.stableId,
              name: existing.name,
              arguments: const {},
            ),
          );

          final calls = await ConversationToolCall.db.find(
            fixture.database,
            where: (table) => table.stableId.equals(existing.stableId),
          );
          expect(calls, hasLength(1));
          expect(calls.single.status, 'toolNotFound');
          expect(calls.single.resultJson, contains('no longer available'));
        },
      );

      test('Skip leaves other pending approvals awaiting a decision', () async {
        final fixture = await prepareExecution();
        final staged = await stageAwaitingApproval(fixture, calls: 2);

        await decisionUseCases().submitToolDecision(
          fixture.database,
          userId: fixture.userId,
          request: SubmitToolDecisionRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'skip-one-of-two',
            turnId: staged.turn.requestId,
            toolCallId: staged.toolCallIds.first,
            argumentsDigest: 'digest-1',
            expectedTurnRevision: 2,
            decision: 'deny',
          ),
        );

        final calls = await ConversationToolCall.db.find(
          fixture.database,
          where: (table) => table.turnId.equals(staged.turn.id),
          orderBy: (table) => table.stableId,
        );
        final turn = (await ConversationTurn.db.findById(
          fixture.database,
          staged.turn.id!,
        ))!;
        final execution = (await ConversationExecution.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.conversationId.equals(fixture.conversationDatabaseId),
        ))!;
        final conversation = (await Conversation.db.findById(
          fixture.database,
          fixture.conversationDatabaseId,
        ))!;
        expect(calls.map((call) => call.status), ['denied', 'pending']);
        expect(turn.status, ConversationStatuses.awaitingApproval);
        expect(execution.status, ConversationStatuses.awaitingApproval);
        expect(
          conversation.executionState,
          ConversationStatuses.awaitingApproval,
        );
        expect(
          await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) => table.requestId.equals('skip-one-of-two'),
          ),
          isNull,
        );
      });

      test(
        'reports stale revision for a second pending decision from one snapshot',
        () async {
          final fixture = await prepareExecution();
          final staged = await stageAwaitingApproval(fixture, calls: 2);
          final useCases = decisionUseCases();

          await useCases.submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: SubmitToolDecisionRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'approve-first',
              turnId: staged.turn.requestId,
              toolCallId: staged.toolCallIds.first,
              argumentsDigest: 'digest-1',
              expectedTurnRevision: 2,
              decision: 'approve',
            ),
          );
          await expectLater(
            useCases.submitToolDecision(
              fixture.database,
              userId: fixture.userId,
              request: SubmitToolDecisionRequest(
                workspaceId: fixture.workspaceId,
                requestId: 'approve-second-stale',
                turnId: staged.turn.requestId,
                toolCallId: staged.toolCallIds.last,
                argumentsDigest: 'digest-2',
                expectedTurnRevision: 2,
                decision: 'approve',
              ),
            ),
            throwsA(
              isA<ConversationException>().having(
                (error) => error.code,
                'code',
                ConversationErrorCode.staleRevision,
              ),
            ),
          );

          final result = await useCases.submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: SubmitToolDecisionRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'approve-second-retry',
              turnId: staged.turn.requestId,
              toolCallId: staged.toolCallIds.last,
              argumentsDigest: 'digest-2',
              expectedTurnRevision: 3,
              decision: 'approve',
            ),
          );

          expect(result.status, ConversationStatuses.queued);
          final calls = await ConversationToolCall.db.find(
            fixture.database,
            where: (table) => table.turnId.equals(staged.turn.id),
            orderBy: (table) => table.stableId,
          );
          expect(calls.map((call) => call.status), ['approved', 'approved']);
        },
      );

      test(
        'tool decisions replay by request ID and reject a changed decision',
        () async {
          final fixture = await prepareExecution();
          final staged = await stageAwaitingApproval(fixture, calls: 1);
          final useCases = decisionUseCases();
          final request = SubmitToolDecisionRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'idempotent-decision',
            turnId: staged.turn.requestId,
            toolCallId: staged.toolCallIds.single,
            argumentsDigest: 'digest-1',
            expectedTurnRevision: 2,
            decision: 'approve',
          );

          final first = await useCases.submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: request,
          );
          final replay = await useCases.submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: request,
          );

          expect(replay.toJson(), first.toJson());
          expect(
            await ConversationEvent.db.find(
              fixture.database,
              where: (table) => table.requestId.equals(request.requestId),
            ),
            hasLength(1),
          );
          await expectLater(
            useCases.submitToolDecision(
              fixture.database,
              userId: fixture.userId,
              request: request.copyWith(decision: 'deny'),
            ),
            throwsA(
              isA<ConversationException>().having(
                (error) => error.code,
                'code',
                ConversationErrorCode.idempotencyConflict,
              ),
            ),
          );
        },
      );

      test(
        'Stop all denies remaining approvals and cancels the execution',
        () async {
          final fixture = await prepareExecution();
          final staged = await stageAwaitingApproval(fixture, calls: 2);

          await decisionUseCases().submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: SubmitToolDecisionRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'stop-all',
              turnId: staged.turn.requestId,
              toolCallId: staged.toolCallIds.first,
              argumentsDigest: 'digest-1',
              expectedTurnRevision: 2,
              decision: 'deny',
              stopAll: true,
            ),
          );

          final calls = await ConversationToolCall.db.find(
            fixture.database,
            where: (table) => table.turnId.equals(staged.turn.id),
          );
          final turn = (await ConversationTurn.db.findById(
            fixture.database,
            staged.turn.id!,
          ))!;
          final conversation = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationDatabaseId,
          ))!;
          final assistant = (await ConversationMessage.db.findById(
            fixture.database,
            staged.turn.assistantMessageId!,
          ))!;
          final execution = (await ConversationExecution.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.conversationId.equals(fixture.conversationDatabaseId),
          ))!;
          expect(
            calls
                .map(
                  (call) => call.status,
                )
                .toSet(),
            {'denied'},
          );
          expect(turn.status, ConversationStatuses.cancelled);
          expect(assistant.status, ConversationStatuses.cancelled);
          expect(assistant.metadataJson, '{"errorCode":"cancelled"}');
          expect(execution.status, ConversationStatuses.cancelled);
          expect(conversation.executionState, 'idle');
          expect(conversation.activeExecutionId, isNull);
        },
      );

      test(
        'Stop all applies after a prior Skip replay for the same call',
        () async {
          final fixture = await prepareExecution();
          final staged = await stageAwaitingApproval(fixture, calls: 2);

          await decisionUseCases().submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: SubmitToolDecisionRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'skip-a',
              turnId: staged.turn.requestId,
              toolCallId: staged.toolCallIds.first,
              argumentsDigest: 'digest-1',
              expectedTurnRevision: 2,
              decision: 'deny',
            ),
          );
          await decisionUseCases().submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: SubmitToolDecisionRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'stop-all-a',
              turnId: staged.turn.requestId,
              toolCallId: staged.toolCallIds.first,
              argumentsDigest: 'digest-1',
              // A replay carries the revision from the original prompt.
              expectedTurnRevision: 2,
              decision: 'deny',
              stopAll: true,
            ),
          );

          final calls = await ConversationToolCall.db.find(
            fixture.database,
            where: (table) => table.turnId.equals(staged.turn.id),
          );
          final turn = await ConversationTurn.db.findById(
            fixture.database,
            staged.turn.id!,
          );
          final execution = await ConversationExecution.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.conversationId.equals(fixture.conversationDatabaseId),
          );

          expect(calls.map((call) => call.status).toSet(), {'denied'});
          expect(turn!.status, ConversationStatuses.cancelled);
          expect(execution!.status, ConversationStatuses.cancelled);
        },
      );

      test(
        'promptless Continue creates one execution, assistant, turn, and job',
        () async {
          final fixture = await prepareExecution(continueConversation: false);
          final request = ContinueConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'promptless-continue-1',
            conversationId: fixture.conversationId,
            expectedProjectionRevision: 1,
          );

          final snapshot = await endpoints.conversation.continueConversation(
            fixture.session,
            request,
          );
          final execution = snapshot.activeExecution!;
          final turn = (await ConversationTurn.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.requestId.equals(execution.id),
          ))!;
          final job = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.requestId.equals(execution.id) &
                table.kind.equals(ConversationJobKinds.turn),
          ))!;

          expect(
            snapshot.conversation.executionState,
            ConversationStatuses.running,
          );
          expect(execution.claimedMessageIds, isEmpty);
          expect(snapshot.messages, hasLength(1));
          expect(snapshot.messages.single.role, 'assistant');
          expect(snapshot.messages.single.status, ConversationStatuses.running);
          expect(snapshot.pendingMessages, isEmpty);
          expect(turn.userMessageId, isNull);
          expect(turn.assistantMessageId, isNotNull);
          expect(job.status, ConversationJobStatuses.queued);
          expect(
            job.payloadJson,
            jsonEncode({
              'actorUserId': fixture.userId,
              'executionId': execution.id,
            }),
          );

          final replay = await endpoints.conversation.continueConversation(
            fixture.session,
            request,
          );
          final executions = await ConversationExecution.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId),
          );
          final jobs = await ConversationJob.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId) &
                table.kind.equals(ConversationJobKinds.turn),
          );

          expect(replay.activeExecution!.id, execution.id);
          expect(executions, hasLength(1));
          expect(jobs, hasLength(1));
        },
      );

      test('completing worker drains promptless Continue to idle', () async {
        final fixture = await prepareExecution(continueConversation: false);
        await endpoints.conversation.continueConversation(
          fixture.session,
          ContinueConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'promptless-continue-1',
            conversationId: fixture.conversationId,
            expectedProjectionRevision: 1,
          ),
        );
        final host = _CountingCompletingHost();

        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: host),
        );
        await _waitForIdle(fixture, endpoints);

        final turn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        ))!;
        expect(host.calls, 1);
        expect(turn.status, ConversationStatuses.completed);
      });

      test(
        'queued Continue retains claims while running and approval states reject',
        () async {
          final fixture = await prepareExecution(continueConversation: false);
          await endpoints.conversation.queueConversationMessage(
            fixture.session,
            QueueConversationMessageRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'queue-1',
              conversationId: fixture.conversationId,
              expectedProjectionRevision: 1,
              clientMessageId: 'message-1',
              content: 'First',
              attachmentIds: const [],
            ),
          );
          final snapshot = await endpoints.conversation.continueConversation(
            fixture.session,
            ContinueConversationRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'continue-1',
              conversationId: fixture.conversationId,
              expectedProjectionRevision: 2,
            ),
          );
          expect(snapshot.activeExecution!.claimedMessageIds, ['message-1']);

          Future<void> expectRejected(String requestId) => expectLater(
            endpoints.conversation.continueConversation(
              fixture.session,
              ContinueConversationRequest(
                workspaceId: fixture.workspaceId,
                requestId: requestId,
                conversationId: fixture.conversationId,
                expectedProjectionRevision: 3,
              ),
            ),
            throwsA(
              isA<ConversationException>().having(
                (error) => error.code,
                'code',
                ConversationErrorCode.turnConflict,
              ),
            ),
          );

          await expectRejected('continue-running');
          final conversation = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationDatabaseId,
          ))!;
          await Conversation.db.updateRow(
            fixture.database,
            conversation.copyWith(
              executionState: ConversationStatuses.awaitingApproval,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
          await expectRejected('continue-awaiting-approval');
        },
      );

      test('dispatcher startup recovery reaches durable idle', () async {
        final fixture = await prepareExecution();
        final host = _CountingCompletingHost();
        final drained = Completer<void>();
        final dispatcher = dispatcherFor(fixture, host, drained);
        dispatcher.start(
          wakeups: const Stream<void>.empty(),
          isActive: () => true,
        );

        await drained.future.timeout(const Duration(seconds: 2));
        await dispatcher.stop();
        await _waitForIdle(fixture, endpoints);

        expect(host.calls, 1);
      });

      test(
        'compact wakes a live dispatcher after its durable commit',
        () async {
          final fixture = await prepareExecution(continueConversation: false);
          final now = DateTime.now().toUtc();
          final source = await ConversationMessage.db.insertRow(
            fixture.database,
            ConversationMessage(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationDatabaseId,
              stableId: 'source-message',
              role: 'user',
              kind: 'text',
              status: 'sent',
              content: 'Source',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          final listenerReady = Completer<void>();
          final drained = Completer<void>();
          final wakes = StreamController<void>(
            sync: true,
            onListen: listenerReady.complete,
          );
          var active = false;
          final host = _CountingCompletingHost(compactionMessageId: source.id!);
          final dispatcher = ConversationJobDispatcher(
            drain: (isActive) async {
              await runConversationWorker(
                fixture.database,
                isActive: isActive,
                worker: ConversationWorker(host: host),
              );
              if (!drained.isCompleted) drained.complete();
            },
            onError: (error, stackTrace) => fail('$error\n$stackTrace'),
            recoveryInterval: const Duration(days: 1),
          );
          dispatcher.start(wakeups: wakes.stream, isActive: () => active);
          await listenerReady.future.timeout(const Duration(seconds: 2));
          active = true;
          final useCases = ConversationUseCases(
            conversation_repo.ConversationRepository(),
            publishConversationJob: (session, job) async {
              final persisted = await ConversationJob.db.findById(
                session,
                job.id!,
              );
              expect(persisted, isNotNull);
              wakes.add(null);
            },
          );

          await useCases.compact(
            fixture.database,
            userId: fixture.userId,
            request: CompactConversationRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'compact-1',
              conversationId: fixture.conversationId,
              expectedConversationRevision: 1,
            ),
          );

          await host.compactionStarted.future.timeout(
            const Duration(seconds: 2),
          );
          await drained.future.timeout(const Duration(seconds: 2));
          await dispatcher.stop();

          final job = await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.requestId.equals('compact-1'),
          );
          final summary = await ConversationMessage.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.stableId.equals('compact-1:compaction-summary'),
          );

          expect(host.compactionCalls, 1);
          expect(job!.status, 'completed');
          expect(summary!.content, 'Compacted');
        },
      );

      test(
        'approved tool decision wakes a live dispatcher after its durable commit',
        () async {
          final fixture = await prepareExecution();
          final now = DateTime.now().toUtc();
          final conversation = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationDatabaseId,
          ))!;
          final execution = (await ConversationExecution.db.findById(
            fixture.database,
            conversation.activeExecutionId!,
          ))!;
          final turn = (await ConversationTurn.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId),
          ))!;
          final assistant = (await ConversationMessage.db.findById(
            fixture.database,
            turn.assistantMessageId!,
          ))!;
          final initialJob = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.turnId.equals(turn.id),
          ))!;
          await ConversationJob.db.updateRow(
            fixture.database,
            initialJob.copyWith(status: 'completed', updatedAt: now),
          );
          await ConversationTurn.db.updateRow(
            fixture.database,
            turn.copyWith(
              status: 'awaitingApproval',
              revision: 2,
              updatedAt: now,
            ),
          );
          await ConversationMessage.db.updateRow(
            fixture.database,
            assistant.copyWith(
              status: 'awaitingApproval',
              revision: assistant.revision + 1,
              updatedAt: now,
            ),
          );
          await ConversationExecution.db.updateRow(
            fixture.database,
            execution.copyWith(status: 'awaitingApproval', updatedAt: now),
          );
          await Conversation.db.updateRow(
            fixture.database,
            conversation.copyWith(
              executionState: 'awaitingApproval',
              updatedAt: now,
            ),
          );
          await ConversationToolCall.db.insertRow(
            fixture.database,
            ConversationToolCall(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationDatabaseId,
              turnId: turn.id!,
              messageId: assistant.id!,
              stableId: 'tool-call-1',
              name: 'tool',
              argumentsJson: '{}',
              argumentsDigest: 'digest-1',
              status: 'pending',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );

          final listenerReady = Completer<void>();
          final drained = Completer<void>();
          final wakes = StreamController<void>(
            sync: true,
            onListen: listenerReady.complete,
          );
          var active = false;
          final host = _CountingCompletingHost();
          final dispatcher = ConversationJobDispatcher(
            drain: (isActive) async {
              await runConversationWorker(
                fixture.database,
                isActive: isActive,
                worker: ConversationWorker(host: host),
              );
              if (!drained.isCompleted) drained.complete();
            },
            onError: (error, stackTrace) => fail('$error\n$stackTrace'),
            recoveryInterval: const Duration(days: 1),
          );
          dispatcher.start(wakeups: wakes.stream, isActive: () => active);
          await listenerReady.future.timeout(const Duration(seconds: 2));
          active = true;
          final useCases = ConversationUseCases(
            conversation_repo.ConversationRepository(),
            publishConversationJob: (session, job) async {
              final persisted = await ConversationJob.db.findById(
                session,
                job.id!,
              );
              expect(persisted, isNotNull);
              expect(persisted!.status, 'queued');
              expect(persisted.requestId, 'approve-1');
              wakes.add(null);
            },
          );

          await useCases.submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: SubmitToolDecisionRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'approve-1',
              turnId: turn.requestId,
              toolCallId: 'tool-call-1',
              argumentsDigest: 'digest-1',
              expectedTurnRevision: 2,
              decision: 'approve',
            ),
          );

          await host.started.future.timeout(const Duration(seconds: 2));
          await drained.future.timeout(const Duration(seconds: 2));
          await dispatcher.stop();
          await wakes.close();

          final resumedJob = await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.requestId.equals('approve-1'),
          );
          final completedTurn = await ConversationTurn.db.findById(
            fixture.database,
            turn.id!,
          );
          final completedConversation = await Conversation.db.findById(
            fixture.database,
            fixture.conversationDatabaseId,
          );
          final assistantMessages = await ConversationMessage.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId) &
                table.role.equals('assistant'),
            orderBy: (table) => table.id,
          );

          expect(host.calls, 1);
          expect(resumedJob!.status, 'completed');
          expect(completedTurn!.status, 'completed');
          expect(
            assistantMessages.map((message) => message.stableId),
            [assistant.stableId, 'approve-1:assistant'],
          );
          expect(assistantMessages.map((message) => message.status), [
            'sent',
            'sent',
          ]);
          expect(completedConversation!.executionState, 'idle');
          expect(completedConversation.activeExecutionId, isNull);
        },
      );

      test(
        'duplicate wakes execute a blocked job once and finish idle',
        () async {
          final fixture = await prepareExecution();
          final block = Completer<void>();
          final host = _CountingCompletingHost(block: block);
          final drained = Completer<void>();
          final wakes = StreamController<void>(sync: true);
          final dispatcher = dispatcherFor(fixture, host, drained);
          dispatcher.start(wakeups: wakes.stream, isActive: () => true);

          await host.started.future.timeout(const Duration(seconds: 2));
          wakes
            ..add(null)
            ..add(null);
          expect(host.calls, 1);
          block.complete();
          await drained.future.timeout(const Duration(seconds: 2));
          await dispatcher.stop();
          await wakes.close();
          await _waitForIdle(fixture, endpoints);

          expect(host.calls, 1);
        },
      );

      test(
        'stop wins when it races approval pausing after the host returns',
        () async {
          final fixture = await prepareExecution();
          final pauseEntered = Completer<void>();
          final releasePause = Completer<void>();
          final worker = ConversationWorker(
            host: _AwaitingApprovalHost(),
            beforePauseForApproval: () async {
              if (!pauseEntered.isCompleted) pauseEntered.complete();
              await releasePause.future;
            },
          );

          final running = runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );
          await pauseEntered.future.timeout(const Duration(seconds: 2));
          final snapshot = await endpoints.conversation.getConversationSnapshot(
            fixture.session,
            GetConversationRequest(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationId,
            ),
          );
          await endpoints.conversation.stopConversation(
            fixture.session,
            StopConversationRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'stop-before-pause',
              conversationId: fixture.conversationId,
              expectedProjectionRevision:
                  snapshot.conversation.projectionRevision,
            ),
          );
          releasePause.complete();
          await running.timeout(const Duration(seconds: 2));

          final conversation = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationDatabaseId,
          ))!;
          final execution = (await ConversationExecution.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.stableId.equals(snapshot.activeExecution!.id),
          ))!;
          final turn = (await ConversationTurn.db.findFirstRow(
            fixture.database,
            where: (table) => table.requestId.equals(execution.stableId),
          ))!;
          final assistant = (await ConversationMessage.db.findById(
            fixture.database,
            turn.assistantMessageId!,
          ))!;
          expect(turn.status, ConversationStatuses.cancelled);
          expect(assistant.status, ConversationStatuses.cancelled);
          expect(execution.status, ConversationStatuses.cancelled);
          expect(conversation.executionState, 'idle');
          expect(conversation.activeExecutionId, isNull);
        },
      );

      test(
        'approval pause and decision submission complete without lock inversion',
        () async {
          final fixture = await prepareExecution();
          final staged = await stageAwaitingApproval(fixture, calls: 1);
          final job = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) => table.turnId.equals(staged.turn.id),
          ))!;
          await ConversationJob.db.updateRow(
            fixture.database,
            job.copyWith(
              status: ConversationJobStatuses.queued,
              availableAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
          final pauseTurnLocked = Completer<void>();
          final releasePause = Completer<void>();
          final worker = ConversationWorker(
            host: _AwaitingApprovalHost(),
            afterApprovalTurnLock: () async {
              pauseTurnLocked.complete();
              await releasePause.future;
            },
          );

          final running = runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );
          await pauseTurnLocked.future.timeout(const Duration(seconds: 2));
          final decision = decisionUseCases().submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: SubmitToolDecisionRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'approve-racing-pause',
              turnId: staged.turn.requestId,
              toolCallId: staged.toolCallIds.single,
              argumentsDigest: 'digest-1',
              expectedTurnRevision: 3,
              decision: 'approve',
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
          releasePause.complete();

          await Future.wait([running, decision]).timeout(
            const Duration(seconds: 2),
          );
          final turn = (await ConversationTurn.db.findById(
            fixture.database,
            staged.turn.id!,
          ))!;
          expect(turn.status, ConversationStatuses.queued);
        },
      );

      test(
        'a second approval pause belongs to its resumed phase assistant',
        () async {
          final fixture = await prepareExecution();
          final worker = ConversationWorker(host: _AwaitingApprovalHost());
          await runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );
          final firstTurn = (await ConversationTurn.db.findFirstRow(
            fixture.database,
            where: (table) => table.conversationId.equals(
              fixture.conversationDatabaseId,
            ),
          ))!;
          final firstAssistant = (await ConversationMessage.db.findById(
            fixture.database,
            firstTurn.assistantMessageId!,
          ))!;
          final now = DateTime.now().toUtc();
          await ConversationToolCall.db.insertRow(
            fixture.database,
            ConversationToolCall(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationDatabaseId,
              turnId: firstTurn.id!,
              messageId: firstAssistant.id!,
              stableId: 'phase-one-call',
              name: 'tool',
              argumentsJson: '{}',
              argumentsDigest: 'phase-one-digest',
              status: 'pending',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          await decisionUseCases().submitToolDecision(
            fixture.database,
            userId: fixture.userId,
            request: SubmitToolDecisionRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'approve-phase-one',
              turnId: firstTurn.requestId,
              toolCallId: 'phase-one-call',
              argumentsDigest: 'phase-one-digest',
              expectedTurnRevision: firstTurn.revision,
              decision: 'approve',
            ),
          );

          await runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );

          final assistants = await ConversationMessage.db.find(
            fixture.database,
            where: (table) =>
                table.conversationId.equals(fixture.conversationDatabaseId) &
                table.role.equals('assistant'),
            orderBy: (table) => table.id,
          );
          expect(assistants.map((assistant) => assistant.stableId), [
            firstAssistant.stableId,
            'approve-phase-one:assistant',
          ]);
          expect(assistants.map((assistant) => assistant.status), [
            'sent',
            ConversationStatuses.awaitingApproval,
          ]);
        },
      );

      test(
        'retry wake waits for its durable availability before rerunning',
        () async {
          final fixture = await prepareExecution();
          final host = _FailOnceHost();
          final published = <ConversationJob>[];
          final worker = ConversationWorker(
            host: host,
            publishConversationJob: (session, job) async {
              final persisted = await ConversationJob.db.findById(
                session,
                job.id!,
              );
              expect(persisted, isNotNull);
              expect(persisted!.status, ConversationJobStatuses.queued);
              expect(persisted.availableAt, job.availableAt);
              published.add(job);
            },
          );

          await runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );

          final retry = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId) &
                table.kind.equals(ConversationJobKinds.turn),
          ))!;
          final databaseNow = await fixture.database.db.unsafeQuery(
            'SELECT clock_timestamp() AS "now"',
          );

          expect(host.calls, 1);
          expect(retry.status, ConversationJobStatuses.queued);
          expect(
            retry.availableAt.isAfter(
              databaseNow.first.toColumnMap()['now']! as DateTime,
            ),
            isTrue,
          );
          expect(published, hasLength(1));
          expect(published.single.id, retry.id);

          await runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );

          expect(host.calls, 1);

          await fixture.database.db.unsafeQuery(
            'UPDATE conversation_job '
            'SET "availableAt" = CURRENT_TIMESTAMP - INTERVAL \'1 second\' '
            'WHERE "id" = ${retry.id}',
          );
          await runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );

          final completed = await ConversationJob.db.findById(
            fixture.database,
            retry.id!,
          );
          expect(host.calls, 2);
          expect(completed!.status, ConversationJobStatuses.completed);
        },
      );

      test(
        'transient renewal retries before aborting a blocked provider request',
        () async {
          final fixture = await prepareExecution();
          final host = _BlockingCompletingHost();
          final renewalRecovered = Completer<void>();
          var renewalAttempts = 0;
          final worker = ConversationWorker(
            host: host,
            renewalInterval: const Duration(milliseconds: 1),
            renewalRetryDelay: const Duration(milliseconds: 1),
            renewLease: (jobId, leaseToken) async {
              renewalAttempts++;
              if (renewalAttempts == 1) {
                throw StateError('transient renewal failure');
              }
              final renewed = await const ConversationJobLeases().renew(
                fixture.database,
                jobId: jobId,
                leaseToken: leaseToken,
                now: DateTime.now().toUtc(),
              );
              if (!renewalRecovered.isCompleted) renewalRecovered.complete();
              return renewed;
            },
          );

          final running = runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );
          await host.started.future.timeout(const Duration(seconds: 2));
          await renewalRecovered.future.timeout(const Duration(seconds: 2));

          expect(host.leaseLostObserved, isFalse);
          host.release();
          await running.timeout(const Duration(seconds: 2));
          await _waitForIdle(fixture, endpoints);

          expect(renewalAttempts, greaterThanOrEqualTo(2));
          expect(host.normalCompletions, 1);
          final job = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId) &
                table.kind.equals(ConversationJobKinds.turn),
          ))!;
          final turn = await ConversationTurn.db.findById(
            fixture.database,
            job.turnId!,
          );
          expect(job.status, ConversationJobStatuses.completed);
          expect(turn!.status, ConversationStatuses.completed);
        },
      );

      test(
        'authoritative lease loss aborts a blocked provider request',
        () async {
          final fixture = await prepareExecution();
          final host = _BlockingCompletingHost();
          final worker = ConversationWorker(
            host: host,
            renewalInterval: const Duration(milliseconds: 1),
            renewalRetryDelay: const Duration(milliseconds: 1),
            renewLease: (jobId, leaseToken) async {
              throw ConversationJobLeaseLostException(jobId);
            },
          );

          final running = runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );
          await host.started.future.timeout(const Duration(seconds: 2));
          await host.leaseLost.future.timeout(const Duration(seconds: 2));
          await running.timeout(const Duration(seconds: 2));
          await _waitForIdle(fixture, endpoints);

          expect(host.normalCompletions, 0);
          final job = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId) &
                table.kind.equals(ConversationJobKinds.turn),
          ))!;
          final turn = await ConversationTurn.db.findById(
            fixture.database,
            job.turnId!,
          );
          expect(job.status, ConversationJobStatuses.completed);
          expect(turn!.status, ConversationStatuses.cancelled);
        },
      );

      test(
        'operation completion during renewal does not reschedule renewal',
        () async {
          final fixture = await prepareExecution();
          final host = _BlockingCompletingHost();
          final renewalStarted = Completer<void>();
          final releaseRenewal = Completer<void>();
          final scheduledTimers = <_ManualTimer>[];
          final worker = ConversationWorker(
            host: host,
            renewalInterval: const Duration(milliseconds: 1),
            renewalTimer: (duration, callback) {
              final timer = _ManualTimer(callback);
              scheduledTimers.add(timer);
              return timer;
            },
            renewLease: (jobId, leaseToken) async {
              if (!renewalStarted.isCompleted) renewalStarted.complete();
              await releaseRenewal.future;
              return const ConversationJobLeases().renew(
                fixture.database,
                jobId: jobId,
                leaseToken: leaseToken,
                now: DateTime.now().toUtc(),
              );
            },
          );

          final running = runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: worker,
          );
          await host.started.future.timeout(const Duration(seconds: 2));
          expect(scheduledTimers, hasLength(1));
          scheduledTimers.single.fire();
          await renewalStarted.future.timeout(const Duration(seconds: 2));

          host.release();
          await scheduledTimers.single.cancelled.future.timeout(
            const Duration(seconds: 2),
          );
          releaseRenewal.complete();
          await running.timeout(const Duration(seconds: 2));

          expect(scheduledTimers, hasLength(1));
        },
      );

      test('inactive ownership leaves a continued execution running', () async {
        final fixture = await prepareExecution();
        final host = _CountingCompletingHost();
        final dispatcher = dispatcherFor(fixture, host, Completer<void>());
        dispatcher.start(
          wakeups: const Stream<void>.empty(),
          isActive: () => false,
        );

        final snapshot = await endpoints.conversation.getConversationSnapshot(
          fixture.session,
          GetConversationRequest(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
          ),
        );
        await dispatcher.stop();

        expect(snapshot.conversation.executionState, 'running');
        expect(host.calls, 0);
      });

      test(
        'empty wake stream fallback executes a continued execution once',
        () async {
          final fixture = await prepareExecution();
          var active = false;
          final host = _CountingCompletingHost();
          final drained = Completer<void>();
          final dispatcher = dispatcherFor(fixture, host, drained);
          dispatcher.start(
            wakeups: const Stream<void>.empty(),
            isActive: () => active,
          );
          active = true;

          await drained.future.timeout(const Duration(seconds: 2));
          await dispatcher.stop();
          await _waitForIdle(fixture, endpoints);

          expect(host.calls, 1);
        },
      );
    },
  );

  withServerpod(
    'ConversationExecutionState concurrent same-request',
    (sessionBuilder, endpoints) {
      test(
        'concurrent Continue requests from independent sessions replay once',
        () async {
          final fixture = await _preparePromptlessExecution(
            sessionBuilder,
          );
          final request = ContinueConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'concurrent-promptless-continue-1',
            conversationId: fixture.conversationId,
            expectedProjectionRevision: 1,
          );
          final firstSession = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              fixture.userId,
              const {},
            ),
          );
          final secondSession = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              fixture.userId,
              const {},
            ),
          );

          try {
            final snapshots = await Future.wait([
              endpoints.conversation.continueConversation(
                firstSession,
                request,
              ),
              endpoints.conversation.continueConversation(
                secondSession,
                request,
              ),
            ]);
            final executions = await ConversationExecution.db.find(
              fixture.database,
              where: (table) =>
                  table.workspaceId.equals(fixture.workspaceId) &
                  table.conversationId.equals(
                    fixture.conversationDatabaseId,
                  ),
            );
            final jobs = await ConversationJob.db.find(
              fixture.database,
              where: (table) =>
                  table.workspaceId.equals(fixture.workspaceId) &
                  table.conversationId.equals(
                    fixture.conversationDatabaseId,
                  ) &
                  table.kind.equals(ConversationJobKinds.turn),
            );
            final events = await ConversationEvent.db.find(
              fixture.database,
              where: (table) =>
                  table.workspaceId.equals(fixture.workspaceId) &
                  table.requestId.equals(request.requestId),
            );

            expect(
              snapshots.map((snapshot) => snapshot.activeExecution!.id).toSet(),
              hasLength(1),
            );
            expect(executions, hasLength(1));
            expect(jobs, hasLength(1));
            expect(events, hasLength(1));
          } finally {
            await runConversationWorker(
              fixture.database,
              isActive: () => true,
              worker: ConversationWorker(host: _CountingCompletingHost()),
            );
            await _waitForIdle(fixture, endpoints);
          }
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}

Future<_ExecutionFixture> _preparePromptlessExecution(
  dynamic sessionBuilder,
) async {
  final userId = const Uuid().v4().toString();
  final session = sessionBuilder.copyWith(
    authentication: AuthenticationOverride.authenticationInfo(userId, const {}),
  );
  final database = session.build();
  await AuthUser.db.insertRow(
    database,
    AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
  );
  await EmailAccount.db.insertRow(
    database,
    EmailAccount(
      authUserId: UuidValue.fromString(userId),
      email: '$userId@example.com',
      passwordHash: 'unused',
    ),
  );
  final workspace = await workspace_repo.CloudWorkspaceRepository()
      .createWorkspace(
        database,
        name: 'Workspace',
        ownerUserId: userId,
        now: DateTime.now().toUtc(),
      );
  final now = DateTime.now().toUtc();
  final conversation = await Conversation.db.insertRow(
    database,
    Conversation(
      workspaceId: workspace.id!,
      stableId: 'conversation-1',
      title: 'Conversation',
      isPinned: false,
      revision: 1,
      projectionRevision: 1,
      eventSequence: 0,
      executionState: 'idle',
      createdAt: now,
      updatedAt: now,
    ),
  );
  return _ExecutionFixture(
    session: session,
    database: database,
    userId: userId,
    workspaceId: workspace.id!,
    conversationDatabaseId: conversation.id!,
    conversationId: conversation.stableId,
  );
}

Future<void> _waitForIdle(
  _ExecutionFixture fixture,
  dynamic endpoints,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  String? lastState;
  while (DateTime.now().isBefore(deadline)) {
    final snapshot = await endpoints.conversation.getConversationSnapshot(
      fixture.session,
      GetConversationRequest(
        workspaceId: fixture.workspaceId,
        conversationId: fixture.conversationId,
      ),
    );
    lastState = snapshot.conversation.executionState;
    if (lastState == 'idle') return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Conversation execution did not reach idle; state=$lastState.');
}

class _ExecutionFixture {
  const _ExecutionFixture({
    required this.session,
    required this.database,
    required this.userId,
    required this.workspaceId,
    required this.conversationDatabaseId,
    required this.conversationId,
  });

  final dynamic session;
  final Session database;
  final String userId;
  final int workspaceId;
  final int conversationDatabaseId;
  final String conversationId;
}

class _CountingCompletingHost implements ConversationEngineHost {
  _CountingCompletingHost({this.block, this.compactionMessageId});

  final Completer<void>? block;
  final int? compactionMessageId;
  final started = Completer<void>();
  final compactionStarted = Completer<void>();
  var calls = 0;
  var compactionCalls = 0;

  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async {
    calls++;
    if (!started.isCompleted) started.complete();
    await block?.future;
    return const ConversationEngineResult(
      content: 'Done',
      finishReason: 'stop',
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
    );
  }

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) async {
    compactionCalls++;
    if (!compactionStarted.isCompleted) compactionStarted.complete();
    final messageId = compactionMessageId;
    if (messageId == null) {
      throw StateError('No compaction message configured.');
    }
    return ConversationCompactionResult(
      summary: 'Compacted',
      range: AgentCompactionRangeSelected(
        fromMessageId: '$messageId',
        throughMessageId: '$messageId',
        messageIds: ['$messageId'],
        keptTailMessageIds: const [],
      ),
    );
  }
}

class _AwaitingApprovalHost extends _CountingCompletingHost {
  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async {
    calls++;
    if (!started.isCompleted) started.complete();
    return const ConversationEngineResult(
      content: '',
      finishReason: 'tool_calls',
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
      awaitingApproval: true,
    );
  }
}

class _FailOnceHost extends _CountingCompletingHost {
  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async {
    calls++;
    if (calls == 1) throw StateError('retry once');
    return const ConversationEngineResult(
      content: 'Done',
      finishReason: 'stop',
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
    );
  }
}

class _BlockingCompletingHost extends _CountingCompletingHost {
  final _release = Completer<void>();
  final leaseLost = Completer<void>();
  var leaseLostObserved = false;
  var normalCompletions = 0;

  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async {
    calls++;
    if (!started.isCompleted) started.complete();
    final abort = leaseLost?.then((_) {
      leaseLostObserved = true;
      if (!this.leaseLost.isCompleted) this.leaseLost.complete();
    });
    await Future.any([
      _release.future,
      ?abort,
    ]);
    if (leaseLostObserved) throw const ConversationCancelledException();
    normalCompletions++;
    return const ConversationEngineResult(
      content: 'Done',
      finishReason: 'stop',
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
    );
  }
}

class _ManualTimer implements Timer {
  _ManualTimer(this._callback);

  final void Function() _callback;
  final cancelled = Completer<void>();
  var _isActive = true;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => 0;

  @override
  void cancel() {
    _isActive = false;
    if (!cancelled.isCompleted) cancelled.complete();
  }

  void fire() {
    if (!_isActive) return;
    _isActive = false;
    _callback();
  }
}
