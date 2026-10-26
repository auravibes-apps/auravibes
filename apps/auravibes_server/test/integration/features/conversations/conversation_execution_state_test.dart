import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:genkit/plugin.dart' show GenkitException;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_engine_host.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/conversations/usecases/conversation_usecases.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_job_dispatcher.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_job_leases.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_worker.dart';
import 'package:auravibes_server/src/features/workspaces/domain/workspace_roles.dart';
import 'package:auravibes_server/src/generated/protocol.dart';

import '../../test_tools/auth_services_test_helper.dart';
import '../../test_tools/serverpod_test_tools.dart';

import 'package:auravibes_server/src/features/conversations/repositories/conversation_repository.dart'
    as conversation_repo;
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;

void main() {
  withServerpod('ConversationExecutionState', (sessionBuilder, endpoints) {
    Future<_ExecutionFixture> prepareExecution({
      bool continueConversation = true,
      bool seedCompletedTurn = false,
      String? languageCode,
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
      if (seedCompletedTurn) {
        final historyTime = now.subtract(const Duration(seconds: 2));
        final historyUser = await ConversationMessage.db.insertRow(
          database,
          ConversationMessage(
            workspaceId: workspace.id!,
            conversationId: conversation.id!,
            stableId: 'history-user',
            role: 'user',
            kind: 'text',
            status: 'sent',
            content: 'History',
            revision: 1,
            createdAt: historyTime,
            updatedAt: historyTime,
          ),
        );
        final historyAssistant = await ConversationMessage.db.insertRow(
          database,
          ConversationMessage(
            workspaceId: workspace.id!,
            conversationId: conversation.id!,
            stableId: 'history-assistant',
            role: 'assistant',
            kind: 'text',
            status: 'sent',
            content: 'Completed history',
            revision: 1,
            createdAt: historyTime.add(const Duration(milliseconds: 1)),
            updatedAt: historyTime.add(const Duration(milliseconds: 1)),
          ),
        );
        final historyTurn = await ConversationTurn.db.insertRow(
          database,
          ConversationTurn(
            workspaceId: workspace.id!,
            conversationId: conversation.id!,
            requestId: 'history-turn',
            requestHash: '{}',
            initiatorUserId: userId,
            userMessageId: historyUser.id,
            assistantMessageId: historyAssistant.id,
            status: ConversationStatuses.completed,
            revision: 1,
            acceptedSequence: 1,
            terminalAt: historyTime.add(const Duration(milliseconds: 1)),
            createdAt: historyTime,
            updatedAt: historyTime.add(const Duration(milliseconds: 1)),
          ),
        );
        await ConversationMessage.db.updateRow(
          database,
          historyUser.copyWith(turnId: historyTurn.id),
        );
        await ConversationMessage.db.updateRow(
          database,
          historyAssistant.copyWith(turnId: historyTurn.id),
        );
      }
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
            languageCode: languageCode,
          ),
        );
        final snapshot = await endpoints.conversation.continueConversation(
          session,
          ContinueConversationRequest(
            workspaceId: workspace.id!,
            requestId: 'continue-1',
            conversationId: conversation.stableId,
            expectedProjectionRevision: 2,
            languageCode: languageCode,
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

    Future<void> deleteFixtureAccount(_ExecutionFixture fixture) async {
      final newOwnerId = const Uuid().v4().toString();
      await AuthUser.db.insertRow(
        fixture.database,
        AuthUser(id: UuidValue.fromString(newOwnerId), scopeNames: const {}),
      );
      final workspace = (await CloudWorkspace.db.findById(
        fixture.database,
        fixture.workspaceId,
      ))!;
      await CloudWorkspace.db.updateRow(
        fixture.database,
        workspace.copyWith(ownerUserId: newOwnerId),
      );
      initializeTestAuthServices(fixture.database.serverpod);
      await endpoints.account.deleteCurrentUser(fixture.session);
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
      'queued user messages are claimed one at a time in FIFO order',
      () async {
        final fixture = await prepareExecution(continueConversation: false);
        await endpoints.conversation.queueConversationMessage(
          fixture.session,
          QueueConversationMessageRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'queue-first',
            conversationId: fixture.conversationId,
            expectedProjectionRevision: 1,
            clientMessageId: 'message-first',
            content: 'First arrival',
            attachmentIds: const [],
          ),
        );
        await endpoints.conversation.queueConversationMessage(
          fixture.session,
          QueueConversationMessageRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'queue-second',
            conversationId: fixture.conversationId,
            expectedProjectionRevision: 2,
            clientMessageId: 'message-second',
            content: 'Second arrival',
            attachmentIds: const [],
          ),
        );

        final continued =
            await ConversationUseCases(
              conversation_repo.ConversationRepository(),
            ).continueOldestQueuedMessage(
              fixture.database,
              userId: fixture.userId,
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationId,
            );
        expect(continued, isTrue);

        final started = await endpoints.conversation.getConversationSnapshot(
          fixture.session,
          GetConversationRequest(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
          ),
        );

        expect(started.activeExecution!.claimedMessageIds, ['message-first']);
        expect(started.pendingMessages.map((message) => message.id), [
          'message-second',
        ]);
        final queuedEvents = await ConversationEvent.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId) &
              table.kind.equals(ConversationEventType.messageQueued),
          orderBy: (table) => table.sequence,
        );
        expect(queuedEvents.map((event) => event.eventId), [
          'user-message:message-first',
          'user-message:message-second',
        ]);
      },
    );

    test('queued message starts with its own conversation language', () async {
      final fixture = await prepareExecution(languageCode: 'en');
      final snapshot = await endpoints.conversation.getConversationSnapshot(
        fixture.session,
        GetConversationRequest(
          workspaceId: fixture.workspaceId,
          conversationId: fixture.conversationId,
        ),
      );
      await endpoints.conversation.queueConversationMessage(
        fixture.session,
        QueueConversationMessageRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'queue-spanish-message',
          conversationId: fixture.conversationId,
          expectedProjectionRevision: snapshot.conversation.projectionRevision,
          clientMessageId: 'message-spanish',
          content: 'Mensaje en español',
          attachmentIds: const [],
          languageCode: 'es',
        ),
      );

      final host = _CountingCompletingHost();
      await runConversationWorker(
        fixture.database,
        isActive: () => true,
        worker: ConversationWorker(host: host),
      );

      expect(host.languageCodes, ['en', 'es']);
    });

    test(
      'legacy queued messages without a locale fall back to English',
      () async {
        final fixture = await prepareExecution(languageCode: 'es');
        final snapshot = await endpoints.conversation.getConversationSnapshot(
          fixture.session,
          GetConversationRequest(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
          ),
        );
        await endpoints.conversation.queueConversationMessage(
          fixture.session,
          QueueConversationMessageRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'queue-legacy-message',
            conversationId: fixture.conversationId,
            expectedProjectionRevision:
                snapshot.conversation.projectionRevision,
            clientMessageId: 'message-legacy',
            content: 'Legacy message',
            attachmentIds: const [],
          ),
        );

        final host = _CountingCompletingHost();
        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: host),
        );

        expect(host.languageCodes, ['es', 'en']);
      },
    );

    test('malformed queued message locale falls back to English', () async {
      final fixture = await prepareExecution(languageCode: 'es');
      final snapshot = await endpoints.conversation.getConversationSnapshot(
        fixture.session,
        GetConversationRequest(
          workspaceId: fixture.workspaceId,
          conversationId: fixture.conversationId,
        ),
      );
      await endpoints.conversation.queueConversationMessage(
        fixture.session,
        QueueConversationMessageRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'queue-malformed-message',
          conversationId: fixture.conversationId,
          expectedProjectionRevision: snapshot.conversation.projectionRevision,
          clientMessageId: 'message-malformed',
          content: 'Malformed message locale',
          attachmentIds: const [],
          languageCode: 'fr-CA',
        ),
      );
      final event = await ConversationEvent.db.findFirstRow(
        fixture.database,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.eventId.equals('user-message:message-malformed'),
      );
      expect(event, isNotNull);
      await ConversationEvent.db.updateRow(
        fixture.database,
        event!.copyWith(payloadJson: '{'),
      );

      final host = _CountingCompletingHost();
      await runConversationWorker(
        fixture.database,
        isActive: () => true,
        worker: ConversationWorker(host: host),
      );

      expect(host.languageCodes, ['es', 'en']);
    });

    test(
      'background-work continuation keeps locale and defaults malformed events',
      () async {
        final fixture = await prepareExecution(languageCode: 'en');
        final now = DateTime.now().toUtc();
        const workEvents = [
          (
            workId: 'background-work-language',
            payloadJson:
                '{"workId":"background-work-language",'
                '"languageCode":"es"}',
          ),
          (
            workId: 'background-work-malformed-language',
            payloadJson: '{',
          ),
        ];
        await fixture.database.db.transaction((transaction) async {
          var conversation = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationDatabaseId,
            transaction: transaction,
          ))!;
          for (final workEvent in workEvents) {
            final eventId = 'background-work-completion:${workEvent.workId}';
            final sequence = conversation.eventSequence + 1;
            conversation = await Conversation.db.updateRow(
              fixture.database,
              conversation.copyWith(
                eventSequence: sequence,
                projectionRevision: conversation.projectionRevision + 1,
                updatedAt: now,
              ),
              transaction: transaction,
            );
            await ConversationEvent.db.insertRow(
              fixture.database,
              ConversationEvent(
                workspaceId: fixture.workspaceId,
                conversationId: fixture.conversationDatabaseId,
                sequence: sequence,
                eventId: eventId,
                actorUserId: fixture.userId,
                requestId: eventId,
                kind: ConversationEventType.backgroundWorkCompleted,
                payloadJson: workEvent.payloadJson,
                createdAt: now,
              ),
              transaction: transaction,
            );
            await conversation_repo.ConversationRepository()
                .insertPendingMessage(
                  fixture.database,
                  conversation: conversation,
                  clientMessageId: 'background_work:${workEvent.workId}',
                  content: 'Resume background work.',
                  attachmentIds: const [],
                  metadataJson: jsonEncode({
                    'isBackgroundWorkCompletion': true,
                    'backgroundWorkId': workEvent.workId,
                    'eventId': eventId,
                  }),
                  now: now,
                  transaction: transaction,
                );
          }
        });

        final host = _CountingCompletingHost();
        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: host),
        );

        expect(host.languageCodes, ['en', 'es', 'en']);
      },
    );

    test('cancel hides turn existence from non-members', () async {
      final fixture = await prepareExecution();
      final attackerId = const Uuid().v4().toString();
      final attackerSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          attackerId,
          const {},
        ),
      );
      await AuthUser.db.insertRow(
        fixture.database,
        AuthUser(id: UuidValue.fromString(attackerId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        fixture.database,
        EmailAccount(
          authUserId: UuidValue.fromString(attackerId),
          email: 'cancel-attacker@example.com',
          passwordHash: 'unused',
        ),
      );

      for (final turnId in ['continue-1', 'missing-turn']) {
        await expectLater(
          endpoints.conversation.cancelTurn(
            attackerSession,
            CancelTurnRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'unauthorized-cancel-$turnId',
              turnId: turnId,
              expectedTurnRevision: 1,
            ),
          ),
          throwsA(
            isA<ConversationException>().having(
              (error) => error.code,
              'code',
              ConversationErrorCode.permissionDenied,
            ),
          ),
        );
      }
    });

    Future<({ConversationTurn turn, List<String> toolCallIds})>
    stageAwaitingApproval(
      _ExecutionFixture fixture, {
      required int calls,
      String? argumentsDigest,
    }) => _stageAwaitingApproval(
      fixture,
      calls: calls,
      argumentsDigest: argumentsDigest,
    );

    ConversationUseCases decisionUseCases() => ConversationUseCases(
      conversation_repo.ConversationRepository(),
      publishConversationJob: (_, _) async {},
    );

    test('workspace removal fences new detached tool work', () async {
      final fixture = await prepareExecution();
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
      final now = DateTime.now().toUtc();
      final _ = await ConversationToolCall.db.insertRow(
        fixture.database,
        ConversationToolCall(
          workspaceId: fixture.workspaceId,
          conversationId: fixture.conversationDatabaseId,
          turnId: turn.id!,
          messageId: assistant.id!,
          stableId: 'tool-call-after-workspace-removal',
          name: 'background-search',
          argumentsJson: '{}',
          argumentsDigest: 'digest',
          backgroundEligible: true,
          status: 'running',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final workspace = (await CloudWorkspace.db.findById(
        fixture.database,
        fixture.workspaceId,
      ))!;
      final _ = await CloudWorkspace.db.updateRow(
        fixture.database,
        workspace.copyWith(
          revision: workspace.revision + 1,
          deletedAt: now,
          updatedAt: now,
        ),
      );

      await expectLater(
        decisionUseCases().detachToolCall(
          fixture.database,
          userId: fixture.userId,
          request: DetachToolCallRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'detach-after-workspace-removal',
            conversationId: fixture.conversationId,
            toolCallId: 'tool-call-after-workspace-removal',
          ),
        ),
        throwsA(
          isA<ConversationException>().having(
            (error) => error.code,
            'code',
            ConversationErrorCode.notFound,
          ),
        ),
      );
      expect(
        await BackgroundWorkRecord.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        ),
        isEmpty,
      );
    });

    test('Fork during approval stops before the active user turn', () async {
      final fixture = await prepareExecution(seedCompletedTurn: true);
      final staged = await stageAwaitingApproval(fixture, calls: 1);

      final fork = await decisionUseCases().fork(
        fixture.database,
        userId: fixture.userId,
        request: ForkConversationRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'fork-approval',
          forkConversationId: 'fork-1',
          sourceConversationId: fixture.conversationId,
        ),
      );

      expect(fork.forkThroughMessageId, 'history-assistant');
      final snapshot = await decisionUseCases().getConversationSnapshot(
        fixture.database,
        userId: fixture.userId,
        request: GetConversationRequest(
          workspaceId: fixture.workspaceId,
          conversationId: fork.id,
        ),
      );
      expect(snapshot.messages.map((message) => message.id), [
        'history-assistant',
        'history-user',
      ]);
      expect(snapshot.toolCalls, isEmpty);
      expect(snapshot.pendingMessages, isEmpty);
      expect(snapshot.activeExecution, isNull);
      expect(snapshot.conversation.executionState, 'idle');
      expect(staged.toolCallIds, ['tool-call-1']);
      final sourceCall = (await ConversationToolCall.db.findFirstRow(
        fixture.database,
        where: (table) => table.stableId.equals(staged.toolCallIds.single),
      ))!;
      expect(sourceCall.status, 'pending');
    });

    test(
      'Fork strips detached work state and keeps delivered tool history',
      () async {
        final fixture = await prepareExecution(
          continueConversation: false,
          seedCompletedTurn: true,
        );
        final now = DateTime.now().toUtc();
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
        const detachedToolCallId = 'detached-tool-call';
        const detachedWorkId = 'detached-work-id';
        const completedToolCallId = 'completed-detached-tool-call';
        const completedWorkId = 'completed-detached-work-id';
        const deliveredToolCallId = 'delivered-tool-call';
        final acknowledgement = jsonEncode({
          'status': 'running_in_background',
          'work_id': detachedWorkId,
        });
        final detachedCall = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            turnId: turn.id!,
            messageId: assistant.id!,
            stableId: detachedToolCallId,
            name: 'background-search',
            argumentsJson: '{"private":"search query"}',
            argumentsDigest: 'detached-digest',
            backgroundWorkStableId: detachedWorkId,
            status: 'runningInBackground',
            resultJson: acknowledgement,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await BackgroundWorkRecord.db.insertRow(
          fixture.database,
          BackgroundWorkRecord(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            conversationToolCallId: detachedCall.id!,
            originatingMessageId: assistant.id,
            stableId: detachedWorkId,
            toolCallId: detachedToolCallId,
            toolKind: 'skill.native',
            status: 'running',
            createdAt: now,
            updatedAt: now,
          ),
        );
        final completedAcknowledgement = jsonEncode({
          'status': 'running_in_background',
          'work_id': completedWorkId,
        });
        final completedCall = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            turnId: turn.id!,
            messageId: assistant.id!,
            stableId: completedToolCallId,
            name: 'completed-background-search',
            argumentsJson: '{"private":"completed query"}',
            argumentsDigest: 'completed-detached-digest',
            backgroundWorkStableId: completedWorkId,
            status: 'runningInBackground',
            resultJson: completedAcknowledgement,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await BackgroundWorkRecord.db.insertRow(
          fixture.database,
          BackgroundWorkRecord(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            conversationToolCallId: completedCall.id!,
            originatingMessageId: assistant.id,
            stableId: completedWorkId,
            toolCallId: completedToolCallId,
            toolKind: 'skill.native',
            status: 'completed',
            statusPreview: 'Completed',
            resultContent: 'private stored completion result',
            resultByteLength: 'private stored completion result'.length,
            createdAt: now,
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
            stableId: deliveredToolCallId,
            name: 'delivered-search',
            argumentsJson: '{"query":"public history"}',
            argumentsDigest: 'delivered-digest',
            status: 'success',
            resultJson: '{"answer":"already delivered"}',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final userMessage = (await ConversationMessage.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId) &
              table.role.equals('user'),
        )).single;
        final toolCallIdsByMessageId =
            await conversation_repo.ConversationRepository()
                .listBackgroundWorkToolCallIdsByMessageId(
                  fixture.database,
                  workspaceId: fixture.workspaceId,
                  messages: [assistant],
                );
        expect(toolCallIdsByMessageId.keys, {assistant.id!});
        expect(
          toolCallIdsByMessageId[assistant.id!],
          {detachedToolCallId, completedToolCallId},
        );
        expect(
          await conversation_repo.ConversationRepository()
              .listBackgroundWorkToolCallIdsByMessageId(
                fixture.database,
                workspaceId: fixture.workspaceId,
                messages: [userMessage],
              ),
          isEmpty,
          reason:
              'Other messages in the same conversation have no detached calls.',
        );
        await ConversationMessage.db.updateRow(
          fixture.database,
          assistant.copyWith(
            metadataJson: jsonEncode({
              'toolCalls': [
                {
                  'id': detachedToolCallId,
                  'arguments': {'private': 'search query'},
                  'result': jsonDecode(acknowledgement),
                },
                {
                  'id': completedToolCallId,
                  'arguments': {'private': 'completed query'},
                  'result': jsonDecode(completedAcknowledgement),
                },
                {
                  'id': deliveredToolCallId,
                  'arguments': {'query': 'public history'},
                  'result': {'answer': 'already delivered'},
                },
              ],
              'providerToolBatches': [
                {
                  'assistant': {
                    'content': null,
                    'tool_calls': [
                      {
                        'id': detachedToolCallId,
                        'type': 'function',
                        'function': {
                          'name': 'background-search',
                          'arguments': '{"private":"search query"}',
                        },
                      },
                      {
                        'id': deliveredToolCallId,
                        'type': 'function',
                        'function': {
                          'name': 'delivered-search',
                          'arguments': '{"query":"public history"}',
                        },
                      },
                    ],
                  },
                  'toolCallIds': [detachedToolCallId, deliveredToolCallId],
                },
              ],
            }),
            updatedAt: now,
          ),
        );

        final sourceConversation = (await Conversation.db.findById(
          fixture.database,
          fixture.conversationDatabaseId,
        ))!;
        await endpoints.conversation.queueConversationMessage(
          fixture.session,
          QueueConversationMessageRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'queue-before-fork',
            conversationId: fixture.conversationId,
            expectedProjectionRevision: sourceConversation.projectionRevision,
            clientMessageId: 'queued-message-not-forked',
            content: 'This queued prompt stays in the source.',
            attachmentIds: const [],
          ),
        );

        final useCases = decisionUseCases();
        final fork = await useCases.fork(
          fixture.database,
          userId: fixture.userId,
          request: ForkConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'fork-with-detached-work',
            forkConversationId: 'fork-detached-work',
            sourceConversationId: fixture.conversationId,
          ),
        );
        final forkSnapshot = await useCases.getConversationSnapshot(
          fixture.database,
          userId: fixture.userId,
          request: GetConversationRequest(
            workspaceId: fixture.workspaceId,
            conversationId: fork.id,
          ),
        );
        final forkWorkerMessages =
            await conversation_repo.ConversationRepository()
                .listEffectiveMessages(
                  fixture.database,
                  workspaceId: fixture.workspaceId,
                  conversationId: fork.id,
                );
        final nestedFork = await useCases.fork(
          fixture.database,
          userId: fixture.userId,
          request: ForkConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'fork-from-detached-work-fork',
            forkConversationId: 'nested-fork-detached-work',
            sourceConversationId: fork.id,
          ),
        );
        final nestedSnapshot = await useCases.getConversationSnapshot(
          fixture.database,
          userId: fixture.userId,
          request: GetConversationRequest(
            workspaceId: fixture.workspaceId,
            conversationId: nestedFork.id,
          ),
        );
        final nestedWorkerMessages =
            await conversation_repo.ConversationRepository()
                .listEffectiveMessages(
                  fixture.database,
                  workspaceId: fixture.workspaceId,
                  conversationId: nestedFork.id,
                );
        final forkBackgroundWorks = await useCases.listBackgroundWorks(
          fixture.database,
          userId: fixture.userId,
          request: ListBackgroundWorksRequest(
            workspaceId: fixture.workspaceId,
            conversationId: fork.id,
          ),
        );
        final nestedBackgroundWorks = await useCases.listBackgroundWorks(
          fixture.database,
          userId: fixture.userId,
          request: ListBackgroundWorksRequest(
            workspaceId: fixture.workspaceId,
            conversationId: nestedFork.id,
          ),
        );
        final sourceBackgroundWorks = await useCases.listBackgroundWorks(
          fixture.database,
          userId: fixture.userId,
          request: ListBackgroundWorksRequest(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
          ),
        );

        final forkConversation = (await Conversation.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals(fork.id),
        ))!;
        final forkAssistant = forkSnapshot.messages.singleWhere(
          (message) => message.id == assistant.stableId,
        );
        final forkMetadata = jsonDecode(forkAssistant.metadataJson!) as Map;
        final forkToolCalls = forkMetadata['toolCalls']! as List;
        final forkProviderBatches =
            forkMetadata['providerToolBatches']! as List;
        final forkCalls = forkSnapshot.toolCalls
            .where((call) => call.messageId == assistant.stableId)
            .toList();
        final forkWorkerAssistant = forkWorkerMessages.singleWhere(
          (message) => message.stableId == assistant.stableId,
        );
        final nestedAssistant = nestedSnapshot.messages.singleWhere(
          (message) => message.id == assistant.stableId,
        );
        final nestedWorkerAssistant = nestedWorkerMessages.singleWhere(
          (message) => message.stableId == assistant.stableId,
        );
        final sourceWork = await BackgroundWorkRecord.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals(detachedWorkId),
        );
        final completedSourceWork = await BackgroundWorkRecord.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals(completedWorkId),
        );
        final forkQueuedMessage = await ConversationMessage.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.conversationId.equals(forkConversation.id) &
              table.stableId.equals('queued-message-not-forked'),
        );
        final forkConversationToolCalls = await ConversationToolCall.db.find(
          fixture.database,
          where: (table) => table.conversationId.equals(forkConversation.id),
        );
        final sourceAssistantAfterFork = (await ConversationMessage.db.findById(
          fixture.database,
          assistant.id!,
        ))!;
        final sourceCallsAfterFork = await ConversationToolCall.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        );
        final forkEvents = await ConversationEvent.db.find(
          fixture.database,
          where: (table) => table.conversationId.equals(forkConversation.id),
        );

        expect(fork.forkMaterializedAt, isNull);
        expect(
          forkConversation.forkSourceConversationId,
          fixture.conversationId,
        );
        expect(forkSnapshot.messages.map((message) => message.id), [
          'history-assistant',
          'history-user',
        ]);
        expect(forkAssistant.isForkReference, isTrue);
        expect(forkCalls, hasLength(1));
        expect(forkCalls.single.name, 'delivered-search');
        expect(forkCalls.single.status, 'success');
        expect(forkCalls.single.resultJson, '{"answer":"already delivered"}');
        expect(forkToolCalls, hasLength(1));
        expect(forkToolCalls.single['id'], deliveredToolCallId);
        expect(forkProviderBatches, hasLength(1));
        final providerBatch = forkProviderBatches.single as Map;
        expect(providerBatch['toolCallIds'], [deliveredToolCallId]);
        final providerToolCalls =
            (providerBatch['assistant'] as Map)['tool_calls'] as List;
        expect(providerToolCalls, hasLength(1));
        expect(providerToolCalls.single['id'], deliveredToolCallId);
        expect(forkAssistant.metadataJson, isNot(contains(detachedWorkId)));
        expect(forkAssistant.metadataJson, isNot(contains(completedWorkId)));
        expect(forkAssistant.metadataJson, isNot(contains('search query')));
        expect(forkAssistant.metadataJson, isNot(contains('completed query')));
        expect(
          forkWorkerAssistant.metadataJson,
          isNot(contains(detachedWorkId)),
        );
        expect(
          forkWorkerAssistant.metadataJson,
          isNot(contains(completedWorkId)),
        );
        expect(
          forkWorkerAssistant.metadataJson,
          isNot(contains('search query')),
        );
        expect(
          forkWorkerAssistant.metadataJson,
          isNot(contains('completed query')),
        );
        expect(nestedFork.forkMaterializedAt, isNull);
        expect(
          nestedSnapshot.toolCalls
              .where((call) => call.messageId == assistant.stableId)
              .map((call) => call.id),
          [deliveredToolCallId],
        );
        expect(nestedAssistant.metadataJson, isNot(contains(detachedWorkId)));
        expect(nestedAssistant.metadataJson, isNot(contains(completedWorkId)));
        expect(nestedAssistant.metadataJson, isNot(contains('search query')));
        expect(
          nestedWorkerAssistant.metadataJson,
          isNot(contains('completed query')),
        );
        expect(forkBackgroundWorks, isEmpty);
        expect(nestedBackgroundWorks, isEmpty);
        expect(
          sourceBackgroundWorks.map((work) => work.id).toSet(),
          {detachedWorkId, completedWorkId},
        );
        expect(sourceWork?.status, 'running');
        expect(completedSourceWork?.status, 'completed');
        expect(
          completedSourceWork?.resultContent,
          'private stored completion result',
        );
        expect(sourceAssistantAfterFork.metadataJson, contains(detachedWorkId));
        expect(
          sourceAssistantAfterFork.metadataJson,
          contains(completedWorkId),
        );
        expect(sourceCallsAfterFork, hasLength(3));
        expect(forkQueuedMessage, isNull);
        expect(forkConversationToolCalls, isEmpty);
        expect(forkSnapshot.pendingMessages, isEmpty);
        expect(
          forkEvents.map((event) => event.payloadJson),
          everyElement(isNot(contains('queued-message-not-forked'))),
        );
      },
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
            conversationId: fixture.conversationId,
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

    test('removed approved tool resolves its existing durable call', () async {
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
    });

    test('Skip leaves other pending approvals awaiting a decision', () async {
      final fixture = await prepareExecution();
      final staged = await stageAwaitingApproval(fixture, calls: 2);

      await decisionUseCases().submitToolDecision(
        fixture.database,
        userId: fixture.userId,
        request: SubmitToolDecisionRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'skip-one-of-two',
          conversationId: fixture.conversationId,
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
      'batch decision handles all pending calls and queues one continuation',
      () async {
        final fixture = await prepareExecution();
        final staged = await stageAwaitingApproval(fixture, calls: 2);
        final request = SubmitToolDecisionBatchRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'approve-all',
          decision: 'approve',
          calls: [
            for (var index = 0; index < staged.toolCallIds.length; index++)
              SubmitToolDecisionBatchCall(
                conversationId: fixture.conversationId,
                turnId: staged.turn.requestId,
                toolCallId: staged.toolCallIds[index],
                argumentsDigest: 'digest-${index + 1}',
                expectedTurnRevision: 2,
              ),
          ],
        );

        final result = await decisionUseCases().submitToolDecisionBatch(
          fixture.database,
          userId: fixture.userId,
          request: request,
        );

        expect(result.accepted, hasLength(2));
        expect(result.alreadyHandled, isEmpty);
        expect(result.conflicted, isEmpty);
        final calls = await ConversationToolCall.db.find(
          fixture.database,
          where: (table) => table.turnId.equals(staged.turn.id),
        );
        expect(calls.map((call) => call.status), everyElement('approved'));
        final turn = (await ConversationTurn.db.findById(
          fixture.database,
          staged.turn.id!,
        ))!;
        expect(turn.status, ConversationStatuses.queued);
        final jobs = await ConversationJob.db.find(
          fixture.database,
          where: (table) => table.requestId.like('approve-all:%'),
        );
        expect(jobs, hasLength(1));
      },
    );

    test(
      'batch decision rejects a member acting on another user turn',
      () async {
        final fixture = await prepareExecution();
        final staged = await stageAwaitingApproval(fixture, calls: 1);
        final memberId = const Uuid().v4().toString();
        final now = DateTime.now().toUtc();
        final memberSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            memberId,
            const {},
          ),
        );
        await AuthUser.db.insertRow(
          fixture.database,
          AuthUser(id: UuidValue.fromString(memberId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          fixture.database,
          EmailAccount(
            authUserId: UuidValue.fromString(memberId),
            email: 'batch-attacker@example.com',
            passwordHash: 'unused',
          ),
        );
        await WorkspaceMember.db.insertRow(
          fixture.database,
          WorkspaceMember(
            workspaceId: fixture.workspaceId,
            userId: memberId,
            role: WorkspaceRoles.member,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await expectLater(
          endpoints.conversation.submitToolDecisionBatch(
            memberSession,
            SubmitToolDecisionBatchRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'unauthorized-approve-all',
              decision: 'approve',
              calls: [
                SubmitToolDecisionBatchCall(
                  conversationId: fixture.conversationId,
                  turnId: staged.turn.requestId,
                  toolCallId: staged.toolCallIds.single,
                  argumentsDigest: 'digest-1',
                  expectedTurnRevision: 2,
                  editedArgumentsJson: '{"value":"attacker-controlled"}',
                ),
              ],
            ),
          ),
          throwsA(
            isA<ConversationException>().having(
              (error) => error.code,
              'code',
              ConversationErrorCode.permissionDenied,
            ),
          ),
        );

        final toolCall = (await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) => table.turnId.equals(staged.turn.id),
        ))!;
        expect(toolCall.status, 'pending');
        expect(toolCall.decision, isNull);
        expect(toolCall.argumentsJson, '{}');
        expect(toolCall.decisionByUserId, isNull);
      },
    );

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
            conversationId: fixture.conversationId,
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
              conversationId: fixture.conversationId,
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
            conversationId: fixture.conversationId,
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
          conversationId: fixture.conversationId,
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
            conversationId: fixture.conversationId,
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
        expect(calls.map((call) => call.status).toSet(), {'denied'});
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
        final argumentsDigest = base64UrlEncode(
          (await Sha256().hash(utf8.encode('{}'))).bytes,
        );
        final staged = await stageAwaitingApproval(
          fixture,
          calls: 2,
          argumentsDigest: argumentsDigest,
        );

        await decisionUseCases().submitToolDecision(
          fixture.database,
          userId: fixture.userId,
          request: SubmitToolDecisionRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'skip-a',
            conversationId: fixture.conversationId,
            turnId: staged.turn.requestId,
            toolCallId: staged.toolCallIds.first,
            argumentsDigest: argumentsDigest,
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
            conversationId: fixture.conversationId,
            turnId: staged.turn.requestId,
            toolCallId: staged.toolCallIds.first,
            argumentsDigest: argumentsDigest,
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
            'reasoningConfigJson': null,
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

    test('worker cancels queued work after membership is revoked', () async {
      final fixture = await prepareExecution();
      final member = (await WorkspaceMember.db.findFirstRow(
        fixture.database,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.userId.equals(fixture.userId),
      ))!;
      await WorkspaceMember.db.updateRow(
        fixture.database,
        member.copyWith(removedAt: DateTime.now().toUtc()),
      );
      final host = _CountingCompletingHost();

      await runConversationWorker(
        fixture.database,
        isActive: () => true,
        worker: ConversationWorker(host: host),
      );

      final turn = (await ConversationTurn.db.findFirstRow(
        fixture.database,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.conversationId.equals(fixture.conversationDatabaseId),
      ))!;
      final job = (await ConversationJob.db.findFirstRow(
        fixture.database,
        where: (table) => table.turnId.equals(turn.id),
      ))!;
      final assistant = (await ConversationMessage.db.findById(
        fixture.database,
        turn.assistantMessageId!,
      ))!;
      expect(host.calls, 0);
      expect(turn.status, ConversationStatuses.cancelled);
      expect(turn.revision, 2);
      expect(assistant.status, ConversationStatuses.cancelled);
      expect(job.status, ConversationJobStatuses.completed);
      expect(job.attempt, 0);
      expect(job.leaseOwner, isNull);
      expect(job.leaseToken, isNull);
      expect(job.leaseExpiresAt, isNull);
    });

    test(
      'revoked member non-turn jobs cancel once and release waiting parent turn',
      () async {
        final fixture = await prepareExecution();
        final turn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        ))!;
        final parentJob = (await ConversationJob.db.findFirstRow(
          fixture.database,
          where: (table) => table.turnId.equals(turn.id),
        ))!;
        await ConversationJob.db.updateRow(
          fixture.database,
          parentJob.copyWith(
            status: ConversationJobStatuses.waitingForSubAgents,
          ),
        );
        await ConversationTurn.db.updateRow(
          fixture.database,
          turn.copyWith(status: ConversationStatuses.running),
        );
        final now = DateTime.now().toUtc();
        final nonTurnJobs = <ConversationJob>[];
        for (final kind in [
          ConversationJobKinds.compact,
          ConversationJobKinds.title,
          ConversationJobKinds.subAgent,
        ]) {
          nonTurnJobs.add(
            await ConversationJob.db.insertRow(
              fixture.database,
              ConversationJob(
                workspaceId: fixture.workspaceId,
                conversationId: fixture.conversationDatabaseId,
                turnId: kind == ConversationJobKinds.compact ? null : turn.id,
                requestId: 'revoked-$kind',
                kind: kind,
                status: ConversationJobStatuses.queued,
                payloadJson: jsonEncode({
                  'actorUserId': fixture.userId,
                }),
                attempt: 0,
                maxAttempts: 3,
                availableAt: DateTime.utc(2000),
                createdAt: now,
                updatedAt: now,
              ),
            ),
          );
        }
        final member = (await WorkspaceMember.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.userId.equals(fixture.userId),
        ))!;
        await WorkspaceMember.db.updateRow(
          fixture.database,
          member.copyWith(removedAt: now),
        );
        final host = _CountingCompletingHost();
        final worker = ConversationWorker(host: host);

        for (final _ in nonTurnJobs) {
          expect(
            await worker.runOnce(
              fixture.database,
              workerId: 'revoked-non-turn-worker',
            ),
            isTrue,
          );
        }
        expect(
          await ConversationJob.db.findById(fixture.database, parentJob.id!),
          isNotNull,
        );
        final requeuedParent = (await ConversationJob.db.findById(
          fixture.database,
          parentJob.id!,
        ))!;
        expect(requeuedParent.status, ConversationJobStatuses.cancelled);
        expect(requeuedParent.attempt, parentJob.attempt);

        expect(
          await worker.runOnce(
            fixture.database,
            workerId: 'revoked-non-turn-worker',
          ),
          isTrue,
        );
        expect(
          await worker.runOnce(
            fixture.database,
            workerId: 'revoked-non-turn-worker',
          ),
          isFalse,
        );

        for (final job in nonTurnJobs) {
          final cancelled = (await ConversationJob.db.findById(
            fixture.database,
            job.id!,
          ))!;
          expect(cancelled.status, ConversationJobStatuses.cancelled);
          expect(cancelled.attempt, 0);
          expect(cancelled.leaseOwner, isNull);
          expect(cancelled.leaseToken, isNull);
          expect(cancelled.leaseExpiresAt, isNull);
        }
        final terminalParentJob = (await ConversationJob.db.findById(
          fixture.database,
          parentJob.id!,
        ))!;
        final terminalTurn = (await ConversationTurn.db.findById(
          fixture.database,
          turn.id!,
        ))!;
        expect(terminalParentJob.status, ConversationJobStatuses.cancelled);
        expect(terminalParentJob.attempt, parentJob.attempt);
        expect(terminalTurn.status, ConversationStatuses.cancelled);
        expect(host.calls, 0);
        expect(host.compactionCalls, 0);
      },
    );

    test(
      'revoked member waiting parent and child turns both reach cleanup',
      () async {
        final fixture = await prepareExecution();
        final parentTurn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        ))!;
        final parentJob = (await ConversationJob.db.findFirstRow(
          fixture.database,
          where: (table) => table.turnId.equals(parentTurn.id),
        ))!;
        await ConversationJob.db.updateRow(
          fixture.database,
          parentJob.copyWith(
            status: ConversationJobStatuses.waitingForSubAgents,
          ),
        );
        await ConversationTurn.db.updateRow(
          fixture.database,
          parentTurn.copyWith(status: ConversationStatuses.running),
        );
        final now = DateTime.now().toUtc();
        final existingJobs = await ConversationJob.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        );
        for (final existingJob in existingJobs) {
          if (existingJob.id == parentJob.id) continue;
          await ConversationJob.db.updateRow(
            fixture.database,
            existingJob.copyWith(status: ConversationJobStatuses.completed),
          );
        }
        final childUser = await ConversationMessage.db.insertRow(
          fixture.database,
          ConversationMessage(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            stableId: 'revoked-child-user-${fixture.userId}',
            role: 'user',
            kind: 'text',
            status: 'sent',
            content: 'Synthetic child turn.',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final childAssistant = await ConversationMessage.db.insertRow(
          fixture.database,
          ConversationMessage(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            stableId: 'revoked-child-assistant-${fixture.userId}',
            role: 'assistant',
            kind: 'text',
            status: ConversationStatuses.running,
            content: 'Existing partial answer.',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final childTurn = await ConversationTurn.db.insertRow(
          fixture.database,
          ConversationTurn(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            requestId: 'revoked-child-request-${fixture.userId}',
            requestHash: '{}',
            initiatorUserId: fixture.userId,
            userMessageId: childUser.id,
            assistantMessageId: childAssistant.id,
            status: ConversationStatuses.running,
            revision: 1,
            acceptedSequence: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ConversationMessage.db.updateRow(
          fixture.database,
          childUser.copyWith(turnId: childTurn.id),
        );
        await ConversationMessage.db.updateRow(
          fixture.database,
          childAssistant.copyWith(turnId: childTurn.id),
        );
        final childJob = await ConversationJob.db.insertRow(
          fixture.database,
          ConversationJob(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            turnId: childTurn.id,
            requestId: childTurn.requestId,
            kind: ConversationJobKinds.turn,
            status: ConversationJobStatuses.queued,
            payloadJson: jsonEncode({
              'actorUserId': fixture.userId,
              'parentTurnId': parentTurn.id,
            }),
            attempt: 0,
            maxAttempts: 3,
            availableAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final member = (await WorkspaceMember.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.userId.equals(fixture.userId),
        ))!;
        await WorkspaceMember.db.updateRow(
          fixture.database,
          member.copyWith(removedAt: now),
        );

        final host = _CountingCompletingHost();
        final worker = ConversationWorker(host: host);
        expect(
          await worker.runOnce(
            fixture.database,
            workerId: 'revoked-child-turn-${fixture.userId}',
          ),
          isTrue,
        );
        final cleanedParent = (await ConversationJob.db.findById(
          fixture.database,
          parentJob.id!,
        ))!;
        expect(cleanedParent.status, ConversationJobStatuses.cancelled);
        expect(
          (await ConversationTurn.db.findById(
            fixture.database,
            parentTurn.id!,
          ))!.status,
          ConversationStatuses.cancelled,
        );
        expect(host.calls, 0);

        expect(
          await worker.runOnce(
            fixture.database,
            workerId: 'revoked-child-turn-${fixture.userId}',
          ),
          isTrue,
        );
        final cleanedChildJob = (await ConversationJob.db.findById(
          fixture.database,
          childJob.id!,
        ))!;
        final cleanedChildTurn = (await ConversationTurn.db.findById(
          fixture.database,
          childTurn.id!,
        ))!;
        expect(cleanedChildJob.status, ConversationJobStatuses.completed);
        expect(cleanedChildJob.attempt, 0);
        expect(cleanedChildTurn.status, ConversationStatuses.cancelled);
        expect(
          (await ConversationTurn.db.findById(
            fixture.database,
            parentTurn.id!,
          ))!.status,
          ConversationStatuses.cancelled,
        );
        expect(
          await worker.runOnce(
            fixture.database,
            workerId: 'revoked-child-turn-${fixture.userId}',
          ),
          isFalse,
        );
        expect(host.calls, 0);
      },
    );

    test(
      'deleted account child turn is cleaned before its waiting parent',
      () async {
        final fixture = await prepareExecution();
        final parentTurn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        ))!;
        final parentJob = (await ConversationJob.db.findFirstRow(
          fixture.database,
          where: (table) => table.turnId.equals(parentTurn.id),
        ))!;
        await ConversationJob.db.updateRow(
          fixture.database,
          parentJob.copyWith(
            status: ConversationJobStatuses.waitingForSubAgents,
          ),
        );
        await ConversationTurn.db.updateRow(
          fixture.database,
          parentTurn.copyWith(status: ConversationStatuses.running),
        );
        final now = DateTime.now().toUtc();
        final existingJobs = await ConversationJob.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        );
        for (final existingJob in existingJobs) {
          if (existingJob.id == parentJob.id) continue;
          await ConversationJob.db.updateRow(
            fixture.database,
            existingJob.copyWith(status: ConversationJobStatuses.completed),
          );
        }
        final childUserId = const Uuid().v4().toString();
        await AuthUser.db.insertRow(
          fixture.database,
          AuthUser(id: UuidValue.fromString(childUserId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          fixture.database,
          EmailAccount(
            authUserId: UuidValue.fromString(childUserId),
            email: '$childUserId@example.com',
            passwordHash: 'unused',
          ),
        );
        await WorkspaceMember.db.insertRow(
          fixture.database,
          WorkspaceMember(
            workspaceId: fixture.workspaceId,
            userId: childUserId,
            role: WorkspaceRoles.member,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final childAssistant = await ConversationMessage.db.insertRow(
          fixture.database,
          ConversationMessage(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            stableId: 'erased-child-assistant-${fixture.userId}',
            role: 'assistant',
            kind: 'text',
            status: ConversationStatuses.running,
            content: 'Preserved child response.',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final childTurn = await ConversationTurn.db.insertRow(
          fixture.database,
          ConversationTurn(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            requestId: 'erased-child-request-${fixture.userId}',
            requestHash: '{}',
            initiatorUserId: childUserId,
            assistantMessageId: childAssistant.id,
            status: ConversationStatuses.running,
            revision: 1,
            acceptedSequence: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ConversationMessage.db.updateRow(
          fixture.database,
          childAssistant.copyWith(turnId: childTurn.id),
        );
        final childJob = await ConversationJob.db.insertRow(
          fixture.database,
          ConversationJob(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            turnId: childTurn.id,
            requestId: childTurn.requestId,
            kind: ConversationJobKinds.turn,
            status: ConversationJobStatuses.queued,
            payloadJson: jsonEncode({
              'actorUserId': childUserId,
              'parentTurnId': parentTurn.id,
            }),
            attempt: 0,
            maxAttempts: 3,
            availableAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        initializeTestAuthServices(fixture.database.serverpod);
        final childSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            childUserId,
            const {},
          ),
        );
        await endpoints.account.deleteCurrentUser(childSession);

        final host = _CountingCompletingHost();
        final worker = ConversationWorker(host: host);
        expect(
          await worker.runOnce(
            fixture.database,
            workerId: 'erased-child-turn-${fixture.userId}',
          ),
          isTrue,
        );
        final cancelledChildJob = (await ConversationJob.db.findById(
          fixture.database,
          childJob.id!,
        ))!;
        final cancelledChildTurn = (await ConversationTurn.db.findById(
          fixture.database,
          childTurn.id!,
        ))!;
        final preservedChildAssistant = (await ConversationMessage.db.findById(
          fixture.database,
          childAssistant.id!,
        ))!;
        expect(cancelledChildJob.status, ConversationJobStatuses.cancelled);
        expect(cancelledChildJob.attempt, 0);
        expect(cancelledChildTurn.status, ConversationStatuses.cancelled);
        expect(preservedChildAssistant.status, ConversationStatuses.cancelled);
        expect(preservedChildAssistant.content, childAssistant.content);
        expect(
          (await ConversationJob.db.findById(
            fixture.database,
            parentJob.id!,
          ))!.status,
          ConversationJobStatuses.queued,
        );
        expect(host.calls, 0);
      },
    );

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

    test('compact wakes a live dispatcher after its durable commit', () async {
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
      final useCases = ConversationUseCases(
        conversation_repo.ConversationRepository(),
        publishConversationJob: (session, job) async {
          final persisted = await ConversationJob.db.findById(session, job.id!);
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

      final currentConversation = (await Conversation.db.findById(
        fixture.database,
        fixture.conversationDatabaseId,
      ))!;
      await endpoints.conversation.queueConversationMessage(
        fixture.session,
        QueueConversationMessageRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'queue-during-compaction',
          conversationId: fixture.conversationId,
          expectedProjectionRevision: currentConversation.projectionRevision,
          clientMessageId: 'message-after-compaction',
          content: 'Continue after compaction',
          attachmentIds: const [],
        ),
      );
      active = true;
      wakes.add(null);

      await host.compactionStarted.future.timeout(const Duration(seconds: 2));
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

      final continuedMessage = await ConversationMessage.db.findFirstRow(
        fixture.database,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.stableId.equals('message-after-compaction'),
      );
      expect(continuedMessage, isNotNull);
      final followUpTurn = await ConversationTurn.db.findFirstRow(
        fixture.database,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.userMessageId.equals(continuedMessage!.id),
      );

      expect(host.compactionCalls, 1);
      expect(host.calls, 1);
      expect(job!.status, 'completed');
      expect(summary!.content, 'Compacted');
      expect(followUpTurn!.status, ConversationStatuses.completed);
    });

    test('worker does not dispatch compaction for a pending erasure', () async {
      final fixture = await prepareExecution(continueConversation: false);
      final now = DateTime.now().toUtc();
      final source = await ConversationMessage.db.insertRow(
        fixture.database,
        ConversationMessage(
          workspaceId: fixture.workspaceId,
          conversationId: fixture.conversationDatabaseId,
          stableId: 'erasure-source-message',
          role: 'user',
          kind: 'text',
          status: 'sent',
          content: 'Source',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await ConversationUseCases(
        conversation_repo.ConversationRepository(),
        publishConversationJob: (_, _) async {},
      ).compact(
        fixture.database,
        userId: fixture.userId,
        request: CompactConversationRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'erasure-compact',
          conversationId: fixture.conversationId,
          expectedConversationRevision: 1,
        ),
      );
      final workspace = (await CloudWorkspace.db.findById(
        fixture.database,
        fixture.workspaceId,
      ))!;
      await CloudWorkspace.db.updateRow(
        fixture.database,
        workspace.copyWith(erasureRequestedAt: DateTime.now().toUtc()),
      );

      final host = _CountingCompletingHost(compactionMessageId: source.id!);
      await runConversationWorker(
        fixture.database,
        isActive: () => true,
        worker: ConversationWorker(host: host),
      );

      expect(host.compactionCalls, 0);
      expect(
        await ConversationMessage.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.stableId.equals('erasure-compact:compaction-summary'),
        ),
        isNull,
      );
      expect(
        (await ConversationJob.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.requestId.equals('erasure-compact'),
        ))!.status,
        ConversationJobStatuses.queued,
      );
    });

    test(
      'account deletion terminalizes exhausted turn without changing content',
      () async {
        final fixture = await prepareExecution();
        final job = (await ConversationJob.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.conversationId.equals(fixture.conversationDatabaseId),
        ))!;
        final turn = (await ConversationTurn.db.findById(
          fixture.database,
          job.turnId!,
        ))!;
        final userMessage = (await ConversationMessage.db.findById(
          fixture.database,
          turn.userMessageId!,
        ))!;
        final assistantMessage = (await ConversationMessage.db.findById(
          fixture.database,
          turn.assistantMessageId!,
        ))!;
        await ConversationJob.db.updateRow(
          fixture.database,
          job.copyWith(attempt: job.maxAttempts),
        );
        await deleteFixtureAccount(fixture);
        final eventsBeforeClaim = await ConversationEvent.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        );

        final host = _CountingCompletingHost();
        final didWork = await ConversationWorker(host: host).runOnce(
          fixture.database,
          workerId: 'erased-retry-exhaustion-worker',
        );

        final jobAfterClaim = (await ConversationJob.db.findById(
          fixture.database,
          job.id!,
        ))!;
        final turnAfterClaim = (await ConversationTurn.db.findById(
          fixture.database,
          turn.id!,
        ))!;
        final userAfterClaim = (await ConversationMessage.db.findById(
          fixture.database,
          userMessage.id!,
        ))!;
        final assistantAfterClaim = (await ConversationMessage.db.findById(
          fixture.database,
          assistantMessage.id!,
        ))!;
        final eventsAfterClaim = await ConversationEvent.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        );

        expect(didWork, isTrue);
        expect(host.calls, 0);
        expect(jobAfterClaim.status, ConversationJobStatuses.cancelled);
        expect(jobAfterClaim.attempt, job.maxAttempts);
        expect(jobAfterClaim.leaseOwner, isNull);
        expect(jobAfterClaim.leaseToken, isNull);
        expect(jobAfterClaim.leaseExpiresAt, isNull);
        expect(jobAfterClaim.lastErrorCode, isNull);
        expect(turnAfterClaim.status, ConversationStatuses.cancelled);
        expect(turnAfterClaim.terminalAt, isNotNull);
        expect(userAfterClaim.status, userMessage.status);
        expect(userAfterClaim.content, userMessage.content);
        expect(assistantAfterClaim.status, ConversationStatuses.cancelled);
        expect(assistantAfterClaim.content, assistantMessage.content);
        expect(eventsAfterClaim, hasLength(eventsBeforeClaim.length + 1));
        expect(
          eventsAfterClaim.last.actorUserId,
          ConversationSystemActorIds.accountErasure,
        );
      },
    );

    test(
      'unavailable actors terminalize completed approval turns and preserve metadata',
      () async {
        for (final deleteAccount in [true, false]) {
          final fixture = await prepareExecution();
          final staged = await _stageAwaitingApproval(fixture, calls: 1);
          final assistant = (await ConversationMessage.db.findById(
            fixture.database,
            staged.turn.assistantMessageId!,
          ))!;
          const existingMetadata = {
            'a2uiMessages': [
              {'surfaceId': 'surface-1', 'component': 'Text'},
            ],
            'modelMetadata': {'modelId': 'model-1'},
          };
          await ConversationMessage.db.updateRow(
            fixture.database,
            assistant.copyWith(metadataJson: jsonEncode(existingMetadata)),
          );
          if (deleteAccount) {
            await deleteFixtureAccount(fixture);
          } else {
            final member = (await WorkspaceMember.db.findFirstRow(
              fixture.database,
              where: (table) =>
                  table.workspaceId.equals(fixture.workspaceId) &
                  table.userId.equals(fixture.userId),
            ))!;
            await WorkspaceMember.db.updateRow(
              fixture.database,
              member.copyWith(removedAt: DateTime.now().toUtc()),
            );
          }

          final host = _CountingCompletingHost();
          final worker = ConversationWorker(host: host);
          expect(
            await worker.runOnce(
              fixture.database,
              workerId: 'paused-approval-cleanup-${fixture.userId}',
            ),
            isTrue,
          );

          final cleanedJob = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) => table.turnId.equals(staged.turn.id),
          ))!;
          final cleanedTurn = (await ConversationTurn.db.findById(
            fixture.database,
            staged.turn.id!,
          ))!;
          final cleanedAssistant = (await ConversationMessage.db.findById(
            fixture.database,
            staged.turn.assistantMessageId!,
          ))!;
          final cleanedApprovalCall = (await ConversationToolCall.db
              .findFirstRow(
                fixture.database,
                where: (table) =>
                    table.workspaceId.equals(fixture.workspaceId) &
                    table.stableId.equals('tool-call-1'),
              ))!;
          final metadata = jsonDecode(cleanedAssistant.metadataJson!) as Map;
          expect(cleanedJob.status, ConversationJobStatuses.cancelled);
          expect(cleanedJob.attempt, 0);
          expect(cleanedTurn.status, ConversationStatuses.cancelled);
          expect(cleanedAssistant.status, ConversationStatuses.cancelled);
          expect(cleanedAssistant.content, assistant.content);
          expect(metadata['errorCode'], 'cancelled');
          expect(metadata['a2uiMessages'], existingMetadata['a2uiMessages']);
          expect(metadata['modelMetadata'], existingMetadata['modelMetadata']);
          expect(cleanedApprovalCall.status, 'cancelled');
          expect(cleanedApprovalCall.decision, 'deny');
          expect(cleanedApprovalCall.decisionByUserId, isNull);
          expect(cleanedApprovalCall.decisionAt, isNotNull);
          expect(host.calls, 0);
          expect(
            (await ConversationEvent.db.findFirstRow(
              fixture.database,
              where: (table) =>
                  table.workspaceId.equals(fixture.workspaceId) &
                  table.conversationId.equals(fixture.conversationDatabaseId) &
                  table.requestId.equals(staged.turn.requestId) &
                  table.kind.equals(ConversationEventType.executionStopped),
            ))!.actorUserId,
            deleteAccount
                ? ConversationSystemActorIds.accountErasure
                : ConversationSystemActorIds.unavailableMembershipCleanup,
          );
          expect(
            await worker.runOnce(
              fixture.database,
              workerId: 'paused-approval-cleanup-${fixture.userId}',
            ),
            isFalse,
          );
        }
      },
    );

    test('unavailable actor cleanup finds waiting parent turns', () async {
      final fixture = await prepareExecution();
      final job = (await ConversationJob.db.findFirstRow(
        fixture.database,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.conversationId.equals(fixture.conversationDatabaseId),
      ))!;
      final turn = (await ConversationTurn.db.findById(
        fixture.database,
        job.turnId!,
      ))!;
      await ConversationJob.db.updateRow(
        fixture.database,
        job.copyWith(status: ConversationJobStatuses.waitingForSubAgents),
      );
      await ConversationTurn.db.updateRow(
        fixture.database,
        turn.copyWith(status: ConversationStatuses.running),
      );
      final member = (await WorkspaceMember.db.findFirstRow(
        fixture.database,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.userId.equals(fixture.userId),
      ))!;
      await WorkspaceMember.db.updateRow(
        fixture.database,
        member.copyWith(removedAt: DateTime.now().toUtc()),
      );

      final host = _CountingCompletingHost();
      final worker = ConversationWorker(host: host);
      expect(
        await worker.runOnce(
          fixture.database,
          workerId: 'paused-parent-cleanup-${fixture.userId}',
        ),
        isTrue,
      );
      expect(
        (await ConversationJob.db.findById(fixture.database, job.id!))!.status,
        ConversationJobStatuses.cancelled,
      );
      expect(
        (await ConversationTurn.db.findById(
          fixture.database,
          turn.id!,
        ))!.status,
        ConversationStatuses.cancelled,
      );
      expect(host.calls, 0);
      expect(
        await worker.runOnce(
          fixture.database,
          workerId: 'paused-parent-cleanup-${fixture.userId}',
        ),
        isFalse,
      );
    });

    test('claim exhausts all jobs across a changing candidate page', () async {
      final fixture = await prepareExecution();
      final now = DateTime.now().toUtc();
      final jobIds = <int>[];
      await fixture.database.db.transaction((transaction) async {
        final existingJobs = await ConversationJob.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
          transaction: transaction,
        );
        for (final job in existingJobs) {
          await ConversationJob.db.updateRow(
            fixture.database,
            job.copyWith(
              status: ConversationJobStatuses.completed,
              updatedAt: now,
            ),
            transaction: transaction,
          );
        }
        for (var index = 0; index < 101; index++) {
          final job = await ConversationJob.db.insertRow(
            fixture.database,
            ConversationJob(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationDatabaseId,
              requestId: 'exhausted-page-$index',
              kind: ConversationJobKinds.compact,
              payloadJson: jsonEncode({'actorUserId': fixture.userId}),
              status: ConversationJobStatuses.queued,
              attempt: 1,
              maxAttempts: 1,
              availableAt: now,
              createdAt: now,
              updatedAt: now,
            ),
            transaction: transaction,
          );
          jobIds.add(job.id!);
        }
      });

      final leases = ConversationJobLeases();
      for (var index = 0; index < 101; index++) {
        final claimed = await leases.claim(
          fixture.database,
          workerId: 'exhaustion-page-worker',
          leaseToken: const Uuid().v4().toString(),
          now: now,
        );
        expect(claimed?.status, ConversationJobStatuses.failed);
      }
      final claimed = await leases.claim(
        fixture.database,
        workerId: 'exhaustion-page-worker',
        leaseToken: const Uuid().v4().toString(),
        now: now,
      );
      final jobs = await ConversationJob.db.find(
        fixture.database,
        where: (table) => table.id.inSet(jobIds.toSet()),
      );

      expect(claimed, isNull);
      expect(jobs, hasLength(101));
      expect(
        jobs.every((job) => job.status == ConversationJobStatuses.failed),
        isTrue,
      );
    });

    test(
      'pending erasure prevents waiting sub-agent reconciliation writes',
      () async {
        final fixture = await prepareExecution();
        final job = (await ConversationJob.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.conversationId.equals(fixture.conversationDatabaseId),
        ))!;
        final turn = (await ConversationTurn.db.findById(
          fixture.database,
          job.turnId!,
        ))!;
        final assistantMessage = (await ConversationMessage.db.findById(
          fixture.database,
          turn.assistantMessageId!,
        ))!;
        final now = DateTime.now().toUtc();
        final call = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            turnId: turn.id!,
            messageId: assistantMessage.id!,
            stableId: 'erasure-waiting-sub-agent-call',
            name: 'run-sub-agent',
            argumentsJson: '{}',
            argumentsDigest: 'erasure-waiting-sub-agent-digest',
            status: 'awaitingSubAgents',
            resultJson: '{}',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ConversationJob.db.updateRow(
          fixture.database,
          job.copyWith(status: ConversationJobStatuses.waitingForSubAgents),
        );
        final workspace = (await CloudWorkspace.db.findById(
          fixture.database,
          fixture.workspaceId,
        ))!;
        await CloudWorkspace.db.updateRow(
          fixture.database,
          workspace.copyWith(erasureRequestedAt: now),
        );
        final eventsBeforeReconcile = await ConversationEvent.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        );

        final didWork = await ConversationWorker(
          host: _CountingCompletingHost(),
        ).runOnce(fixture.database, workerId: 'erasure-reconcile-worker');

        final callAfterReconcile = (await ConversationToolCall.db.findById(
          fixture.database,
          call.id!,
        ))!;
        final jobAfterReconcile = (await ConversationJob.db.findById(
          fixture.database,
          job.id!,
        ))!;
        final turnAfterReconcile = (await ConversationTurn.db.findById(
          fixture.database,
          turn.id!,
        ))!;
        final eventsAfterReconcile = await ConversationEvent.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        );

        expect(didWork, isFalse);
        expect(callAfterReconcile.status, call.status);
        expect(callAfterReconcile.resultJson, call.resultJson);
        expect(
          jobAfterReconcile.status,
          ConversationJobStatuses.waitingForSubAgents,
        );
        expect(turnAfterReconcile.status, turn.status);
        expect(eventsAfterReconcile, hasLength(eventsBeforeReconcile.length));
      },
    );

    test(
      'detached sub-agent completion after account deletion writes no result',
      () async {
        final fixture = await prepareExecution();
        final turn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.initiatorUserId.equals(fixture.userId),
        ))!;
        final assistantMessage = (await ConversationMessage.db.findById(
          fixture.database,
          turn.assistantMessageId!,
        ))!;
        final now = DateTime.now().toUtc();
        const workId = 'deleted-account-detached-work';
        final call = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            turnId: turn.id!,
            messageId: assistantMessage.id!,
            stableId: 'deleted-account-detached-call',
            name: 'run-sub-agent',
            argumentsJson: '{}',
            argumentsDigest: 'deleted-account-detached-digest',
            backgroundEligible: true,
            backgroundWorkStableId: workId,
            status: 'runningInBackground',
            resultJson: jsonEncode({'status': 'running_in_background'}),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final work = await BackgroundWorkRecord.db.insertRow(
          fixture.database,
          BackgroundWorkRecord(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            conversationToolCallId: call.id!,
            originatingMessageId: assistantMessage.id!,
            stableId: workId,
            toolCallId: call.stableId,
            toolKind: 'skill.native',
            status: 'running',
            statusPreview: 'Running',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await deleteFixtureAccount(fixture);
        final eventsBeforeCompletion = await ConversationEvent.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        );

        await ServerToolRuntime().completeDetachedSubAgentWork(
          fixture.database,
          call: call,
          result: const {'status': 'success', 'content': 'should not persist'},
        );

        final callAfterCompletion = (await ConversationToolCall.db.findById(
          fixture.database,
          call.id!,
        ))!;
        final workAfterCompletion = (await BackgroundWorkRecord.db.findById(
          fixture.database,
          work.id!,
        ))!;
        final eventsAfterCompletion = await ConversationEvent.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationDatabaseId),
        );

        expect(callAfterCompletion.status, call.status);
        expect(callAfterCompletion.resultJson, call.resultJson);
        expect(workAfterCompletion.status, work.status);
        expect(workAfterCompletion.resultContent, isNull);
        expect(eventsAfterCompletion, hasLength(eventsBeforeCompletion.length));
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
            conversationId: fixture.conversationId,
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
        expect(assistantMessages.map((message) => message.stableId), [
          assistant.stableId,
          'approve-1:assistant',
        ]);
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

    test('stop rejects a member acting on another user execution', () async {
      final fixture = await prepareExecution();
      final memberId = const Uuid().v4().toString();
      final now = DateTime.now().toUtc();
      final memberSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          memberId,
          const {},
        ),
      );
      await AuthUser.db.insertRow(
        fixture.database,
        AuthUser(id: UuidValue.fromString(memberId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        fixture.database,
        EmailAccount(
          authUserId: UuidValue.fromString(memberId),
          email: 'stop-attacker@example.com',
          passwordHash: 'unused',
        ),
      );
      await WorkspaceMember.db.insertRow(
        fixture.database,
        WorkspaceMember(
          workspaceId: fixture.workspaceId,
          userId: memberId,
          role: WorkspaceRoles.member,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final snapshot = await endpoints.conversation.getConversationSnapshot(
        memberSession,
        GetConversationRequest(
          workspaceId: fixture.workspaceId,
          conversationId: fixture.conversationId,
        ),
      );

      await expectLater(
        endpoints.conversation.stopConversation(
          memberSession,
          StopConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'unauthorized-stop',
            conversationId: fixture.conversationId,
            expectedProjectionRevision:
                snapshot.conversation.projectionRevision,
          ),
        ),
        throwsA(
          isA<ConversationException>().having(
            (error) => error.code,
            'code',
            ConversationErrorCode.permissionDenied,
          ),
        ),
      );

      final conversation = (await Conversation.db.findById(
        fixture.database,
        fixture.conversationDatabaseId,
      ))!;
      final execution = (await ConversationExecution.db.findById(
        fixture.database,
        conversation.activeExecutionId!,
      ))!;
      expect(conversation.executionState, ConversationStatuses.running);
      expect(execution.status, ConversationStatuses.running);
    });

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
          where: (table) =>
              table.conversationId.equals(fixture.conversationDatabaseId),
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
            conversationId: fixture.conversationId,
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
      'persists classified provider failures and does not retry terminal cases',
      () async {
        for (final scenario in [
          (
            name: 'authentication',
            error: GenkitException(
              'Credentials rejected.',
              status: .unauthenticated,
            ),
            category: ProviderFailureCategory.authentication,
            retryable: false,
          ),
          (
            name: 'quota',
            error: GenkitException(
              'Quota exceeded.',
              status: .resourceExhausted,
            ),
            category: ProviderFailureCategory.quotaRateLimit,
            retryable: false,
          ),
          (
            name: 'rate limit with Retry-After',
            error: ProviderHttpFailureException(
              429,
              'Rate limit exceeded.',
              retryAfter: const Duration(seconds: 42),
            ),
            category: ProviderFailureCategory.quotaRateLimit,
            retryable: true,
          ),
          (
            name: 'transient outage',
            error: ProviderHttpFailureException(
              503,
              'Provider unavailable.',
              details: 'api_key=offline-fixture-secret',
            ),
            category: ProviderFailureCategory.transientOutage,
            retryable: true,
          ),
          (
            name: 'configuration',
            error: GenkitException(
              'Invalid model settings.',
              status: .invalidArgument,
            ),
            category: ProviderFailureCategory.configuration,
            retryable: false,
          ),
          (
            name: 'unknown text that resembles a rate limit',
            error: GenkitException(
              'HTTP 429 rate limit. Try again in one minute.',
              status: .unknown,
            ),
            category: ProviderFailureCategory.unknown,
            retryable: false,
          ),
        ]) {
          final fixture = await prepareExecution();
          final job = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.conversationId.equals(fixture.conversationDatabaseId),
          ))!;
          await ConversationJob.db.updateRow(
            fixture.database,
            job.copyWith(maxAttempts: 1),
          );
          final host = _ThrowingFailureHost(scenario.error);

          await runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: ConversationWorker(host: host),
          );

          final failedJob = await ConversationJob.db.findById(
            fixture.database,
            job.id!,
          );
          final turn = (await ConversationTurn.db.findById(
            fixture.database,
            job.turnId!,
          ))!;
          final userMessage = await ConversationMessage.db.findById(
            fixture.database,
            turn.userMessageId!,
          );
          final assistantMessage = await ConversationMessage.db.findById(
            fixture.database,
            turn.assistantMessageId!,
          );
          final userMetadata = jsonDecode(userMessage!.metadataJson!) as Map;
          final assistantMetadata =
              jsonDecode(assistantMessage!.metadataJson!) as Map;
          final userModelMetadata = userMetadata['modelMetadata'] as Map;
          final assistantModelMetadata =
              assistantMetadata['modelMetadata'] as Map;
          final userRecovery = userModelMetadata['providerRecovery'] as Map;
          final assistantRecovery =
              assistantModelMetadata['providerRecovery'] as Map;

          expect(failedJob!.status, ConversationJobStatuses.failed);
          expect(turn.status, ConversationStatuses.failed);
          expect(host.calls, 1, reason: scenario.name);
          expect(userMessage.status, 'error');
          expect(assistantMessage.status, ConversationStatuses.failed);
          expect(userModelMetadata['providerError'], isTrue);
          expect(assistantModelMetadata['providerError'], isTrue);
          expect(userRecovery['classification'], scenario.category.wireValue);
          expect(
            assistantRecovery['classification'],
            scenario.category.wireValue,
          );
          expect(userRecovery['retryable'], scenario.retryable);
          expect(assistantRecovery['retryable'], scenario.retryable);
          if (scenario.name == 'rate limit with Retry-After') {
            expect(userRecovery['retryAfterSeconds'], 42);
            expect(assistantRecovery['retryAfterSeconds'], 42);
          }
          if (scenario.category == ProviderFailureCategory.transientOutage) {
            expect(assistantMessage.content, 'api_key=[REDACTED]');
            expect(
              assistantMessage.content,
              isNot(contains('offline-fixture-secret')),
            );
          }

          await runConversationWorker(
            fixture.database,
            isActive: () => true,
            worker: ConversationWorker(host: host),
          );
          expect(host.calls, 1, reason: scenario.name);
        }
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
        final timerScheduled = Completer<void>();
        final scheduledTimers = <_ManualTimer>[];
        final worker = ConversationWorker(
          host: host,
          renewalInterval: const Duration(milliseconds: 1),
          renewalTimer: (duration, callback) {
            final timer = _ManualTimer(callback);
            scheduledTimers.add(timer);
            if (!timerScheduled.isCompleted) timerScheduled.complete();
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
        await timerScheduled.future.timeout(const Duration(seconds: 2));
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
  });

  withServerpod('ConversationExecutionState concurrent transactions', (
    sessionBuilder,
    endpoints,
  ) {
    Future<_ExecutionFixture> prepareQueuedExecution() async {
      final fixture = await _preparePromptlessExecution(sessionBuilder);
      await endpoints.conversation.queueConversationMessage(
        fixture.session,
        QueueConversationMessageRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'erasure-queue-${fixture.userId}',
          conversationId: fixture.conversationId,
          expectedProjectionRevision: 1,
          clientMessageId: 'erasure-message-${fixture.userId}',
          content: 'Synthetic prompt.',
          attachmentIds: const [],
        ),
      );
      await endpoints.conversation.continueConversation(
        fixture.session,
        ContinueConversationRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'erasure-continue-${fixture.userId}',
          conversationId: fixture.conversationId,
          expectedProjectionRevision: 2,
        ),
      );
      await ProviderAdmissionLock.db.deleteWhere(
        fixture.database,
        where: (table) => table.key.equals('global'),
      );

      return fixture;
    }

    Future<void> deleteFixtureAccount(_ExecutionFixture fixture) async {
      final newOwnerId = const Uuid().v4().toString();
      await AuthUser.db.insertRow(
        fixture.database,
        AuthUser(id: UuidValue.fromString(newOwnerId), scopeNames: const {}),
      );
      final workspace = (await CloudWorkspace.db.findById(
        fixture.database,
        fixture.workspaceId,
      ))!;
      await CloudWorkspace.db.updateRow(
        fixture.database,
        workspace.copyWith(ownerUserId: newOwnerId),
      );
      initializeTestAuthServices(fixture.database.serverpod);
      await endpoints.account.deleteCurrentUser(fixture.session);
    }

    test(
      'provider failure after account deletion or pending erasure writes no result state',
      () async {
        for (final deleteAccount in [true, false]) {
          final fixture = await prepareQueuedExecution();
          final turn = (await ConversationTurn.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId) &
                table.initiatorUserId.equals(fixture.userId),
          ))!;
          final userMessage = (await ConversationMessage.db.findById(
            fixture.database,
            turn.userMessageId!,
          ))!;
          final assistantMessage = (await ConversationMessage.db.findById(
            fixture.database,
            turn.assistantMessageId!,
          ))!;
          final now = DateTime.now().toUtc();
          final workId = 'failure-erasure-work-${fixture.userId}';
          final toolCall = await ConversationToolCall.db.insertRow(
            fixture.database,
            ConversationToolCall(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationDatabaseId,
              turnId: turn.id!,
              messageId: assistantMessage.id!,
              stableId: 'failure-erasure-call-${fixture.userId}',
              name: 'background-work',
              argumentsJson: '{}',
              argumentsDigest: 'failure-erasure-digest-${fixture.userId}',
              backgroundWorkStableId: workId,
              status: 'runningInBackground',
              resultJson: jsonEncode({'status': 'running_in_background'}),
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          await BackgroundWorkRecord.db.insertRow(
            fixture.database,
            BackgroundWorkRecord(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationDatabaseId,
              conversationToolCallId: toolCall.id!,
              originatingMessageId: userMessage.id,
              stableId: workId,
              toolCallId: toolCall.stableId,
              toolKind: 'skill.native',
              status: 'running',
              statusPreview: BackgroundWorkPreviews.queuedForContinuation,
              createdAt: now,
              updatedAt: now,
            ),
          );
          await ConversationMessage.db.updateRow(
            fixture.database,
            userMessage.copyWith(
              metadataJson: jsonEncode({
                'isBackgroundWorkCompletion': true,
                'backgroundWorkId': workId,
              }),
            ),
          );
          final job = (await ConversationJob.db.findFirstRow(
            fixture.database,
            where: (table) => table.turnId.equals(turn.id!),
          ))!;
          await ConversationJob.db.updateRow(
            fixture.database,
            job.copyWith(attempt: job.maxAttempts - 1),
          );

          final host = _FailingAfterReleaseHost();
          final worker = ConversationWorker(host: host).runOnce(
            fixture.database,
            workerId: 'erasure-failure-${fixture.userId}',
          );
          try {
            await host.started.future.timeout(const Duration(seconds: 10));
            if (deleteAccount) {
              await deleteFixtureAccount(fixture);
              expect(
                await AuthUser.db.findById(
                  fixture.database,
                  UuidValue.fromString(fixture.userId),
                ),
                isNull,
              );
            } else {
              final workspace = (await CloudWorkspace.db.findById(
                fixture.database,
                fixture.workspaceId,
              ))!;
              await CloudWorkspace.db.updateRow(
                fixture.database,
                workspace.copyWith(erasureRequestedAt: DateTime.now().toUtc()),
              );
            }

            final jobBeforeFailure = (await ConversationJob.db.findById(
              fixture.database,
              job.id!,
            ))!;
            final turnBeforeFailure = (await ConversationTurn.db.findById(
              fixture.database,
              turn.id!,
            ))!;
            final userBeforeFailure = (await ConversationMessage.db.findById(
              fixture.database,
              userMessage.id!,
            ))!;
            final assistantBeforeFailure = (await ConversationMessage.db
                .findById(
                  fixture.database,
                  assistantMessage.id!,
                ))!;
            final eventsBeforeFailure = await ConversationEvent.db.find(
              fixture.database,
              where: (table) =>
                  table.workspaceId.equals(fixture.workspaceId) &
                  table.conversationId.equals(fixture.conversationDatabaseId),
            );
            final backgroundBeforeFailure = (await BackgroundWorkRecord.db
                .findFirstRow(
                  fixture.database,
                  where: (table) =>
                      table.workspaceId.equals(fixture.workspaceId) &
                      table.stableId.equals(workId),
                ))!;

            host.release.complete();
            await worker.timeout(const Duration(seconds: 10));

            final jobAfterFailure = (await ConversationJob.db.findById(
              fixture.database,
              job.id!,
            ))!;
            final turnAfterFailure = (await ConversationTurn.db.findById(
              fixture.database,
              turn.id!,
            ))!;
            final userAfterFailure = (await ConversationMessage.db.findById(
              fixture.database,
              userMessage.id!,
            ))!;
            final assistantAfterFailure = (await ConversationMessage.db
                .findById(
                  fixture.database,
                  assistantMessage.id!,
                ))!;
            final eventsAfterFailure = await ConversationEvent.db.find(
              fixture.database,
              where: (table) =>
                  table.workspaceId.equals(fixture.workspaceId) &
                  table.conversationId.equals(fixture.conversationDatabaseId),
            );
            final backgroundAfterFailure = (await BackgroundWorkRecord.db
                .findFirstRow(
                  fixture.database,
                  where: (table) =>
                      table.workspaceId.equals(fixture.workspaceId) &
                      table.stableId.equals(workId),
                ))!;

            expect(jobAfterFailure.status, jobBeforeFailure.status);
            expect(jobAfterFailure.lastErrorCode, isNull);
            expect(turnAfterFailure.status, turnBeforeFailure.status);
            expect(userAfterFailure.status, userBeforeFailure.status);
            expect(
              assistantAfterFailure.status,
              assistantBeforeFailure.status,
            );
            expect(
              assistantAfterFailure.content,
              assistantBeforeFailure.content,
            );
            expect(eventsAfterFailure, hasLength(eventsBeforeFailure.length));
            expect(
              backgroundAfterFailure.status,
              backgroundBeforeFailure.status,
            );
            expect(
              backgroundAfterFailure.statusPreview,
              backgroundBeforeFailure.statusPreview,
            );
          } finally {
            if (!host.release.isCompleted) host.release.complete();
            await worker.timeout(const Duration(seconds: 10));
          }
        }
      },
    );

    test(
      'provider cancellation after pending erasure writes no cancellation state',
      () async {
        final fixture = await prepareQueuedExecution();
        final job = (await ConversationJob.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.conversationId.equals(fixture.conversationDatabaseId),
        ))!;
        final turn = (await ConversationTurn.db.findById(
          fixture.database,
          job.turnId!,
        ))!;
        final userMessage = (await ConversationMessage.db.findById(
          fixture.database,
          turn.userMessageId!,
        ))!;
        final assistantMessage = (await ConversationMessage.db.findById(
          fixture.database,
          turn.assistantMessageId!,
        ))!;
        final host = _FailingAfterReleaseHost(
          const ConversationCancelledException(),
        );
        final worker = ConversationWorker(host: host).runOnce(
          fixture.database,
          workerId: 'erasure-cancellation-${fixture.userId}',
        );

        try {
          await host.started.future.timeout(const Duration(seconds: 10));
          final workspace = (await CloudWorkspace.db.findById(
            fixture.database,
            fixture.workspaceId,
          ))!;
          await CloudWorkspace.db.updateRow(
            fixture.database,
            workspace.copyWith(erasureRequestedAt: DateTime.now().toUtc()),
          );
          final jobBeforeCancellation = (await ConversationJob.db.findById(
            fixture.database,
            job.id!,
          ))!;
          final turnBeforeCancellation = (await ConversationTurn.db.findById(
            fixture.database,
            turn.id!,
          ))!;
          final userBeforeCancellation = (await ConversationMessage.db.findById(
            fixture.database,
            userMessage.id!,
          ))!;
          final assistantBeforeCancellation = (await ConversationMessage.db
              .findById(
                fixture.database,
                assistantMessage.id!,
              ))!;
          final eventsBeforeCancellation = await ConversationEvent.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId),
          );

          host.release.complete();
          await worker.timeout(const Duration(seconds: 10));

          final jobAfterCancellation = (await ConversationJob.db.findById(
            fixture.database,
            job.id!,
          ))!;
          final turnAfterCancellation = (await ConversationTurn.db.findById(
            fixture.database,
            turn.id!,
          ))!;
          final userAfterCancellation = (await ConversationMessage.db.findById(
            fixture.database,
            userMessage.id!,
          ))!;
          final assistantAfterCancellation = (await ConversationMessage.db
              .findById(
                fixture.database,
                assistantMessage.id!,
              ))!;
          final eventsAfterCancellation = await ConversationEvent.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationDatabaseId),
          );

          expect(jobAfterCancellation.status, jobBeforeCancellation.status);
          expect(turnAfterCancellation.status, turnBeforeCancellation.status);
          expect(userAfterCancellation.status, userBeforeCancellation.status);
          expect(
            assistantAfterCancellation.status,
            assistantBeforeCancellation.status,
          );
          expect(
            assistantAfterCancellation.content,
            assistantBeforeCancellation.content,
          );
          expect(
            eventsAfterCancellation,
            hasLength(eventsBeforeCancellation.length),
          );
        } finally {
          if (!host.release.isCompleted) host.release.complete();
          await worker.timeout(const Duration(seconds: 10));
        }
      },
    );

    test(
      'erasure waits for compaction dispatch and compaction cannot commit later',
      () async {
        final fixture = await _preparePromptlessExecution(sessionBuilder);
        final now = DateTime.now().toUtc();
        final source = await ConversationMessage.db.insertRow(
          fixture.database,
          ConversationMessage(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationDatabaseId,
            stableId: 'dispatch-fence-source-${fixture.userId}',
            role: 'user',
            kind: 'text',
            status: 'sent',
            content: 'Source',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ConversationUseCases(
          conversation_repo.ConversationRepository(),
          publishConversationJob: (_, _) async {},
        ).compact(
          fixture.database,
          userId: fixture.userId,
          request: CompactConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'dispatch-fence-${fixture.userId}',
            conversationId: fixture.conversationId,
            expectedConversationRevision: 1,
          ),
        );
        final workspaceBeforeDispatch = (await CloudWorkspace.db.findById(
          fixture.database,
          fixture.workspaceId,
        ))!;
        final conversationBeforeDispatch = (await Conversation.db.findById(
          fixture.database,
          fixture.conversationDatabaseId,
        ))!;
        final eventsBeforeDispatch = await WorkspaceEvent.db.find(
          fixture.database,
          where: (table) => table.workspaceId.equals(fixture.workspaceId),
        );
        final dispatchTransactionHeld = Completer<void>();
        final releaseDispatchTransaction = Completer<void>();
        final host = _CountingCompletingHost(
          compactionMessageId: source.id!,
          compactionBlock: Completer<void>(),
        );
        final workerSession = fixture.session.build();
        int? workerBackendPid;
        final worker = runConversationWorker(
          workerSession,
          isActive: () => true,
          worker: ConversationWorker(
            host: host,
            afterCompactionDispatch: (session, transaction) async {
              workerBackendPid =
                  (await session.db.unsafeQuery(
                        'SELECT pg_backend_pid() AS "pid"',
                        transaction: transaction,
                      )).single.toColumnMap()['pid']
                      as int;
              dispatchTransactionHeld.complete();
              await releaseDispatchTransaction.future;
            },
          ),
        );

        await host.compactionStarted.future.timeout(const Duration(seconds: 2));
        await dispatchTransactionHeld.future.timeout(
          const Duration(seconds: 2),
        );
        final erasureSession = fixture.session.build();
        final erasureUpdate = CloudWorkspace.db.updateRow(
          erasureSession,
          workspaceBeforeDispatch.copyWith(
            erasureRequestedAt: DateTime.now().toUtc(),
          ),
        );
        final erasureWaitObserved = await _waitForWorkspaceLockWait(
          fixture.database,
          workerBackendPid: workerBackendPid!,
        );
        releaseDispatchTransaction.complete();
        await erasureUpdate;
        host.compactionBlock!.complete();
        await worker.timeout(const Duration(seconds: 5));

        expect(
          erasureWaitObserved,
          isTrue,
          reason: 'Erasure should wait on the worker-held workspace lock.',
        );
        expect(
          await ConversationMessage.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.stableId.equals(
                  'dispatch-fence-${fixture.userId}:compaction-summary',
                ),
          ),
          isNull,
        );
        final conversationAfterWorker = (await Conversation.db.findById(
          fixture.database,
          fixture.conversationDatabaseId,
        ))!;
        final workspaceAfterWorker = (await CloudWorkspace.db.findById(
          fixture.database,
          fixture.workspaceId,
        ))!;
        final eventsAfterWorker = await WorkspaceEvent.db.find(
          fixture.database,
          where: (table) => table.workspaceId.equals(fixture.workspaceId),
        );
        expect(
          conversationAfterWorker.revision,
          conversationBeforeDispatch.revision,
        );
        expect(workspaceAfterWorker.sequence, workspaceBeforeDispatch.sequence);
        expect(eventsAfterWorker, hasLength(eventsBeforeDispatch.length));
      },
    );

    test(
      'erasure fences turn dispatch, assistant checkpoints, and result commits',
      () async {
        final fixture = await _preparePromptlessExecution(sessionBuilder);
        await endpoints.conversation.queueConversationMessage(
          fixture.session,
          QueueConversationMessageRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'turn-erasure-queue-${fixture.userId}',
            conversationId: fixture.conversationId,
            expectedProjectionRevision: 1,
            clientMessageId: 'turn-erasure-message-${fixture.userId}',
            content: 'Prompt',
            attachmentIds: const [],
          ),
        );
        await endpoints.conversation.continueConversation(
          fixture.session,
          ContinueConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'turn-erasure-continue-${fixture.userId}',
            conversationId: fixture.conversationId,
            expectedProjectionRevision: 2,
          ),
        );
        await ProviderAdmissionLock.db.deleteWhere(
          fixture.database,
          where: (table) => table.key.equals('global'),
        );
        final workspace = (await CloudWorkspace.db.findById(
          fixture.database,
          fixture.workspaceId,
        ))!;
        final dispatchTransactionHeld = Completer<void>();
        final releaseDispatchTransaction = Completer<void>();
        final host = _CheckpointAfterReleaseHost();
        int? workerBackendPid;
        final worker = runConversationWorker(
          fixture.session.build(),
          isActive: () => true,
          worker: ConversationWorker(
            host: host,
            afterTurnDispatch: (session, transaction) async {
              workerBackendPid =
                  (await session.db.unsafeQuery(
                        'SELECT pg_backend_pid() AS "pid"',
                        transaction: transaction,
                      )).single.toColumnMap()['pid']
                      as int;
              dispatchTransactionHeld.complete();
              await releaseDispatchTransaction.future;
            },
          ),
        );

        await host.started.future.timeout(const Duration(seconds: 2));
        await dispatchTransactionHeld.future.timeout(
          const Duration(seconds: 2),
        );
        final erasureUpdate = CloudWorkspace.db.updateRow(
          fixture.session.build(),
          workspace.copyWith(erasureRequestedAt: DateTime.now().toUtc()),
        );
        final erasureWaitObserved = await _waitForWorkspaceLockWait(
          fixture.database,
          workerBackendPid: workerBackendPid!,
        );
        releaseDispatchTransaction.complete();
        await erasureUpdate;
        host.release.complete();
        await worker.timeout(const Duration(seconds: 5));

        final turn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.initiatorUserId.equals(fixture.userId),
        ))!;
        final assistant = (await ConversationMessage.db.findById(
          fixture.database,
          turn.assistantMessageId!,
        ))!;
        expect(erasureWaitObserved, isTrue);
        expect(assistant.content, isEmpty);
      },
    );

    test(
      'approval pause and decision submission complete without lock inversion',
      () async {
        final fixture = await _preparePromptlessExecution(sessionBuilder);
        await endpoints.conversation.continueConversation(
          fixture.session,
          ContinueConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'approval-race-continue-1',
            conversationId: fixture.conversationId,
            expectedProjectionRevision: 1,
          ),
        );
        final argumentsDigest = base64UrlEncode(
          (await Sha256().hash(utf8.encode('{}'))).bytes,
        );
        final staged = await _stageAwaitingApproval(
          fixture,
          calls: 1,
          argumentsDigest: argumentsDigest,
        );
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
        var approvalLockBarrierCalls = 0;
        int? workerBackendPid;
        final worker = ConversationWorker(
          host: _AwaitingApprovalHost(),
          afterApprovalTurnLock: (workerSession, transaction) async {
            approvalLockBarrierCalls++;
            workerBackendPid ??=
                (await workerSession.db.unsafeQuery(
                      'SELECT pg_backend_pid() AS "pid"',
                      transaction: transaction,
                    )).single.toColumnMap()['pid']
                    as int;
            if (!pauseTurnLocked.isCompleted) pauseTurnLocked.complete();
            await releasePause.future;
          },
        );

        final running = runConversationWorker(
          fixture.session.build(),
          isActive: () => true,
          worker: worker,
        );
        await pauseTurnLocked.future.timeout(const Duration(seconds: 2));
        final decisionDatabase = sessionBuilder
            .copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                fixture.userId,
                const {},
              ),
            )
            .build();
        final decision =
            ConversationUseCases(
              conversation_repo.ConversationRepository(),
              publishConversationJob: (_, _) async {},
            ).submitToolDecision(
              decisionDatabase,
              userId: fixture.userId,
              request: SubmitToolDecisionRequest(
                workspaceId: fixture.workspaceId,
                requestId: 'approve-racing-pause',
                conversationId: fixture.conversationId,
                turnId: staged.turn.requestId,
                toolCallId: staged.toolCallIds.single,
                argumentsDigest: argumentsDigest,
                expectedTurnRevision: 3,
                decision: 'approve',
              ),
            );
        final decisionWaitObserved = await _waitForAuthUserLockWait(
          fixture.database,
          workerBackendPid: workerBackendPid!,
        );
        releasePause.complete();

        final decisionResult = await decision.timeout(
          const Duration(seconds: 2),
        );
        await running.timeout(const Duration(seconds: 2));
        expect(
          decisionWaitObserved,
          isTrue,
          reason: 'The decision should wait on the worker-held AuthUser lock.',
        );
        expect(decisionResult.status, ConversationStatuses.queued);

        await runConversationWorker(
          fixture.session.build(),
          isActive: () => true,
          worker: worker,
        );
        expect(
          approvalLockBarrierCalls,
          greaterThan(1),
          reason:
              'The worker should re-enter this barrier for the continuation.',
        );
      },
    );

    test(
      'concurrent Continue requests from independent sessions replay once',
      () async {
        final fixture = await _preparePromptlessExecution(sessionBuilder);
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

        final host = _CountingCompletingHost();
        try {
          final snapshots = await Future.wait([
            endpoints.conversation.continueConversation(firstSession, request),
            endpoints.conversation.continueConversation(secondSession, request),
          ]);
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
            worker: ConversationWorker(host: host),
          );
          await _waitForIdle(fixture, endpoints);
          expect(host.calls, 1);
        }
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
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

Future<bool> _waitForAuthUserLockWait(
  Session session, {
  required int workerBackendPid,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(deadline)) {
    final rows = await session.db.unsafeQuery(
      '''
      SELECT EXISTS (
        SELECT 1
        FROM pg_stat_activity
        WHERE datname = current_database()
          AND pid <> pg_backend_pid()
          AND @workerBackendPid = ANY(pg_blocking_pids(pid))
          AND wait_event_type = 'Lock'
          AND state = 'active'
      ) AS "waiting"
    ''',
      parameters: QueryParameters.named({'workerBackendPid': workerBackendPid}),
    );
    if (rows.single.toColumnMap()['waiting'] as bool) return true;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  return false;
}

Future<bool> _waitForWorkspaceLockWait(
  Session session, {
  required int workerBackendPid,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(deadline)) {
    final rows = await session.db.unsafeQuery(
      '''
      SELECT EXISTS (
        SELECT 1
        FROM pg_stat_activity
        WHERE datname = current_database()
          AND pid <> pg_backend_pid()
          AND @workerBackendPid = ANY(pg_blocking_pids(pid))
          AND wait_event_type = 'Lock'
          AND state = 'active'
          AND query ILIKE '%workspace%'
      ) AS "waiting"
    ''',
      parameters: QueryParameters.named({'workerBackendPid': workerBackendPid}),
    );
    if (rows.single.toColumnMap()['waiting'] as bool) return true;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  return false;
}

Future<({ConversationTurn turn, List<String> toolCallIds})>
_stageAwaitingApproval(
  _ExecutionFixture fixture, {
  required int calls,
  String? argumentsDigest,
}) async {
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
        table.conversationId.equals(fixture.conversationDatabaseId) &
        table.requestId.equals(execution.stableId),
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
        argumentsDigest: argumentsDigest ?? 'digest-${index + 1}',
        status: 'pending',
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
  return (turn: turn, toolCallIds: toolCallIds);
}

Future<void> _waitForIdle(_ExecutionFixture fixture, dynamic endpoints) async {
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

class const _ExecutionFixture({
  required final dynamic session,
  required final Session database,
  required final String userId,
  required final int workspaceId,
  required final int conversationDatabaseId,
  required final String conversationId,
});

class _CountingCompletingHost({
  final Completer<void>? block,
  final Completer<void>? compactionBlock,
  final int? compactionMessageId,
}) implements ConversationEngineHost {
  final started = Completer<void>();
  final compactionStarted = Completer<void>();
  final languageCodes = <String>[];
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
    languageCodes.add(
      conversation_repo.conversationLanguageCodeForJob(job.payloadJson) ?? 'en',
    );
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
    await compactionBlock?.future;
    final messageId = compactionMessageId;
    if (messageId == null) {
      throw StateError('No compaction message configured.');
    }
    return ConversationCompactionResult(
      summary: 'Compacted',
      providerId: 'test-provider',
      modelId: 'test-model',
      range: AgentCompactionRangeSelected(
        fromMessageId: '$messageId',
        throughMessageId: '$messageId',
        messageIds: ['$messageId'],
        keptTailMessageIds: const [],
      ),
    );
  }
}

class _CheckpointAfterReleaseHost extends _CountingCompletingHost {
  final release = Completer<void>();

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
    await release.future;
    await liveTurns.text('after erasure');
    await liveTurns.flush();
    return const ConversationEngineResult(
      content: 'after erasure',
      finishReason: 'stop',
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
    );
  }
}

class _FailingAfterReleaseHost extends _CountingCompletingHost {
  _FailingAfterReleaseHost([
    this.failure = const ConversationEngineConfigurationException(
      'synthetic_failure',
    ),
  ]);

  final Object failure;
  final release = Completer<void>();

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
    await release.future;
    throw failure;
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

class _ThrowingFailureHost extends _CountingCompletingHost {
  _ThrowingFailureHost(this.failure);

  final Object failure;

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
    throw failure;
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
    if (calls == 1) {
      throw const ProviderTransientFailureException('offline retry fixture');
    }
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
    await Future.any([_release.future, ?abort]);
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

class _ManualTimer(final void Function() _callback) implements Timer {
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
