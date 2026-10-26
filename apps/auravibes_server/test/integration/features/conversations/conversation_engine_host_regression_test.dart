import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_engine_host.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/conversations/repositories/conversation_repository.dart'
    as conversation_repo;
import 'package:auravibes_server/src/features/conversations/usecases/conversation_usecases.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_worker.dart';
import 'package:auravibes_server/src/features/model_connections/domain/virtual_workspace_model_selection.dart';
import 'package:auravibes_server/src/features/workspace_state/domain/workspace_resource_validation.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_secret_cipher.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

Future<_Fixture> _prepareConversationFixture(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints, {
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
  await endpoints.conversation.queueConversationMessage(
    session,
    QueueConversationMessageRequest(
      workspaceId: workspace.id!,
      requestId: 'queue-1',
      conversationId: conversation.stableId,
      expectedProjectionRevision: 1,
      clientMessageId: 'message-1',
      content: 'Continue.',
      attachmentIds: const [],
      languageCode: languageCode,
    ),
  );
  await endpoints.conversation.continueConversation(
    session,
    ContinueConversationRequest(
      workspaceId: workspace.id!,
      requestId: 'continue-1',
      conversationId: conversation.stableId,
      expectedProjectionRevision: 2,
      languageCode: languageCode,
    ),
  );
  final turn = (await ConversationTurn.db.findFirstRow(
    database,
    where: (table) =>
        table.workspaceId.equals(workspace.id) &
        table.conversationId.equals(conversation.id),
  ))!;
  final job = (await ConversationJob.db.findFirstRow(
    database,
    where: (table) => table.turnId.equals(turn.id),
  ))!;
  final messages = await ConversationMessage.db.find(
    database,
    where: (table) => table.conversationId.equals(conversation.id),
    orderBy: (table) => table.id,
  );
  return _Fixture(
    session: session,
    database: database,
    userId: userId,
    workspaceId: workspace.id!,
    conversationId: conversation.id!,
    turn: turn,
    job: job,
    messages: messages,
  );
}

void main() {
  withServerpod('ConversationEngineHostRegression', (
    sessionBuilder,
    endpoints,
  ) {
    Future<_Fixture> prepare({String? languageCode}) =>
        _prepareConversationFixture(
          sessionBuilder,
          endpoints,
          languageCode: languageCode,
        );

    test('Connector writes require Default approval and durable uncertainty prevents duplicate effects', () async {
      final fixture = await prepare();
      final assistant = fixture.messages.singleWhere(
        (message) => message.id == fixture.turn.assistantMessageId,
      );
      final now = DateTime.now().toUtc();
      final target = await WorkspaceResource.db.insertRow(
        fixture.database,
        WorkspaceResource(
          workspaceId: fixture.workspaceId,
          resourceKind: .tool,
          resourceId: 'connector/duckduckgo/search',
          data: jsonEncode({
            'toolId': 'connector/duckduckgo/search',
            'isEnabled': true,
            'permissionMode': 'alwaysAllow',
          }),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await WorkspaceResource.db.insertRow(
        fixture.database,
        WorkspaceResource(
          workspaceId: fixture.workspaceId,
          resourceKind: .toolPermission,
          resourceId: 'command-allow',
          data: jsonEncode({
            'toolId': executeConnectorToolName,
            'isEnabled': true,
            'permissionMode': 'alwaysAllow',
          }),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      var effects = 0;
      var loseResponse = true;
      var statusCode = 201;
      ServerToolRuntime runtime() => ServerToolRuntime(
        executor: ServerToolExecutorService(
          connectorHttpClient: (_) {
            effects++;
            if (loseResponse) {
              return CancelableOperation.fromFuture(
                Future<UrlResponse>.error(
                  TimeoutException('synthetic-provider-secret'),
                ),
              );
            }
            return CancelableOperation.fromFuture(
              Future.value(
                UrlResponse(
                  statusCode: statusCode,
                  body: 'deterministic response',
                  headers: const {},
                  elapsed: Duration.zero,
                ),
              ),
            );
          },
        ).call,
      );
      Future<ServerToolDisposition> run(
        String id, {
        String query = 'write fixture',
        String? operationId,
      }) => runtime().handle(
        fixture.database,
        turn: fixture.turn,
        messageId: assistant.id!,
        request: ServerToolRequest(
          id: id,
          name: executeConnectorToolName,
          arguments: {
            'toolId': 'connector/duckduckgo/search',
            'args': {'query': query},
            'operationId': ?operationId,
          },
        ),
      );
      expect(
        await run('default-preview'),
        ServerToolDisposition.awaitingApproval,
      );
      expect(effects, 0);
      final conversation = await Conversation.db.findById(
        fixture.database,
        fixture.conversationId,
      );
      await Conversation.db.updateRow(
        fixture.database,
        conversation!.copyWith(toolAccessMode: 'allow_all'),
      );
      expect(await run('write-1'), ServerToolDisposition.completed);
      expect(effects, 1);
      expect(await run('retry-new-runtime'), ServerToolDisposition.completed);
      expect(effects, 1);
      final snapshot = await endpoints.conversation.getConversationSnapshot(
        fixture.session,
        GetConversationRequest(
          workspaceId: fixture.workspaceId,
          conversationId: 'conversation-1',
        ),
      );
      final results = snapshot.toolCalls
          .where(
            (call) => call.id == 'write-1' || call.id == 'retry-new-runtime',
          )
          .toList();
      expect(results, hasLength(2));
      for (final result in results) {
        expect(result.status, 'uncertain');
        expect(result.resultJson, contains('"operationId":"write-1"'));
        expect(result.resultJson, contains('"retryBlocked":true'));
        expect(result.resultJson, isNot(contains('synthetic-provider-secret')));
      }
      loseResponse = false;
      expect(
        await run('write-completed', query: 'intentional new action'),
        ServerToolDisposition.completed,
      );
      expect(
        await run(
          'replay-completed',
          query: 'intentional new action',
          operationId: 'write-completed',
        ),
        ServerToolDisposition.completed,
      );
      expect(effects, 2);
      statusCode = 422;
      expect(
        await run('write-rejected', query: 'invalid action'),
        ServerToolDisposition.completed,
      );
      expect(
        await run(
          'replay-rejected',
          query: 'invalid action',
          operationId: 'write-rejected',
        ),
        ServerToolDisposition.completed,
      );
      expect(effects, 3);
      final outcomes = await endpoints.conversation.getConversationSnapshot(
        fixture.session,
        GetConversationRequest(
          workspaceId: fixture.workspaceId,
          conversationId: 'conversation-1',
        ),
      );
      expect(
        outcomes.toolCalls
            .singleWhere((call) => call.id == 'replay-completed')
            .resultJson,
        contains('"statusCode":201'),
      );
      expect(
        outcomes.toolCalls
            .singleWhere((call) => call.id == 'replay-rejected')
            .status,
        'executionError',
      );
      expect(
        outcomes.toolCalls
            .singleWhere((call) => call.id == 'replay-rejected')
            .resultJson,
        contains('"statusCode":422'),
      );
      final interrupted = await ConversationToolCall.db.findFirstRow(
        fixture.database,
        where: (row) =>
            row.workspaceId.equals(fixture.workspaceId) &
            row.stableId.equals('replay-completed'),
      );
      await ConversationToolCall.db.updateRow(
        fixture.database,
        interrupted!.copyWith(
          status: 'running',
          updatedAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        ),
      );
      await run(
        'replay-completed',
        query: 'intentional new action',
        operationId: 'write-completed',
      );
      final recovered = await endpoints.conversation.getConversationSnapshot(
        fixture.session,
        GetConversationRequest(
          workspaceId: fixture.workspaceId,
          conversationId: 'conversation-1',
        ),
      );
      final recoveredCall = recovered.toolCalls.singleWhere(
        (call) => call.id == 'replay-completed',
      );
      expect(recoveredCall.status, 'uncertain');
      expect(
        recoveredCall.resultJson,
        contains('"operationId":"write-completed"'),
      );
      await run(
        'recheck-after-recovery',
        query: 'intentional new action',
        operationId: 'write-completed',
      );
      expect(effects, 3);
      await WorkspaceResource.db.updateRow(
        fixture.database,
        target.copyWith(
          data: jsonEncode({
            'toolId': 'connector/duckduckgo/search',
            'isEnabled': false,
          }),
        ),
      );
      expect(
        await run(
          'denied-after-uncertain',
          query: 'intentional new action',
          operationId: 'write-completed',
        ),
        ServerToolDisposition.completed,
      );
      expect(effects, 3);
      final denied = await endpoints.conversation.getConversationSnapshot(
        fixture.session,
        GetConversationRequest(
          workspaceId: fixture.workspaceId,
          conversationId: 'conversation-1',
        ),
      );
      expect(
        denied.toolCalls
            .singleWhere((call) => call.id == 'denied-after-uncertain')
            .status,
        'executionError',
      );
    });

    Future<void> configureProvider(_Fixture fixture) async {
      fixture.database.passwords['workspaceSecretKey'] =
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
      final now = DateTime.now().toUtc();
      await WorkspaceModelConnection.db.insertRow(
        fixture.database,
        WorkspaceModelConnection(
          workspaceId: fixture.workspaceId,
          connectionId: 'connection-1',
          providerId: 'openai',
          name: 'Provider',
          url: 'https://provider.test/v1',
          hasSecret: true,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await ApiModel.db.insertRow(
        fixture.database,
        ApiModel(
          providerId: 'openai',
          modelId: 'model-1',
          name: 'Model',
          limitContext: 1,
          limitOutput: 1,
          modalitiesInput: const ['text'],
          modalitiesOutput: const ['text'],
          costInput: 0,
          costCacheRead: 0,
          costOutput: 0,
          openWeights: false,
          supportsReasoning: false,
          isCanonical: true,
          supportsPriorityMode: false,
          supportsToolCalls: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final encrypted = await const WorkspaceSecretCipher().encrypt(
        fixture.database,
        'test-secret',
        workspaceId: fixture.workspaceId,
        resourceId: 'connection-1',
      );
      await WorkspaceSecret.db.insertRow(
        fixture.database,
        WorkspaceSecret(
          workspaceId: fixture.workspaceId,
          secretKind: WorkspaceSecretKind.provider,
          scope: WorkspaceSecretScope.user,
          ownerUserId: WorkspaceResourceValidation.secretOwnerKey(
            WorkspaceSecretScope.user,
            fixture.userId,
          ),
          resourceId: 'connection-1',
          ciphertext: encrypted.ciphertext,
          nonce: encrypted.nonce,
          authenticationTag: encrypted.authenticationTag,
          algorithm: 'AES-256-GCM',
          keyVersion: 1,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final user = fixture.messages.singleWhere(
        (message) => message.role == 'user',
      );
      await ConversationMessage.db.updateRow(
        fixture.database,
        user.copyWith(
          metadataJson: jsonEncode({
            'modelSelectionId': VirtualWorkspaceModelSelectionId.encode(
              connectionId: 'connection-1',
              modelId: 'model-1',
            ),
          }),
        ),
      );
      fixture.messages = await ConversationMessage.db.find(
        fixture.database,
        where: (table) => table.conversationId.equals(fixture.conversationId),
        orderBy: (table) => table.id,
      );
    }

    test(
      'claimed continuation clears the queued marker without losing the result',
      () async {
        final fixture = await prepare();
        final now = DateTime.now().toUtc();
        final message = fixture.messages.singleWhere(
          (candidate) => candidate.role == 'user',
        );
        const workId = 'background-work-queued-marker';
        const toolCallId = 'background-call-queued-marker';
        final toolCall = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            turnId: fixture.turn.id!,
            messageId: message.id!,
            stableId: toolCallId,
            name: 'skill__app_native__agents__run_sub_agent',
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            backgroundEligible: true,
            backgroundWorkStableId: workId,
            status: 'runningInBackground',
            revision: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await BackgroundWorkRecord.db.insertRow(
          fixture.database,
          BackgroundWorkRecord(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            conversationToolCallId: toolCall.id!,
            originatingMessageId: message.id,
            stableId: workId,
            toolCallId: toolCallId,
            toolKind: 'skillNative',
            status: 'completed',
            statusPreview: BackgroundWorkPreviews.queuedForContinuation,
            resultContent: '{"answer":"saved"}',
            resultByteLength: 18,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ConversationMessage.db.updateRow(
          fixture.database,
          message.copyWith(
            metadataJson: jsonEncode({
              'isBackgroundWorkCompletion': true,
              'backgroundWorkId': workId,
            }),
          ),
        );

        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: const _CompletingHost()),
        );

        final stored = await BackgroundWorkRecord.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals(workId),
        );
        expect(stored?.status, 'completed');
        expect(stored?.statusPreview, 'Completed');
        expect(stored?.resultContent, '{"answer":"saved"}');
        final continuationEvents = await ConversationEvent.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationId),
          orderBy: (table) => table.sequence,
        );
        expect(
          _backgroundWorkStatusPreviews(continuationEvents, workId),
          [
            BackgroundWorkPreviews.continuationInProgress,
            'Completed',
          ],
        );
      },
    );

    test(
      'retrying a continuation keeps its completed result inspectable',
      () async {
        final fixture = await prepare();
        final now = DateTime.now().toUtc();
        final message = fixture.messages.singleWhere(
          (candidate) => candidate.role == 'user',
        );
        const workId = 'background-work-retry-marker';
        const toolCallId = 'background-call-retry-marker';
        final toolCall = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            turnId: fixture.turn.id!,
            messageId: message.id!,
            stableId: toolCallId,
            name: 'skill__app_native__agents__run_sub_agent',
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            backgroundEligible: true,
            backgroundWorkStableId: workId,
            status: 'runningInBackground',
            revision: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await BackgroundWorkRecord.db.insertRow(
          fixture.database,
          BackgroundWorkRecord(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            conversationToolCallId: toolCall.id!,
            originatingMessageId: message.id,
            stableId: workId,
            toolCallId: toolCallId,
            toolKind: 'skillNative',
            status: 'completed',
            statusPreview: BackgroundWorkPreviews.queuedForContinuation,
            resultContent: '{"answer":"saved before retry"}',
            resultByteLength: 31,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ConversationMessage.db.updateRow(
          fixture.database,
          message.copyWith(
            metadataJson: jsonEncode({
              'isBackgroundWorkCompletion': true,
              'backgroundWorkId': workId,
            }),
          ),
        );

        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: const _TransientFailingHost()),
        );

        final stored = await BackgroundWorkRecord.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals(workId),
        );
        final retriedJob = await ConversationJob.db.findById(
          fixture.database,
          fixture.job.id!,
        );
        expect(retriedJob?.status, ConversationJobStatuses.queued);
        expect(
          stored?.statusPreview,
          BackgroundWorkPreviews.queuedForContinuation,
        );
        expect(stored?.resultContent, '{"answer":"saved before retry"}');
        final continuationEvents = await ConversationEvent.db.find(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.conversationId.equals(fixture.conversationId),
        );
        expect(
          _backgroundWorkStatusPreviews(continuationEvents, workId),
          [
            BackgroundWorkPreviews.continuationInProgress,
            BackgroundWorkPreviews.queuedForContinuation,
          ],
        );
        final visibleWorks = await endpoints.conversation.listBackgroundWorks(
          fixture.session,
          ListBackgroundWorksRequest(
            workspaceId: fixture.workspaceId,
            conversationId: 'conversation-1',
          ),
        );
        expect(visibleWorks.single.id, workId);
      },
    );

    test(
      'cloud detachment is rejected at the global limit and recovers capacity',
      () async {
        final fixture = await prepare();
        final now = DateTime.now().toUtc();
        final message = fixture.messages.first;
        final activeWorks = <BackgroundWorkRecord>[];
        for (
          var index = 0;
          index < ConversationLimits.maxConcurrentDetachedWork;
          index++
        ) {
          final workId = 'background-capacity-$index';
          final toolCall = await ConversationToolCall.db.insertRow(
            fixture.database,
            ConversationToolCall(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationId,
              turnId: fixture.turn.id!,
              messageId: message.id!,
              stableId: 'background-capacity-call-$index',
              name: 'skill__app_native__agents__run_sub_agent',
              argumentsJson: '{}',
              argumentsDigest: 'digest',
              backgroundEligible: true,
              backgroundWorkStableId: workId,
              status: 'runningInBackground',
              resultJson: jsonEncode({
                'status': 'running_in_background',
                'work_id': workId,
              }),
              revision: 2,
              createdAt: now,
              updatedAt: now,
            ),
          );
          activeWorks.add(
            await BackgroundWorkRecord.db.insertRow(
              fixture.database,
              BackgroundWorkRecord(
                workspaceId: fixture.workspaceId,
                conversationId: fixture.conversationId,
                conversationToolCallId: toolCall.id!,
                originatingMessageId: message.id,
                stableId: workId,
                toolCallId: toolCall.stableId,
                toolKind: 'skillNative',
                status: 'running',
                createdAt: now,
                updatedAt: now,
              ),
            ),
          );
        }
        final target = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            turnId: fixture.turn.id!,
            messageId: message.id!,
            stableId: 'background-capacity-target',
            name: 'skill__app_native__agents__run_sub_agent',
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            backgroundEligible: true,
            status: 'running',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final useCases = ConversationUseCases(
          conversation_repo.ConversationRepository(),
        );
        final request = DetachToolCallRequest(
          workspaceId: fixture.workspaceId,
          requestId: 'detach-over-capacity',
          conversationId: 'conversation-1',
          toolCallId: target.stableId,
        );

        await expectLater(
          useCases.detachToolCall(
            fixture.database,
            userId: fixture.userId,
            request: request,
          ),
          throwsA(
            isA<ConversationException>().having(
              (error) => error.code,
              'code',
              ConversationErrorCode.turnConflict,
            ),
          ),
        );
        final unchangedTarget = await ConversationToolCall.db.findById(
          fixture.database,
          target.id!,
        );
        expect(unchangedTarget?.status, 'running');
        expect(unchangedTarget?.backgroundWorkStableId, isNull);

        await BackgroundWorkRecord.db.updateRow(
          fixture.database,
          activeWorks.first.copyWith(status: 'completed'),
        );
        final admitted = await useCases.detachToolCall(
          fixture.database,
          userId: fixture.userId,
          request: request.copyWith(requestId: 'detach-after-capacity'),
        );

        expect(admitted.status, 'running');
        expect(admitted.statusPreview, isNull);
        expect(
          await BackgroundWorkRecord.db.count(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.status.equals('running'),
          ),
          ConversationLimits.maxConcurrentDetachedWork,
        );
      },
    );

    test('cloud stop request is scoped and idempotent', () async {
      final fixture = await prepare();
      final now = DateTime.now().toUtc();
      final message = fixture.messages.first;
      const workId = 'background-work-stop';
      const toolCallId = 'background-call-stop';
      const acknowledgement = '{"status":"running_in_background"}';
      final call = await ConversationToolCall.db.insertRow(
        fixture.database,
        ConversationToolCall(
          workspaceId: fixture.workspaceId,
          conversationId: fixture.conversationId,
          turnId: fixture.turn.id!,
          messageId: message.id!,
          stableId: toolCallId,
          name: 'skill__app_native__agents__run_sub_agent',
          argumentsJson: '{}',
          argumentsDigest: 'digest',
          backgroundEligible: true,
          backgroundWorkStableId: workId,
          status: 'runningInBackground',
          resultJson: acknowledgement,
          revision: 2,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await BackgroundWorkRecord.db.insertRow(
        fixture.database,
        BackgroundWorkRecord(
          workspaceId: fixture.workspaceId,
          conversationId: fixture.conversationId,
          conversationToolCallId: call.id!,
          originatingMessageId: message.id!,
          stableId: workId,
          toolCallId: toolCallId,
          toolKind: 'skillNative',
          status: 'running',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final request = StopBackgroundWorkRequest(
        requestId: 'stop-background-work',
        workspaceId: fixture.workspaceId,
        conversationId: 'conversation-1',
        workId: workId,
      );
      final requested = await endpoints.conversation.stopBackgroundWork(
        fixture.session,
        request,
      );
      expect(requested.status, 'stopRequested');
      final retried = await endpoints.conversation.stopBackgroundWork(
        fixture.session,
        request.copyWith(requestId: 'stop-background-work-retry'),
      );
      expect(retried.status, 'stopRequested');
      final storedCall = await ConversationToolCall.db.findById(
        fixture.database,
        call.id!,
      );
      expect(storedCall?.resultJson, acknowledgement);
      expect(storedCall?.backgroundWorkStableId, workId);
    });

    test(
      'resumed all-denied calls are sent to the provider as a terminal exchange',
      () async {
        final fixture = await prepare();
        await configureProvider(fixture);
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            turnId: fixture.turn.id!,
            messageId: assistant.id!,
            stableId: 'call-denied',
            name: 'tool',
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            status: 'denied',
            decision: 'deny',
            resultJson: '{"error":"Tool approval was denied."}',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final requests = <Map<String, dynamic>>[];
        final host = ServerConversationEngineHost(
          admissionGate: const _ImmediateAdmissionGate(),
          lookup: (_) async => [InternetAddress('8.8.8.8')],
          providerTransport: (body) async {
            requests.add(body);
            return ProviderTransportResponse(
              statusCode: 200,
              body: Stream.value(
                utf8.encode(
                  'data: {"id":"response","choices":[{"delta":{"content":"Done"},"finish_reason":"stop"}],"usage":{"prompt_tokens":1,"completion_tokens":1,"total_tokens":2}}\n\n'
                  'data: [DONE]\n\n',
                ),
              ),
            );
          },
        );

        await host.executeTurn(
          fixture.database,
          job: fixture.job,
          turn: fixture.turn,
          messages: fixture.messages,
          liveTurns: const _NoopProgressPublisher(),
        );

        final messages = requests.single['messages'] as List;
        final deniedAssistantMessage = messages.whereType<Map>().singleWhere(
          (message) =>
              message['role'] == 'assistant' && message['tool_calls'] is List,
        );
        expect(deniedAssistantMessage['content'], isNull);
        final deniedToolCalls = deniedAssistantMessage['tool_calls'] as List;
        expect(deniedToolCalls, hasLength(1));
        final deniedToolCall = Map<String, Object?>.from(
          deniedToolCalls.single as Map,
        );
        expect(deniedToolCall['id'], 'call-denied');
        expect(deniedToolCall['type'], 'function');
        final deniedFunction = Map<String, Object?>.from(
          deniedToolCall['function']! as Map,
        );
        expect(deniedFunction['name'], 'tool');
        expect(deniedFunction['arguments'], '{}');

        final deniedToolReply = messages.whereType<Map>().singleWhere(
          (message) =>
              message['role'] == 'tool' &&
              message['tool_call_id'] == 'call-denied',
        );
        expect(
          deniedToolReply['content'],
          '{"error":"Tool approval was denied."}',
        );
      },
    );

    test(
      'does not inject the A2UI catalog prompt before capability activation',
      () async {
        final fixture = await prepare();
        await configureProvider(fixture);
        final requests = <Map<String, dynamic>>[];
        final host = ServerConversationEngineHost(
          admissionGate: const _ImmediateAdmissionGate(),
          lookup: (_) async => [InternetAddress('8.8.8.8')],
          providerTransport: (body) async {
            requests.add(body);
            return ProviderTransportResponse(
              statusCode: 200,
              body: Stream.value(
                utf8.encode(
                  'data: {"id":"response","choices":[{"delta":{"content":"Done"},"finish_reason":"stop"}],"usage":{"prompt_tokens":1,"completion_tokens":1,"total_tokens":2}}\n\n'
                  'data: [DONE]\n\n',
                ),
              ),
            );
          },
        );

        await host.executeTurn(
          fixture.database,
          job: fixture.job.copyWith(
            payloadJson: conversation_repo.conversationTurnJobPayload(
              fixture.userId,
              a2uiSupportedComponents: const ['Text'],
            ),
          ),
          turn: fixture.turn,
          messages: fixture.messages,
          liveTurns: const _NoopProgressPublisher(),
        );

        final messages = requests.single['messages'] as List;
        expect(
          messages.whereType<Map>().any(
            (message) =>
                message['content'] is String &&
                (message['content'] as String).contains(
                  a2uiChatCatalogId,
                ),
          ),
          isFalse,
        );
        expect(
          messages.whereType<Map>().any(
            (message) =>
                message['content'] is String &&
                (message['content'] as String).contains(
                  'CATALOG_SCHEMA_START',
                ),
          ),
          isFalse,
        );
      },
    );

    test(
      'Skill activation references Connector tools without loading tool specs',
      () async {
        final fixture = await prepare();
        final now = DateTime.now().toUtc();
        final connector = connectorDefinitions.singleWhere(
          (candidate) => candidate.identifier == 'duckduckgo',
        );
        final toolId = connectorToolId(connector, connector.tools.single);
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.skill,
            resourceId: 'research',
            data: jsonEncode({
              'id': 'research',
              'slug': 'research',
              'title': 'Research',
              'description': 'Use primary sources.',
              'content': 'Search primary sources.',
              'connectorToolIds': [toolId],
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final runtime = ServerToolRuntime();
        final before = await runtime.loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        );
        final revision = (await buildCloudSkillCatalog(
          fixture.database,
          workspaceId: fixture.workspaceId,
          activeSkillIds: const {},
          isChildConversation: false,
        )).singleWhere((entry) => entry.slug == 'research').revision;
        final activate = before.singleWhere(
          (tool) => tool.spec.name == activateSkillToolName,
        );
        final result = await const ServerToolExecutorService().call(
          fixture.database,
          fixture.turn,
          activate,
          ServerToolRequest(
            id: 'activate-research',
            name: activateSkillToolName,
            arguments: {'slug': 'research', 'revision': revision},
          ),
        );
        expect(result, isA<SkillActivationResult>());
        expect(result.toString(), contains(toolId));

        final after = await runtime.loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        );
        final connectorTools = [
          for (final tool in before)
            if (tool.descriptor.kind == AgentResolvedToolKind.connectorCommand)
              tool.spec,
        ];
        expect(
          [
            for (final tool in after)
              if (tool.descriptor.kind ==
                  AgentResolvedToolKind.connectorCommand)
                tool.spec,
          ],
          orderedEquals(connectorTools),
        );
        final names = after.map((tool) => tool.spec.name);
        expect(names, contains(executeConnectorToolName));
        expect(names, isNot(contains(toolId)));
        expect(
          names.where((name) => name.startsWith('skill__user__')),
          isEmpty,
        );
      },
    );

    test('agents activation preserves the conversation language', () async {
      const languageCode = 'es-MX';
      final fixture = await prepare(languageCode: languageCode);
      final spanishManifest = await buildCloudSkillManifest(
        slug: agentsSkillSlug,
        userSkills: const [],
        languageCode: languageCode,
      );
      expect(spanishManifest, isNotNull);
      final runtime = ServerToolRuntime(
        executor: (session, turn, tool, request) =>
            const ServerToolExecutorService().call(
              session,
              turn,
              tool,
              request,
            ),
      );
      final controls = await runtime.loadTools(
        fixture.database,
        workspaceId: fixture.workspaceId,
        conversationStableId: 'conversation-1',
        languageCode: languageCode,
      );
      final activate = controls.singleWhere(
        (tool) => tool.spec.name == activateSkillToolName,
      );
      final runSubAgentBefore = controls.singleWhere(
        (tool) => tool.descriptor.toolIdentifier == runSubAgentToolName,
      );

      final activated = await const ServerToolExecutorService().call(
        fixture.database,
        fixture.turn,
        activate,
        ServerToolRequest(
          id: 'activate-agents-spanish',
          name: activateSkillToolName,
          arguments: {
            'slug': agentsSkillSlug,
            'revision': spanishManifest!.revision,
          },
          languageCode: languageCode,
        ),
      );

      expect(activated, isA<SkillActivationResult>());
      expect(activated.toString(), contains('Usa list_agents'));
      expect(activated.toString(), isNot(contains('Use list_agents')));
      final selectedTools = await runtime.loadTools(
        fixture.database,
        workspaceId: fixture.workspaceId,
        conversationStableId: 'conversation-1',
        languageCode: languageCode,
      );
      final runSubAgentAfter = selectedTools.singleWhere(
        (tool) => tool.descriptor.toolIdentifier == runSubAgentToolName,
      );
      expect(runSubAgentAfter.spec.name, runSubAgentBefore.spec.name);
      expect(
        runSubAgentAfter.spec.inputJsonSchema,
        runSubAgentBefore.spec.inputJsonSchema,
      );

      final listAgents = selectedTools.singleWhere(
        (tool) => tool.descriptor.toolIdentifier == listAgentsToolName,
      );
      final now = DateTime.now().toUtc();
      await WorkspaceResource.db.insertRow(
        fixture.database,
        WorkspaceResource(
          workspaceId: fixture.workspaceId,
          resourceKind: WorkspaceResourceKind.toolPermission,
          resourceId: 'agents-list-agents-permission',
          data: jsonEncode({
            'toolId': listAgents.descriptor.tableId,
            'permissionMode': 'alwaysAllow',
            'isEnabled': true,
          }),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final disposition = await runtime.handle(
        fixture.database,
        turn: fixture.turn,
        messageId: fixture.messages
            .singleWhere(
              (message) => message.id == fixture.turn.assistantMessageId,
            )
            .id!,
        request: ServerToolRequest(
          id: 'list-agents-through-call-skill',
          name: listAgents.spec.name,
          arguments: const {},
          languageCode: languageCode,
        ),
      );
      final dispatchedCall = await ConversationToolCall.db.findFirstRow(
        fixture.database,
        where: (table) =>
            table.stableId.equals('list-agents-through-call-skill'),
      );
      expect(disposition, ServerToolDisposition.completed);
      expect(dispatchedCall?.status, 'success');
      expect(dispatchedCall?.resultJson, contains('agentes configurados'));
      expect(
        dispatchedCall?.resultJson,
        isNot(contains('Configured agents')),
      );
    });

    test(
      'activates content-only A2UI and loads static resources after selection',
      () async {
        final fixture = await prepare();
        final runtime = ServerToolRuntime();
        final catalog = await buildCloudSkillCatalog(
          fixture.database,
          workspaceId: fixture.workspaceId,
          activeSkillIds: const {},
          isChildConversation: false,
        );
        final a2uiEntry = catalog.singleWhere(
          (entry) => entry.slug == a2uiSkillSlug,
        );
        expect(a2uiEntry.active, isFalse);

        final childCatalog = await buildCloudSkillCatalog(
          fixture.database,
          workspaceId: fixture.workspaceId,
          activeSkillIds: const {},
          isChildConversation: true,
        );
        expect(
          childCatalog.any((entry) => entry.slug == a2uiSkillSlug),
          isFalse,
        );

        final optedOutCatalog = await buildCloudSkillCatalog(
          fixture.database,
          workspaceId: fixture.workspaceId,
          activeSkillIds: const {},
          isChildConversation: false,
          a2uiSupportedComponents: const {},
        );
        expect(
          optedOutCatalog.any((entry) => entry.slug == a2uiSkillSlug),
          isFalse,
        );

        final controls = await runtime.loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        );
        final activate = controls.singleWhere(
          (tool) => tool.spec.name == activateSkillToolName,
        );
        final activated = await const ServerToolExecutorService().call(
          fixture.database,
          fixture.turn,
          activate,
          ServerToolRequest(
            id: 'activate-a2ui',
            name: activateSkillToolName,
            arguments: {
              'slug': a2uiSkillSlug,
              'revision': a2uiEntry.revision,
            },
          ),
        );

        expect(activated, isA<SkillActivationResult>());
        expect(activated.toString(), contains('<skill_content'));
        expect(activated.toString(), contains(a2uiCoreResourceSlug));
        expect(activated.toString(), contains(a2uiPassiveResourceSlug));

        final load = controls.singleWhere(
          (tool) => tool.spec.name == loadSkillResourceToolName,
        );
        final core = await const ServerToolExecutorService().call(
          fixture.database,
          fixture.turn,
          load,
          const ServerToolRequest(
            id: 'load-a2ui-core',
            name: loadSkillResourceToolName,
            arguments: {
              'skill': a2uiSkillSlug,
              'resource': a2uiCoreResourceSlug,
            },
          ),
        );
        expect(core.toString(), contains('A2UI_CORE_INSTRUCTIONS_START'));
        expect(core.toString(), isNot(contains('CATALOG_SCHEMA_START')));

        final passive =
            await ServerToolExecutorService(
              a2uiSupportedComponents: const {'Text'},
            ).call(
              fixture.database,
              fixture.turn,
              load,
              const ServerToolRequest(
                id: 'load-a2ui-passive',
                name: loadSkillResourceToolName,
                arguments: {
                  'skill': a2uiSkillSlug,
                  'resource': a2uiPassiveResourceSlug,
                },
              ),
            );
        expect(passive.toString(), contains('CATALOG_SCHEMA_START'));
        expect(passive.toString(), contains('"Text"'));
        expect(passive.toString(), isNot(contains('"TextField"')));
      },
    );

    test(
      'unloaded tool is terminally unavailable before its stale descriptor executes',
      () async {
        const staleToolName = 'mcp_server-1_server_tool';
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        final call = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            turnId: fixture.turn.id!,
            messageId: assistant.id!,
            stableId: 'call-approved',
            name: staleToolName,
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            status: 'approved',
            decision: 'approve',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final tool = await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.tool,
            resourceId: 'server-1',
            data: jsonEncode({
              'name': staleToolName,
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final advertised = (await ServerToolRuntime().loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        )).firstWhere((tool) => tool.spec.name == staleToolName);
        await WorkspaceResource.db.updateRow(
          fixture.database,
          tool.copyWith(deletedAt: DateTime.now().toUtc()),
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
          turn: fixture.turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: 'call-approved',
            name: advertised.spec.name,
            arguments: {},
          ),
        );

        final resolved = (await ConversationToolCall.db.findById(
          fixture.database,
          call.id!,
        ))!;
        expect(executions, 0);
        expect(resolved.status, 'toolNotFound');
        expect(resolved.resultJson, contains('no longer available'));
      },
    );

    test(
      'Connector tool IDs require the shared execution command',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final connector = connectorDefinitions.singleWhere(
          (candidate) => candidate.identifier == 'duckduckgo',
        );
        final toolId = connectorToolId(connector, connector.tools.single);
        var executions = 0;
        final runtime = ServerToolRuntime(
          executor: (_, _, _, _) async {
            executions++;
            return {'unexpected': true};
          },
        );

        final advertisedNames = (await runtime.loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        )).map((tool) => tool.spec.name);
        expect(advertisedNames, contains(executeConnectorToolName));
        expect(advertisedNames, isNot(contains(toolId)));
        await runtime.handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: 'call-direct-connector-tool',
            name: toolId,
            arguments: const {'query': 'search'},
          ),
        );

        final call = await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals('call-direct-connector-tool'),
        );
        expect(executions, 0);
        expect(call?.status, 'toolNotFound');
      },
    );

    test(
      'Connector command denial blocks executor side effects',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.toolPermission,
            resourceId: 'connector-command-deny',
            data: jsonEncode({
              'toolId': executeConnectorToolName,
              'permissionMode': 'alwaysDeny',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
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
          turn: fixture.turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: 'call-denied-connector-command',
            name: executeConnectorToolName,
            arguments: const {
              'toolId': 'connector/duckduckgo/search',
              'args': {'query': 'search'},
            },
          ),
        );

        final call = await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.stableId.equals('call-denied-connector-command'),
        );
        expect(executions, 0);
        expect(
          call?.status,
          AgentToolPermissionResult.disabledInWorkspace.name,
        );
      },
    );

    test(
      'admin shared Connector execution honors target group denial',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        final membership = await WorkspaceMember.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.userId.equals(fixture.turn.initiatorUserId),
        );
        await WorkspaceMember.db.updateRow(
          fixture.database,
          membership!.copyWith(role: 'admin'),
        );
        final target = await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: .tool,
            resourceId: 'connector/brave/web_search',
            data: jsonEncode({
              'toolId': 'connector/brave/web_search',
              'isEnabled': true,
              'permissionMode': 'alwaysAllow',
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.toolPermission,
            resourceId: 'connector-command-allow',
            data: jsonEncode({
              'toolId': executeConnectorToolName,
              'permissionMode': 'alwaysAllow',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final runtime = ServerToolRuntime(
          executor: const ServerToolExecutorService().call,
        );

        await runtime.handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: const ServerToolRequest(
            id: 'execute-without-connection',
            name: executeConnectorToolName,
            arguments: {
              'toolId': 'connector/brave/web_search',
              'args': {'query': 'research'},
            },
          ),
        );

        final call = await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals('execute-without-connection'),
        );
        expect(call?.status, 'executionError');
        expect(call?.resultJson, contains('connection_required'));
        expect(call?.resultJson, contains('"recoverable":true'));
        await WorkspaceResource.db.updateRow(
          fixture.database,
          target.copyWith(
            data: jsonEncode({
              'toolId': 'connector/brave/web_search',
              'toolGroupId': 'connector-group',
              'isEnabled': true,
              'permissionMode': 'alwaysAllow',
            }),
          ),
        );
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: .toolGroup,
            resourceId: 'connector-group',
            data: jsonEncode({'isEnabled': false}),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final _ = await runtime.handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: const ServerToolRequest(
            id: 'execute-with-disabled-group',
            name: executeConnectorToolName,
            arguments: {
              'toolId': 'connector/brave/web_search',
              'args': {'query': 'research'},
            },
          ),
        );
        final denied = await ConversationToolCall.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.stableId.equals('execute-with-disabled-group'),
        );
        expect(denied?.resultJson, contains('tool_access_denied'));
      },
    );

    test(
      'durable cancellation before executor invocation prevents side effects',
      () async {
        final fixture = await prepare();
        final assistant = fixture.messages.singleWhere(
          (message) => message.id == fixture.turn.assistantMessageId,
        );
        final now = DateTime.now().toUtc();
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.tool,
            resourceId: 'server-1',
            data: jsonEncode({
              'name': 'mcp_server-1_server_tool',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.toolPermission,
            resourceId: 'server-1-permission',
            data: jsonEncode({
              'toolId': 'server-1',
              'permissionMode': 'alwaysAllow',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final advertised = (await ServerToolRuntime().loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        )).firstWhere((tool) => tool.spec.name == 'mcp_server-1_server_tool');
        final cancellation = _BlockedCancellationProbe();
        var executions = 0;
        final runtime = ServerToolRuntime(
          cancellationProbe: cancellation,
          executor: (_, _, _, _) async {
            executions++;
            return {'unexpected': true};
          },
        );

        final handling = runtime.handle(
          fixture.database,
          turn: fixture.turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: 'cancelled-before-executor',
            name: advertised.spec.name,
            arguments: {},
          ),
        );
        await cancellation.entered.future.timeout(const Duration(seconds: 2));
        await ConversationTurn.db.updateRow(
          fixture.database,
          fixture.turn.copyWith(
            cancellationRequestedAt: DateTime.now().toUtc(),
          ),
        );
        cancellation.release.complete();

        await expectLater(
          handling,
          throwsA(isA<ConversationCancelledException>()),
        );
        expect(executions, 0);
      },
    );

    test(
      'cancellation while creating a child removes its queued child artifacts',
      () async {
        final fixture = await prepare();
        final entered = Completer<void>();
        final release = Completer<void>();
        final parentTool = ServerResolvedTool(
          descriptor: AgentResolvedToolName.skillNative(
            tableId: runSubAgentToolName,
            skillSlug: agentsSkillSlug,
            toolIdentifier: runSubAgentToolName,
          ),
          spec: ToolSpec(
            name: 'skill__app_native__agents__$runSubAgentToolName',
            description: '',
            inputJsonSchema: const {},
          ),
        );
        final handling =
            ServerToolExecutorService(
              beforeChildLaunch: () async {
                entered.complete();
                await release.future;
              },
            ).call(
              fixture.database,
              fixture.turn,
              parentTool,
              ServerToolRequest(
                id: 'cancel-during-child-launch',
                name: 'skill__app_native__agents__run_sub_agent',
                arguments: {'title': 'Child', 'prompt': 'Do the work.'},
              ),
            );
        await entered.future.timeout(const Duration(seconds: 2));
        await ConversationUseCases(
          conversation_repo.ConversationRepository(),
          publishConversationJob: (_, _) async {},
        ).cancelTurn(
          fixture.database,
          userId: fixture.userId,
          request: CancelTurnRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'cancel-parent-during-child-launch',
            turnId: fixture.turn.requestId,
            expectedTurnRevision: fixture.turn.revision,
          ),
        );
        release.complete();

        await expectLater(
          handling,
          throwsA(isA<ConversationCancelledException>()),
        );
        final child = (await Conversation.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.parentConversationStableId.equals('conversation-1'),
        ))!;
        expect(child.deletedAt, isNotNull);
        expect(
          await ConversationMessage.db.find(
            fixture.database,
            where: (table) => table.conversationId.equals(child.id),
          ),
          isEmpty,
        );
        expect(
          await ConversationJob.db.find(
            fixture.database,
            where: (table) => table.conversationId.equals(child.id),
          ),
          isEmpty,
        );
      },
    );

    test(
      'a second worker retires a continued child when its parent is cancelled',
      () async {
        final fixture = await prepare();
        final continued = Completer<void>();
        final release = Completer<void>();
        final parentTool = ServerResolvedTool(
          descriptor: AgentResolvedToolName.skillNative(
            tableId: runSubAgentToolName,
            skillSlug: agentsSkillSlug,
            toolIdentifier: runSubAgentToolName,
          ),
          spec: ToolSpec(
            name: 'skill__app_native__agents__$runSubAgentToolName',
            description: '',
            inputJsonSchema: const {},
          ),
        );
        final handling =
            ServerToolExecutorService(
              afterChildContinuation: () async {
                continued.complete();
                await release.future;
              },
            ).call(
              fixture.database,
              fixture.turn,
              parentTool,
              ServerToolRequest(
                id: 'cancel-after-child-continuation',
                name: 'skill__app_native__agents__run_sub_agent',
                arguments: {'title': 'Child', 'prompt': 'Do the work.'},
              ),
            );
        await continued.future.timeout(const Duration(seconds: 2));
        await ConversationUseCases(
          conversation_repo.ConversationRepository(),
          publishConversationJob: (_, _) async {},
        ).cancelTurn(
          fixture.database,
          userId: fixture.userId,
          request: CancelTurnRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'cancel-parent-after-child-continuation',
            turnId: fixture.turn.requestId,
            expectedTurnRevision: fixture.turn.revision,
          ),
        );

        final effects = _EffectTrackingHost();
        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: effects),
        );
        final child = (await Conversation.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.parentConversationStableId.equals('conversation-1'),
        ))!;
        final execution = (await ConversationExecution.db.findFirstRow(
          fixture.database,
          where: (table) => table.conversationId.equals(child.id),
        ))!;
        final childTurn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) => table.requestId.equals(execution.stableId),
        ))!;
        final jobs = await ConversationJob.db.find(
          fixture.database,
          where: (table) => table.conversationId.equals(child.id),
        );

        expect(
          conversation_repo.conversationParentTurnIdForExecutionSettings(
            execution.settingsJson,
          ),
          fixture.turn.id,
        );
        expect(
          conversation_repo.conversationParentTurnIdForJob(
            jobs.single.payloadJson,
          ),
          fixture.turn.id,
        );
        expect(child.activeExecutionId, isNull);
        expect(execution.status, ConversationStatuses.cancelled);
        expect(childTurn.status, ConversationStatuses.cancelled);
        expect(
          jobs.map((job) => job.status),
          isNot(
            contains(
              anyOf(
                ConversationJobStatuses.queued,
                ConversationJobStatuses.leased,
              ),
            ),
          ),
        );
        expect(effects.calls, 0);

        release.complete();
        await expectLater(
          handling,
          throwsA(isA<ConversationCancelledException>()),
        );
      },
    );

    test(
      'cancellation before loading a skill leaves no selection or workspace event',
      () async {
        final fixture = await prepare();
        final now = DateTime.now().toUtc();
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.skill,
            resourceId: 'research',
            data: jsonEncode({
              'slug': 'research',
              'title': 'Research',
              'description': 'Use primary sources.',
              'content': 'Use primary sources.',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final activate = (await ServerToolRuntime().loadTools(
          fixture.database,
          workspaceId: fixture.workspaceId,
          conversationStableId: 'conversation-1',
        )).singleWhere((tool) => tool.spec.name == activateSkillToolName);
        final revision = (await buildCloudSkillCatalog(
          fixture.database,
          workspaceId: fixture.workspaceId,
          activeSkillIds: const {},
          isChildConversation: false,
        )).singleWhere((entry) => entry.slug == 'research').revision;
        final eventCount = (await WorkspaceEvent.db.find(
          fixture.database,
          where: (table) => table.workspaceId.equals(fixture.workspaceId),
        )).length;
        final entered = Completer<void>();
        final release = Completer<void>();
        final handling =
            ServerToolExecutorService(
              beforeSkillSelectionMutation: () async {
                entered.complete();
                await release.future;
              },
            ).call(
              fixture.database,
              fixture.turn,
              activate,
              ServerToolRequest(
                id: 'cancel-during-activate-skill',
                name: activateSkillToolName,
                arguments: {'slug': 'research', 'revision': revision},
              ),
            );
        await entered.future.timeout(const Duration(seconds: 2));
        await ConversationUseCases(
          conversation_repo.ConversationRepository(),
          publishConversationJob: (_, _) async {},
        ).cancelTurn(
          fixture.database,
          userId: fixture.userId,
          request: CancelTurnRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'cancel-parent-during-load-skill',
            turnId: fixture.turn.requestId,
            expectedTurnRevision: fixture.turn.revision,
          ),
        );
        release.complete();

        await expectLater(
          handling,
          throwsA(isA<ConversationCancelledException>()),
        );
        expect(
          await WorkspaceResource.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.resourceKind.equals(
                  WorkspaceResourceKind.conversationSkillSelection,
                ),
          ),
          isEmpty,
        );
        expect(
          (await WorkspaceEvent.db.find(
            fixture.database,
            where: (table) => table.workspaceId.equals(fixture.workspaceId),
          )).length,
          eventCount,
        );
      },
    );

    test(
      'child carries its initiating parent turn model selection',
      () async {
        final fixture = await prepare();
        await configureProvider(fixture);
        final now = DateTime.now().toUtc();
        await ConversationJob.db.updateRow(
          fixture.database,
          fixture.job.copyWith(
            status: ConversationJobStatuses.completed,
            updatedAt: now,
          ),
        );
        final parentTool = ServerResolvedTool(
          descriptor: AgentResolvedToolName.skillNative(
            tableId: runSubAgentToolName,
            skillSlug: agentsSkillSlug,
            toolIdentifier: runSubAgentToolName,
          ),
          spec: ToolSpec(
            name: 'skill__app_native__agents__$runSubAgentToolName',
            description: '',
            inputJsonSchema: const {},
          ),
        );
        final childResult = await const ServerToolExecutorService().call(
          fixture.database,
          fixture.turn,
          parentTool,
          const ServerToolRequest(
            id: 'parent-approved-child',
            name: 'skill__app_native__agents__run_sub_agent',
            arguments: {'title': 'Child', 'prompt': 'Do the work.'},
          ),
        );
        final childLaunch = childResult! as ServerToolAwaitingSubAgents;
        final childId =
            childLaunch.children.single['conversationId']! as String;
        final child = (await Conversation.db.findFirstRow(
          fixture.database,
          where: (table) => table.stableId.equals(childId),
        ))!;
        final modelSelectionId = VirtualWorkspaceModelSelectionId.encode(
          connectionId: 'connection-1',
          modelId: 'model-1',
        );
        expect(child.modelId, modelSelectionId);
        final childExecution = (await ConversationExecution.db.findFirstRow(
          fixture.database,
          where: (table) => table.conversationId.equals(child.id),
        ))!;
        final childTurn = (await ConversationTurn.db.findFirstRow(
          fixture.database,
          where: (table) => table.requestId.equals(childExecution.stableId),
        ))!;
        final childUser = (await ConversationMessage.db.findById(
          fixture.database,
          childTurn.userMessageId!,
        ))!;
        expect(
          jsonDecode(childUser.metadataJson!)['modelSelectionId'],
          modelSelectionId,
        );
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.tool,
            resourceId: 'child-server',
            data: jsonEncode({
              'name': 'mcp_child-server_demo_confirm',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceResource.db.insertRow(
          fixture.database,
          WorkspaceResource(
            workspaceId: fixture.workspaceId,
            resourceKind: WorkspaceResourceKind.toolPermission,
            resourceId: 'child-server-permission',
            data: jsonEncode({
              'toolId': 'child-server',
              'permissionMode': 'alwaysAsk',
              'isEnabled': true,
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final childTool =
            (await ServerToolRuntime().loadTools(
              fixture.database,
              workspaceId: fixture.workspaceId,
              conversationStableId: childId,
            )).singleWhere(
              (tool) => tool.spec.name == 'mcp_child-server_demo_confirm',
            );
        final disposition = await ServerToolRuntime().handle(
          fixture.database,
          turn: childTurn,
          messageId: childExecution.assistantMessageId!,
          request: ServerToolRequest(
            id: 'child-confirmation',
            name: childTool.spec.name,
            arguments: const {},
          ),
        );
        expect(disposition, ServerToolDisposition.awaitingApproval);

        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: const _AwaitingApprovalHost()),
        );
        final pausedTurn = (await ConversationTurn.db.findById(
          fixture.database,
          childTurn.id!,
        ))!;
        final pausedExecution = (await ConversationExecution.db.findById(
          fixture.database,
          childExecution.id!,
        ))!;
        expect(pausedTurn.status, ConversationStatuses.awaitingApproval);
        expect(pausedExecution.status, ConversationStatuses.awaitingApproval);

        await ConversationUseCases(
          conversation_repo.ConversationRepository(),
          publishConversationJob: (_, _) async {},
        ).submitToolDecision(
          fixture.database,
          userId: fixture.userId,
          request: SubmitToolDecisionRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'approve-child-confirmation',
            conversationId: childId,
            turnId: pausedTurn.requestId,
            toolCallId: 'child-confirmation',
            argumentsDigest: (await ConversationToolCall.db.findFirstRow(
              fixture.database,
              where: (table) => table.stableId.equals('child-confirmation'),
            ))!.argumentsDigest,
            expectedTurnRevision: pausedTurn.revision,
            decision: 'approve',
          ),
        );
        await runConversationWorker(
          fixture.database,
          isActive: () => true,
          worker: ConversationWorker(host: const _CompletingHost()),
        );
        final completedExecution = (await ConversationExecution.db.findById(
          fixture.database,
          childExecution.id!,
        ))!;
        expect(completedExecution.status, ConversationStatuses.completed);
      },
    );

    test('connector result is not persisted after workspace erasure', () async {
      final fixture = await prepare();
      final assistant = fixture.messages.singleWhere(
        (message) => message.id == fixture.turn.assistantMessageId,
      );
      final now = DateTime.now().toUtc();
      await WorkspaceResource.db.insertRow(
        fixture.database,
        WorkspaceResource(
          workspaceId: fixture.workspaceId,
          resourceKind: WorkspaceResourceKind.tool,
          resourceId: 'connector/duckduckgo/search',
          data: jsonEncode({
            'toolId': 'connector/duckduckgo/search',
            'isEnabled': true,
            'permissionMode': 'alwaysAllow',
          }),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await WorkspaceResource.db.insertRow(
        fixture.database,
        WorkspaceResource(
          workspaceId: fixture.workspaceId,
          resourceKind: WorkspaceResourceKind.toolPermission,
          resourceId: 'command-allow',
          data: jsonEncode({
            'toolId': executeConnectorToolName,
            'permissionMode': 'alwaysAllow',
            'isEnabled': true,
          }),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final conversation = (await Conversation.db.findById(
        fixture.database,
        fixture.conversationId,
      ))!;
      await Conversation.db.updateRow(
        fixture.database,
        conversation.copyWith(toolAccessMode: 'allow_all'),
      );
      var executorCalls = 0;
      final runtime = ServerToolRuntime(
        executor: (session, _, _, _) async {
          executorCalls++;
          final workspace = (await CloudWorkspace.db.findById(
            session,
            fixture.workspaceId,
          ))!;
          await CloudWorkspace.db.updateRow(
            session,
            workspace.copyWith(erasureRequestedAt: DateTime.now().toUtc()),
          );
          return {'content': 'synthetic connector response'};
        },
      );

      final disposition = await runtime.handle(
        fixture.database,
        turn: fixture.turn,
        messageId: assistant.id!,
        request: const ServerToolRequest(
          id: 'erasure-after-connector-response',
          name: executeConnectorToolName,
          arguments: {
            'toolId': 'connector/duckduckgo/search',
            'args': {'query': 'synthetic read'},
          },
        ),
      );

      final call = (await ConversationToolCall.db.findFirstRow(
        fixture.database,
        where: (table) =>
            table.workspaceId.equals(fixture.workspaceId) &
            table.stableId.equals('erasure-after-connector-response'),
      ))!;
      expect(disposition, ServerToolDisposition.completed);
      expect(executorCalls, 1);
      expect(call.status, 'running');
      expect(call.resultJson, isNull);
    });
  });

  // Workspace deletion and a detached executor can overlap database writes.
  // Use a fresh database without the rollback proxy's single-transaction limit.
  withServerpod(
    'ConversationEngineHostRegression concurrent workspace removal',
    (sessionBuilder, endpoints) {
      Future<_Fixture> prepare() =>
          _prepareConversationFixture(sessionBuilder, endpoints);

      test(
        'workspace removal hides late detached output and leaves queued work idle',
        () async {
          final fixture = await prepare();
          final now = DateTime.now().toUtc();
          await WorkspaceResource.db.insertRow(
            fixture.database,
            WorkspaceResource(
              workspaceId: fixture.workspaceId,
              resourceKind: WorkspaceResourceKind.toolPermission,
              resourceId: 'run-sub-agent-permission',
              data: jsonEncode({
                'toolId': 'skill__app_native__agents__$runSubAgentToolName',
                'permissionMode': 'alwaysAllow',
                'isEnabled': true,
              }),
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          final entered = Completer<void>();
          final release = Completer<void>();
          final runtime = ServerToolRuntime(
            executor: (_, _, _, _) async {
              entered.complete();
              await release.future;
              return {'secret': 'late output'};
            },
          );
          final callTool =
              (await runtime.loadTools(
                fixture.database,
                workspaceId: fixture.workspaceId,
                conversationStableId: 'conversation-1',
              )).singleWhere(
                (candidate) =>
                    candidate.descriptor.toolIdentifier == runSubAgentToolName,
              );
          final assistant = fixture.messages.singleWhere(
            (message) => message.id == fixture.turn.assistantMessageId,
          );
          final handling = runtime.handle(
            fixture.database,
            turn: fixture.turn,
            messageId: assistant.id!,
            request: ServerToolRequest(
              id: 'background-workspace-removal-call',
              name: callTool.spec.name,
              arguments: {
                'title': 'Research',
                'prompt': 'Search primary sources.',
                'agentId': null,
              },
            ),
          );
          await entered.future.timeout(const Duration(seconds: 2));

          final work = await endpoints.conversation.detachToolCall(
            fixture.session,
            DetachToolCallRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'detach-before-workspace-removal',
              conversationId: 'conversation-1',
              toolCallId: 'background-workspace-removal-call',
            ),
          );
          await handling.timeout(const Duration(seconds: 2));
          final acknowledgement = jsonEncode({
            'status': 'running_in_background',
            'work_id': work.id,
          });
          final call = (await ConversationToolCall.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.stableId.equals('background-workspace-removal-call'),
          ))!;

          final conversation = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationId,
          ))!;
          await endpoints.conversation.queueConversationMessage(
            fixture.session,
            QueueConversationMessageRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'queue-behind-detached-work',
              conversationId: 'conversation-1',
              expectedProjectionRevision: conversation.projectionRevision,
              clientMessageId: 'message-behind-detached-work',
              content: 'Continue after the search.',
              attachmentIds: const [],
            ),
          );

          await endpoints.cloudWorkspace.deleteWorkspace(
            fixture.session,
            DeleteCloudWorkspaceRequest(
              workspaceId: fixture.workspaceId,
              confirmationName: 'Workspace',
              requestId: 'delete-workspace-with-background-work',
              expectedWorkspaceRevision: 1,
            ),
          );

          var storedWork = (await BackgroundWorkRecord.db.findFirstRow(
            fixture.database,
            where: (table) => table.stableId.equals(work.id),
          ))!;
          expect(storedWork.status, 'stopRequested');
          expect(storedWork.resultContent, isNull);
          final eventSequenceAfterRemoval = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationId,
          ))!.eventSequence;

          release.complete();
          for (var attempt = 0; attempt < 40; attempt++) {
            storedWork = (await BackgroundWorkRecord.db.findFirstRow(
              fixture.database,
              where: (table) => table.stableId.equals(work.id),
            ))!;
            if (storedWork.status != 'stopRequested') break;
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }

          expect(storedWork.status, 'failed');
          expect(storedWork.statusPreview, 'Outcome unknown');
          expect(storedWork.errorCode, 'outcome_unknown');
          expect(storedWork.resultContent, isNull);
          expect(storedWork.resultByteLength, 0);
          final completionEvents = await ConversationEvent.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationId) &
                table.eventId.equals('background-work-completion:${work.id}'),
          );
          final completionMessages = await ConversationMessage.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationId) &
                table.stableId.equals('background_work:${work.id}'),
          );
          final queuedMessage = await ConversationMessage.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.conversationId.equals(fixture.conversationId) &
                table.stableId.equals('message-behind-detached-work'),
          );
          final turns = await ConversationTurn.db.find(
            fixture.database,
            where: (table) =>
                table.conversationId.equals(fixture.conversationId),
          );
          final jobs = await ConversationJob.db.find(
            fixture.database,
            where: (table) => table.turnId.equals(fixture.turn.id),
          );
          final immutableCall = (await ConversationToolCall.db.findById(
            fixture.database,
            call.id!,
          ))!;
          final finalConversation = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationId,
          ))!;

          expect(completionEvents, isEmpty);
          expect(completionMessages, isEmpty);
          expect(queuedMessage?.status, ConversationStatuses.queued);
          expect(turns, hasLength(1));
          expect(jobs, hasLength(1));
          expect(finalConversation.eventSequence, eventSequenceAfterRemoval);
          expect(immutableCall.status, 'runningInBackground');
          expect(immutableCall.resultJson, acknowledgement);
        },
      );
    },
    ephemeralDatabase: true,
    rollbackDatabase: RollbackDatabase.disabled,
  );

  // Concurrent detaches and reconciliation need independent sessions and
  // committed writes; the rollback proxy serializes only one transaction.
  withServerpod(
    'ConversationBackgroundWork concurrent operations',
    (sessionBuilder, endpoints) {
      Future<_Fixture> prepare() =>
          _prepareConversationFixture(sessionBuilder, endpoints);

      test(
        'concurrent detaches across conversations share one global capacity',
        () async {
          final fixtures = <_Fixture>[];
          final requestCount = ConversationLimits.maxConcurrentDetachedWork + 2;
          for (var index = 0; index < requestCount; index++) {
            fixtures.add(await prepare());
          }
          final useCases = ConversationUseCases(
            conversation_repo.ConversationRepository(),
          );
          final requests =
              <
                ({
                  _Fixture fixture,
                  DetachToolCallRequest request,
                })
              >[];
          final now = DateTime.now().toUtc();
          for (var index = 0; index < fixtures.length; index++) {
            final fixture = fixtures[index];
            final message = fixture.messages.first;
            final toolCall = await ConversationToolCall.db.insertRow(
              fixture.database,
              ConversationToolCall(
                workspaceId: fixture.workspaceId,
                conversationId: fixture.conversationId,
                turnId: fixture.turn.id!,
                messageId: message.id!,
                stableId: 'background-global-capacity-$index',
                name: 'skill__app_native__agents__run_sub_agent',
                argumentsJson: '{}',
                argumentsDigest: 'digest',
                backgroundEligible: true,
                status: 'running',
                revision: 1,
                createdAt: now,
                updatedAt: now,
              ),
            );
            requests.add((
              fixture: fixture,
              request: DetachToolCallRequest(
                workspaceId: fixture.workspaceId,
                requestId: 'detach-global-capacity-$index',
                conversationId: 'conversation-1',
                toolCallId: toolCall.stableId,
              ),
            ));
          }

          Future<Object> attemptDetach(
            _Fixture fixture,
            DetachToolCallRequest request,
          ) async {
            try {
              return await useCases.detachToolCall(
                fixture.session.build(),
                userId: fixture.userId,
                request: request,
              );
            } on ConversationException catch (error) {
              return error;
            }
          }

          final outcomes = await Future.wait([
            for (final item in requests)
              attemptDetach(item.fixture, item.request),
          ]);
          final admitted = outcomes.whereType<BackgroundWorkView>();
          final rejected = outcomes.whereType<ConversationException>();

          expect(
            admitted,
            hasLength(ConversationLimits.maxConcurrentDetachedWork),
          );
          expect(rejected, hasLength(requestCount - admitted.length));
          expect(
            rejected.map((error) => error.code),
            everyElement(ConversationErrorCode.turnConflict),
          );
          expect(
            await BackgroundWorkRecord.db.count(
              fixtures.first.database,
              where: (table) =>
                  table.workspaceId.inSet(
                    fixtures.map((fixture) => fixture.workspaceId).toSet(),
                  ) &
                  table.status.equals('running'),
            ),
            ConversationLimits.maxConcurrentDetachedWork,
          );
        },
      );

      test(
        'restart reconciliation appends every unknown outcome once without replay',
        () async {
          final fixture = await prepare();
          final now = DateTime.now().toUtc();
          final message = fixture.messages.first;
          final workIds = [
            'background-work-restart-a',
            'background-work-restart-b',
          ];
          final calls = <ConversationToolCall>[];
          for (var index = 0; index < workIds.length; index++) {
            final workId = workIds[index];
            final callId = 'background-call-restart-$index';
            final acknowledgement = jsonEncode({
              'status': 'running_in_background',
              'work_id': workId,
            });
            final call = await ConversationToolCall.db.insertRow(
              fixture.database,
              ConversationToolCall(
                workspaceId: fixture.workspaceId,
                conversationId: fixture.conversationId,
                turnId: fixture.turn.id!,
                messageId: message.id!,
                stableId: callId,
                name: 'skill__app_native__agents__run_sub_agent',
                argumentsJson: '{}',
                argumentsDigest: 'digest',
                backgroundEligible: true,
                backgroundWorkStableId: workId,
                status: 'runningInBackground',
                resultJson: acknowledgement,
                revision: 2,
                createdAt: now,
                updatedAt: now,
              ),
            );
            calls.add(call);
            await BackgroundWorkRecord.db.insertRow(
              fixture.database,
              BackgroundWorkRecord(
                workspaceId: fixture.workspaceId,
                conversationId: fixture.conversationId,
                conversationToolCallId: call.id!,
                originatingMessageId: message.id!,
                stableId: workId,
                toolCallId: callId,
                toolKind: 'skillNative',
                runtimeServerId: fixture.database.serverpod.serverId,
                status: 'running',
                createdAt: now,
                updatedAt: now,
              ),
            );
          }

          final beforeQueue = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationId,
          ))!;
          await endpoints.conversation.queueConversationMessage(
            fixture.session,
            QueueConversationMessageRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'queue-before-parent-stop',
              conversationId: 'conversation-1',
              expectedProjectionRevision: beforeQueue.projectionRevision,
              clientMessageId: 'queued-after-parent-stop',
              content: 'Continue after the current work.',
              attachmentIds: const [],
            ),
          );
          final beforeStop = (await Conversation.db.findById(
            fixture.database,
            fixture.conversationId,
          ))!;
          await ConversationUseCases(
            conversation_repo.ConversationRepository(),
          ).stopConversation(
            fixture.database,
            userId: fixture.userId,
            request: StopConversationRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'stop-before-restart-reconciliation',
              conversationId: 'conversation-1',
              expectedProjectionRevision: beforeStop.projectionRevision,
            ),
          );

          final runtime = ServerToolRuntime();
          final reconciliationSessions = [
            fixture.session.build(),
            fixture.session.build(),
          ];
          await Future.wait([
            for (final session in reconciliationSessions)
              runtime.reconcileInterruptedBackgroundWork(
                session,
                startedAt: now.add(const Duration(seconds: 1)),
              ),
          ]);

          final completed = await BackgroundWorkRecord.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationId) &
                table.stableId.inSet(workIds.toSet()),
          );
          final events = await ConversationEvent.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationId) &
                table.kind.equals(
                  ConversationEventType.backgroundWorkCompleted,
                ),
            orderBy: (table) => table.sequence,
          );
          final completionMessages = await ConversationMessage.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationId) &
                table.stableId.inSet(
                  workIds.map((id) => 'background_work:$id').toSet(),
                ),
          );
          final storedCalls = await ConversationToolCall.db.find(
            fixture.database,
            where: (table) =>
                table.id.inSet(calls.map((call) => call.id!).toSet()),
          );
          final turns = await ConversationTurn.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationId),
          );
          final queuedMessage = await ConversationMessage.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.conversationId.equals(fixture.conversationId) &
                table.stableId.equals('queued-after-parent-stop'),
          );

          expect(completed, hasLength(2));
          expect(
            completed.map((work) => (work.status, work.errorCode)),
            everyElement(('failed', 'outcome_unknown')),
          );
          expect(
            completed.map((work) => work.statusPreview),
            everyElement(BackgroundWorkPreviews.queuedForContinuation),
          );
          expect(events, hasLength(2));
          expect(events[0].sequence, lessThan(events[1].sequence));
          expect(
            events.map((event) => event.eventId).toSet(),
            workIds.map((id) => 'background-work-completion:$id').toSet(),
          );
          expect(completionMessages, hasLength(2));
          expect(
            completionMessages.map((message) => message.status),
            everyElement(ConversationStatuses.queued),
          );
          expect(
            completionMessages.map((message) => message.stableId).toSet(),
            workIds.map((id) => 'background_work:$id').toSet(),
          );
          expect(
            completionMessages.map((message) => message.content),
            everyElement(contains('outcome is unknown')),
          );
          for (var index = 0; index < calls.length; index++) {
            final storedCall = storedCalls.singleWhere(
              (call) => call.id == calls[index].id,
            );
            expect(storedCall.status, 'runningInBackground');
            expect(
              storedCall.resultJson,
              jsonEncode({
                'status': 'running_in_background',
                'work_id': workIds[index],
              }),
            );
          }
          expect(turns, hasLength(1));
          expect(turns.single.cancellationRequestedAt, isNotNull);
          expect(queuedMessage?.status, ConversationStatuses.queued);
        },
      );
    },
    ephemeralDatabase: true,
    rollbackDatabase: RollbackDatabase.disabled,
  );

  // Both resumes claim one approved call at once on independent sessions.
  // The rollback test proxy supports only one concurrent transaction.
  withServerpod(
    'ConversationEngineHostRegression concurrent skill resumes',
    (sessionBuilder, endpoints) {
      test(
        'approved Connector command resumes once with recorded arguments',
        () async {
          final fixture = await _prepareConversationFixture(
            sessionBuilder,
            endpoints,
          );
          final assistant = fixture.messages.singleWhere(
            (message) => message.id == fixture.turn.assistantMessageId,
          );
          final arguments = <String, Object?>{
            'toolId': 'connector/duckduckgo/search',
            'args': {'query': 'nested query'},
          };
          Object? executedArguments;
          final claimsReached = Completer<void>();
          final releaseClaims = Completer<void>();
          var claimWaiters = 0;
          var executorInvocations = 0;
          final runtime = ServerToolRuntime(
            beforeApprovedClaim: () async {
              claimWaiters++;
              if (claimWaiters == 2) claimsReached.complete();
              await releaseClaims.future;
            },
            executor: (_, _, tool, request) async {
              executorInvocations++;
              expect(tool.descriptor.toolIdentifier, executeConnectorToolName);
              expect(request.name, executeConnectorToolName);
              executedArguments = request.arguments;
              return {'ok': true};
            },
          );

          final request = ServerToolRequest(
            id: 'approved-connector-command',
            name: executeConnectorToolName,
            arguments: arguments,
            userFacingDescription: 'Search with the Connector.',
          );
          expect(
            await runtime.handle(
              fixture.database,
              turn: fixture.turn,
              messageId: assistant.id!,
              request: request,
            ),
            ServerToolDisposition.awaitingApproval,
          );
          final pending = (await ConversationToolCall.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.stableId.equals('approved-connector-command'),
          ))!;
          expect(pending.name, executeConnectorToolName);
          expect(jsonDecode(pending.argumentsJson), arguments);
          expect(pending.userFacingDescription, request.userFacingDescription);
          await ConversationToolCall.db.updateRow(
            fixture.database,
            pending.copyWith(
              status: 'approved',
              decision: 'approve',
              updatedAt: DateTime.now().toUtc(),
            ),
          );

          Future<ServerToolDisposition> resume(Session session) =>
              runtime.handle(
                session,
                turn: fixture.turn,
                messageId: assistant.id!,
                request: request,
              );
          final firstResume = resume(fixture.session.build());
          final secondResume = resume(fixture.session.build());
          await claimsReached.future;
          releaseClaims.complete();
          expect(
            await Future.wait([firstResume, secondResume]),
            everyElement(ServerToolDisposition.completed),
          );

          expect(executedArguments, arguments);
          expect(executorInvocations, 1);
          final completed = await ConversationToolCall.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.stableId.equals('approved-connector-command'),
          );
          expect(completed?.status, 'success');
        },
      );
    },
    ephemeralDatabase: true,
    rollbackDatabase: RollbackDatabase.disabled,
  );

  // Background-eligible template calls execute on a separate session. These
  // tests need committed fixture writes and real transaction isolation.
  withServerpod(
    'ConversationBackgroundWork',
    (sessionBuilder, endpoints) {
      Future<_Fixture> prepare({String? languageCode}) =>
          _prepareConversationFixture(
            sessionBuilder,
            endpoints,
            languageCode: languageCode,
          );

      test(
        'cloud detach preserves its acknowledgement and runs past turn stop',
        () async {
          final fixture = await prepare(languageCode: 'es');
          final now = DateTime.now().toUtc();
          await WorkspaceResource.db.insertRow(
            fixture.database,
            WorkspaceResource(
              workspaceId: fixture.workspaceId,
              resourceKind: WorkspaceResourceKind.toolPermission,
              resourceId: 'run-sub-agent-permission',
              data: jsonEncode({
                'toolId': 'skill__app_native__agents__$runSubAgentToolName',
                'permissionMode': 'alwaysAllow',
                'isEnabled': true,
              }),
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          final entered = Completer<void>();
          final release = Completer<void>();
          bool? cancelledAfterDetach;
          final runtime = ServerToolRuntime(
            executor: (_, _, tool, request) async {
              expect(tool.descriptor.toolIdentifier, runSubAgentToolName);
              expect(request.name, tool.spec.name);
              entered.complete();
              await release.future;
              cancelledAfterDetach = await request.isCancelled?.call();
              return {'ok': true};
            },
          );
          final callTool =
              (await runtime.loadTools(
                fixture.database,
                workspaceId: fixture.workspaceId,
                conversationStableId: 'conversation-1',
              )).singleWhere(
                (candidate) =>
                    candidate.descriptor.toolIdentifier == runSubAgentToolName,
              );
          final assistant = fixture.messages.singleWhere(
            (message) => message.id == fixture.turn.assistantMessageId,
          );
          final handling = runtime.handle(
            fixture.database,
            turn: fixture.turn,
            messageId: assistant.id!,
            request: ServerToolRequest(
              id: 'background-cloud-call',
              name: callTool.spec.name,
              arguments: {
                'title': 'Research',
                'prompt': 'Search primary sources.',
                'agentId': null,
              },
              languageCode: 'es',
            ),
          );
          await entered.future.timeout(const Duration(seconds: 2));

          final request = DetachToolCallRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'detach-background-cloud-call',
            conversationId: 'conversation-1',
            toolCallId: 'background-cloud-call',
          );
          final nonMemberUserId = const Uuid().v4().toString();
          await AuthUser.db.insertRow(
            fixture.database,
            AuthUser(
              id: UuidValue.fromString(nonMemberUserId),
              scopeNames: const {},
            ),
          );
          await expectLater(
            ConversationUseCases(
              conversation_repo.ConversationRepository(),
            ).detachToolCall(
              fixture.database,
              userId: nonMemberUserId,
              request: request,
            ),
            throwsA(
              isA<ConversationException>().having(
                (error) => error.code,
                'code',
                ConversationErrorCode.permissionDenied,
              ),
            ),
          );

          final work = await endpoints.conversation.detachToolCall(
            fixture.session,
            request,
          );
          expect(work.status, 'running');
          await handling.timeout(const Duration(seconds: 2));
          final callAfterAcknowledgement = (await ConversationToolCall.db
              .findFirstRow(
                fixture.database,
                where: (table) =>
                    table.stableId.equals('background-cloud-call'),
              ))!;
          final acknowledgement = jsonEncode({
            'status': 'running_in_background',
            'work_id': work.id,
          });
          expect(callAfterAcknowledgement.backgroundEligible, isTrue);
          expect(callAfterAcknowledgement.status, 'runningInBackground');
          expect(callAfterAcknowledgement.resultJson, acknowledgement);
          expect(
            (await endpoints.conversation.listBackgroundWorks(
              fixture.session,
              ListBackgroundWorksRequest(
                workspaceId: fixture.workspaceId,
                conversationId: 'conversation-1',
              ),
            )).map((item) => item.id),
            [work.id],
          );

          await ConversationUseCases(
            conversation_repo.ConversationRepository(),
          ).cancelTurn(
            fixture.database,
            userId: fixture.userId,
            request: CancelTurnRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'stop-after-detach',
              turnId: fixture.turn.requestId,
              expectedTurnRevision: fixture.turn.revision,
            ),
          );
          release.complete();

          BackgroundWorkRecord? completed;
          for (var attempt = 0; attempt < 40; attempt++) {
            completed = await BackgroundWorkRecord.db.findFirstRow(
              fixture.database,
              where: (table) => table.stableId.equals(work.id),
            );
            if (completed?.status != 'running') break;
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
          expect(cancelledAfterDetach, isFalse);
          expect(completed?.status, 'completed');
          expect(
            completed?.statusPreview,
            BackgroundWorkPreviews.queuedForContinuation,
          );
          final visibleWorks = await endpoints.conversation.listBackgroundWorks(
            fixture.session,
            ListBackgroundWorksRequest(
              workspaceId: fixture.workspaceId,
              conversationId: 'conversation-1',
            ),
          );
          expect(visibleWorks.single.id, work.id);
          expect(visibleWorks.single.resultContent, contains('"ok":true'));
          final completionEvents = await ConversationEvent.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationId) &
                table.eventId.equals('background-work-completion:${work.id}'),
          );
          final completionMessages = await ConversationMessage.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationId) &
                table.stableId.equals('background_work:${work.id}'),
          );
          expect(completionEvents, hasLength(1));
          expect(
            jsonDecode(completionEvents.single.payloadJson)['languageCode'],
            'es',
          );
          expect(completionMessages, hasLength(1));
          expect(completionMessages.single.status, ConversationStatuses.queued);
          expect(completed?.resultContent, contains('"ok":true'));
          final immutableCall = (await ConversationToolCall.db.findById(
            fixture.database,
            callAfterAcknowledgement.id!,
          ))!;
          expect(immutableCall.status, 'runningInBackground');
          expect(immutableCall.resultJson, acknowledgement);
          final turns = await ConversationTurn.db.find(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.conversationId.equals(fixture.conversationId),
            orderBy: (table) => table.acceptedSequence,
          );
          expect(turns, hasLength(1));
          expect(turns.single.status, ConversationStatuses.cancelled);
        },
      );

      test('cloud stop request is scoped and idempotent', () async {
        final fixture = await prepare();
        final now = DateTime.now().toUtc();
        final message = fixture.messages.first;
        const workId = 'background-work-stop';
        const toolCallId = 'background-call-stop';
        const acknowledgement = '{"status":"running_in_background"}';
        final call = await ConversationToolCall.db.insertRow(
          fixture.database,
          ConversationToolCall(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            turnId: fixture.turn.id!,
            messageId: message.id!,
            stableId: toolCallId,
            name: 'skill__app_native__agents__run_sub_agent',
            argumentsJson: '{}',
            argumentsDigest: 'digest',
            backgroundEligible: true,
            backgroundWorkStableId: workId,
            status: 'runningInBackground',
            resultJson: acknowledgement,
            revision: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await BackgroundWorkRecord.db.insertRow(
          fixture.database,
          BackgroundWorkRecord(
            workspaceId: fixture.workspaceId,
            conversationId: fixture.conversationId,
            conversationToolCallId: call.id!,
            originatingMessageId: message.id!,
            stableId: workId,
            toolCallId: toolCallId,
            toolKind: 'skillNative',
            status: 'running',
            createdAt: now,
            updatedAt: now,
          ),
        );

        final request = StopBackgroundWorkRequest(
          requestId: 'stop-background-work',
          workspaceId: fixture.workspaceId,
          conversationId: 'conversation-1',
          workId: workId,
        );
        final requested = await endpoints.conversation.stopBackgroundWork(
          fixture.session,
          request,
        );
        expect(requested.status, 'stopRequested');
        final retried = await endpoints.conversation.stopBackgroundWork(
          fixture.session,
          request.copyWith(requestId: 'stop-background-work-retry'),
        );
        expect(retried.status, 'stopRequested');
        final storedCall = await ConversationToolCall.db.findById(
          fixture.database,
          call.id!,
        );
        expect(storedCall?.resultJson, acknowledgement);
        expect(storedCall?.backgroundWorkStableId, workId);
      });

      test(
        'historical direct Connector tool call is no longer executable',
        () async {
          final fixture = await prepare();
          final assistant = fixture.messages.singleWhere(
            (message) => message.id == fixture.turn.assistantMessageId,
          );
          final now = DateTime.now().toUtc();
          final connector = connectorDefinitions.singleWhere(
            (candidate) => candidate.identifier == 'duckduckgo',
          );
          final toolId = connectorToolId(connector, connector.tools.single);
          await ConversationToolCall.db.insertRow(
            fixture.database,
            ConversationToolCall(
              workspaceId: fixture.workspaceId,
              conversationId: fixture.conversationId,
              turnId: fixture.turn.id!,
              messageId: assistant.id!,
              stableId: 'historical-direct-call',
              name: toolId,
              argumentsJson: '{"query":"search"}',
              argumentsDigest: 'historical',
              status: 'approved',
              decision: 'approve',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          var executions = 0;
          final runtime = ServerToolRuntime(
            executor: (_, _, _, _) async {
              executions++;
              return {'unexpected': true};
            },
          );

          final advertisedNames = (await runtime.loadTools(
            fixture.database,
            workspaceId: fixture.workspaceId,
            conversationStableId: 'conversation-1',
          )).map((tool) => tool.spec.name);
          expect(advertisedNames, contains(executeConnectorToolName));
          expect(advertisedNames, isNot(contains(toolId)));
          await runtime.handle(
            fixture.database,
            turn: fixture.turn,
            messageId: assistant.id!,
            request: ServerToolRequest(
              id: 'historical-direct-call',
              name: toolId,
              arguments: const {'query': 'search'},
            ),
          );

          final persisted = await ConversationToolCall.db.findFirstRow(
            fixture.database,
            where: (table) => table.stableId.equals('historical-direct-call'),
          );
          expect(executions, 0);
          expect(persisted?.status, 'toolNotFound');
        },
      );
    },
    ephemeralDatabase: true,
    rollbackDatabase: RollbackDatabase.disabled,
  );
}

class const _AwaitingApprovalHost() implements ConversationEngineHost {
  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async => const ConversationEngineResult(
    content: '',
    finishReason: 'awaiting_approval',
    inputTokens: 0,
    outputTokens: 0,
    totalTokens: 0,
    awaitingApproval: true,
  );

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) => throw UnimplementedError();
}

class const _CompletingHost() implements ConversationEngineHost {
  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) async => const ConversationEngineResult(
    content: 'Child completed.',
    finishReason: 'stop',
    inputTokens: 0,
    outputTokens: 0,
    totalTokens: 0,
  );

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) => throw UnimplementedError();
}

class const _TransientFailingHost() implements ConversationEngineHost {
  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationProgressPublisher liveTurns,
    Future<void>? leaseLost,
  }) => throw const ProviderTransientFailureException('offline retry fixture');

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) => throw UnimplementedError();
}

class _EffectTrackingHost implements ConversationEngineHost {
  var calls = 0;

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
    return const ConversationEngineResult(
      content: 'Unexpected child execution.',
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
  }) => throw UnimplementedError();
}

class _BlockedCancellationProbe implements ConversationCancellationProbe {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<bool> isCancelled(Session session, int turnId) async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return (await ConversationTurn.db.findById(
          session,
          turnId,
        ))!.cancellationRequestedAt !=
        null;
  }
}

class _Fixture({
  required final dynamic session,
  required final Session database,
  required final String userId,
  required final int workspaceId,
  required final int conversationId,
  required final ConversationTurn turn,
  required final ConversationJob job,
  required var List<ConversationMessage> messages,
});

List<String?> _backgroundWorkStatusPreviews(
  List<ConversationEvent> events,
  String workId,
) {
  final previews = <String?>[];
  for (final event in events) {
    final payload = jsonDecode(event.payloadJson);
    if (payload is! Map<String, dynamic> || payload['workId'] != workId) {
      continue;
    }
    previews.add(payload['statusPreview'] as String?);
  }
  return previews;
}

class const _ImmediateAdmissionGate() implements ConversationAdmissionGate {
  @override
  Future<T> run<T>(
    Session session, {
    required ConversationJob job,
    required String providerId,
    required Future<T> Function(Future<void> admissionLost) body,
  }) => body(Future<void>.value());
}

class const _NoopProgressPublisher() implements ConversationProgressPublisher {
  @override
  Future<void> flush() async {}

  @override
  Future<void> queued() async {}

  @override
  Future<void> running() async {}

  @override
  Future<void> text(String text) async {}
}
