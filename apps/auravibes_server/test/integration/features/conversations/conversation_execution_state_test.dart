import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_engine_host.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
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

          expect(host.calls, 1);
          expect(resumedJob!.status, 'completed');
          expect(completedTurn!.status, 'completed');
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
