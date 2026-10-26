import 'dart:async';
import 'dart:convert';

import 'package:auravibes_server/src/features/model_connections/domain/virtual_workspace_model_selection.dart';
import 'package:auravibes_server/src/features/objects/object_scanner.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:auravibes_server/src/features/objects/object_use_cases.dart';
import 'package:auravibes_server/src/features/objects/testing/in_memory_object_store.dart';
import 'package:auravibes_server/src/features/workspace_state/repositories/workspace_state_repository.dart';
import 'package:auravibes_server/src/features/workspace_state/usecases/workspace_state_usecases.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/auth_services_test_helper.dart';
import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Account-owned write erasure fencing', (builder, endpoints) {
    test(
      'account deletion fences user-scoped workspace secret writes',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        session.passwords['workspaceSecretKey'] =
            'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
        final workspace = await _createSharedWorkspace(
          session,
          userId: userId,
          memberRole: 'admin',
        );
        initializeTestAuthServices(session.serverpod);

        final race = await _raceWithAccountDeletion(
          builder: builder,
          session: session,
          userId: userId,
          delete: () => endpoints.account.deleteCurrentUser(authenticated),
          write: () async {
            await WorkspaceStateUseCases(WorkspaceStateRepository()).putSecret(
              session,
              userId: userId,
              request: PutWorkspaceSecretRequest(
                workspaceId: workspace.id!,
                requestId: 'secret-write-race',
                secretKind: WorkspaceSecretKind.provider,
                scope: WorkspaceSecretScope.user,
                resourceId: 'provider-secret',
                secret: 'synthetic-secret',
              ),
            );
          },
        );

        _expectSerializedDeletion(race);
        expect(
          await WorkspaceSecret.db.find(
            session,
            where: (row) => row.ownerUserId.equals(userId),
          ),
          isEmpty,
        );
        expect(
          await WorkspaceMutationReceipt.db.find(
            session,
            where: (row) => row.actorUserId.equals(userId),
          ),
          isEmpty,
        );
      },
    );

    test('account deletion fences recent model selection writes', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      final workspace = await _createSharedWorkspace(
        session,
        userId: userId,
        memberRole: 'admin',
      );
      final now = DateTime.now().toUtc();
      await ApiModelProvider.db.insertRow(
        session,
        ApiModelProvider(
          providerId: 'erasure-test-provider',
          name: 'Erasure Test Provider',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await ApiModel.db.insertRow(
        session,
        ApiModel(
          providerId: 'erasure-test-provider',
          modelId: 'erasure-test-model',
          name: 'Erasure Test Model',
          limitContext: 4096,
          limitOutput: 1024,
          modalitiesInput: const ['text'],
          modalitiesOutput: const ['text'],
          costInput: 1,
          costCacheRead: 0,
          costOutput: 1,
          openWeights: false,
          supportsReasoning: false,
          isCanonical: true,
          supportsPriorityMode: false,
          supportsToolCalls: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await WorkspaceModelConnection.db.insertRow(
        session,
        WorkspaceModelConnection(
          workspaceId: workspace.id!,
          connectionId: 'erasure-test-connection',
          providerId: 'erasure-test-provider',
          name: 'Erasure Test Connection',
          hasSecret: false,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      initializeTestAuthServices(session.serverpod);
      final selectionId = VirtualWorkspaceModelSelectionId.encode(
        connectionId: 'erasure-test-connection',
        modelId: 'erasure-test-model',
      );

      final race = await _raceWithAccountDeletion(
        builder: builder,
        session: session,
        userId: userId,
        delete: () => endpoints.account.deleteCurrentUser(authenticated),
        write: () => endpoints.modelConnection.recordRecentSelection(
          authenticated,
          RecordRecentModelSelectionRequest(
            workspaceId: workspace.id!,
            selectionId: selectionId,
          ),
        ),
      );

      _expectSerializedDeletion(race);
      expect(
        await RecentModelSelection.db.find(
          session,
          where: (row) => row.userId.equals(userId),
        ),
        isEmpty,
      );
    });

    test('account deletion fences model connection creation', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      final workspace = await _createSharedWorkspace(
        session,
        userId: userId,
        memberRole: 'admin',
      );
      initializeTestAuthServices(session.serverpod);

      final race = await _raceWithAccountDeletion(
        builder: builder,
        session: session,
        userId: userId,
        delete: () => endpoints.account.deleteCurrentUser(authenticated),
        write: () async {
          await endpoints.modelConnection.create(
            authenticated,
            CreateModelConnectionRequest(
              workspaceId: workspace.id!,
              requestId: 'create-model-race',
              connectionId: 'race-connection',
              name: 'Race connection',
              providerId: 'openai',
            ),
          );
        },
      );

      _expectSerializedDeletion(race);
      final connection = await WorkspaceModelConnection.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) &
            row.connectionId.equals('race-connection'),
      );
      expect(connection != null, race.writeError == null);
    });

    test('account deletion fences object upload creation', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      final workspace = await _createSharedWorkspace(
        session,
        userId: userId,
        memberRole: 'admin',
      );
      initializeTestAuthServices(session.serverpod);
      final store = InMemoryObjectStore();
      final objects = ObjectUseCases(
        store: store,
        scanner: const UnconfiguredObjectScanner(),
      );

      final race = await _raceWithAccountDeletion(
        builder: builder,
        session: session,
        userId: userId,
        delete: () => endpoints.account.deleteCurrentUser(authenticated),
        write: () async {
          await objects.beginUpload(
            session,
            userId: userId,
            request: _beginUploadRequest(workspace.id!, 'begin-race'),
          );
        },
      );

      _expectSerializedDeletion(race);
      final uploadsBeforeRetry = await ObjectUpload.db.find(
        session,
        where: (row) => row.actorUserId.equals(userId),
      );
      await expectLater(
        objects.beginUpload(
          session,
          userId: userId,
          request: _beginUploadRequest(workspace.id!, 'begin-after-delete'),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.authenticationRequired,
          ),
        ),
      );
      expect(
        await ObjectUpload.db.find(
          session,
          where: (row) =>
              row.actorUserId.equals(userId) &
              row.requestId.equals('begin-after-delete'),
        ),
        isEmpty,
      );
      expect(uploadsBeforeRetry.length, lessThanOrEqualTo(1));
    });

    test(
      'account deletion fences in-flight object upload completion',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        final workspace = await _createSharedWorkspace(
          session,
          userId: userId,
          memberRole: 'admin',
        );
        final store = InMemoryObjectStore();
        final scanner = _BlockingObjectScanner();
        final objects = ObjectUseCases(store: store, scanner: scanner);
        final upload = await objects.beginUpload(
          session,
          userId: userId,
          request: _beginUploadRequest(workspace.id!, 'complete-race'),
        );
        final object = await WorkspaceObject.db.findById(
          session,
          upload.objectId,
        );
        expect(object, isNotNull);
        store.objects[object!.objectKey] = ObjectMetadata(
          sizeBytes: object.sizeBytes,
          mimeType: object.mimeType,
          checksumSha256: object.checksumSha256,
        );
        initializeTestAuthServices(session.serverpod);

        Object? completionError;
        final completing = objects
            .completeUpload(
              session,
              userId: userId,
              request: CompleteUploadRequest(
                workspaceId: workspace.id!,
                objectId: object.id!,
              ),
            )
            .then<void>(
              (_) {},
              onError: (Object error, StackTrace _) => completionError = error,
            );
        await scanner.started.future.timeout(const Duration(seconds: 5));
        await endpoints.account.deleteCurrentUser(authenticated);
        scanner.result.complete(ObjectScanResult.clean);
        await completing.timeout(const Duration(seconds: 10));

        expect(
          completionError,
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.authenticationRequired,
          ),
        );
        expect(
          (await WorkspaceObject.db.findById(session, object.id!))?.status,
          'pending',
        );
        expect(
          await WorkspaceEvent.db.find(
            session,
            where: (row) =>
                row.actorUserId.equals(userId) &
                row.resourceId.equals('${object.id}'),
          ),
          isEmpty,
        );
      },
    );

    test(
      'account deletion fences invite acceptance and membership writes',
      () async {
        final userId = const Uuid().v4().toString();
        final email = '$userId@example.invalid';
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        final workspace = await _createSharedWorkspace(
          session,
          userId: userId,
        );
        final now = DateTime.now().toUtc();
        final invite = await WorkspaceInvite.db.insertRow(
          session,
          WorkspaceInvite(
            workspaceId: workspace.id!,
            email: email,
            normalizedEmail: email.toLowerCase(),
            role: 'member',
            invitedByUserId: workspace.ownerUserId,
            revision: 1,
            createdAt: now,
            updatedAt: now,
            expiresAt: now.add(const Duration(days: 1)),
            pendingKey: '${workspace.id}:${email.toLowerCase()}',
          ),
        );
        initializeTestAuthServices(session.serverpod);

        final race = await _raceWithAccountDeletion(
          builder: builder,
          session: session,
          userId: userId,
          delete: () => endpoints.account.deleteCurrentUser(authenticated),
          write: () async {
            await endpoints.cloudWorkspace.acceptInvite(
              authenticated,
              AcceptWorkspaceInviteRequest(
                inviteId: invite.id!,
                requestId: 'accept-invite-race',
                expectedInviteRevision: invite.revision,
              ),
            );
          },
        );

        _expectSerializedDeletion(race);
        expect(
          await WorkspaceMember.db.findFirstRow(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.userId.equals(userId) &
                row.removedAt.equals(null),
          ),
          isNull,
        );
      },
    );

    test(
      'account deletion fences shared workspace conversation-context writes',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        final workspace = await _createSharedWorkspace(
          session,
          userId: userId,
          memberRole: 'admin',
        );
        final now = DateTime.now().toUtc();
        final conversation = await Conversation.db.insertRow(
          session,
          Conversation(
            workspaceId: workspace.id!,
            stableId: 'context-erasure-race',
            isPinned: false,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        initializeTestAuthServices(session.serverpod);

        final race = await _raceWithAccountDeletion(
          builder: builder,
          session: session,
          userId: userId,
          delete: () => endpoints.account.deleteCurrentUser(authenticated),
          write: () async {
            await endpoints.workspaceContext.save(
              authenticated,
              workspace.id!,
              conversation.stableId,
              'context-write-race',
              null,
            );
          },
        );

        _expectSerializedDeletion(race);
        final retainedContext = await WorkspaceConversationContext.db.find(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id!) &
              row.actorUserId.equals(userId),
        );
        expect(retainedContext, hasLength(race.writeError == null ? 1 : 0));
      },
    );

    test('account deletion fences conversation compaction writes', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      final workspace = await _createSharedWorkspace(
        session,
        userId: userId,
        memberRole: 'admin',
      );
      final now = DateTime.now().toUtc();
      await Conversation.db.insertRow(
        session,
        Conversation(
          workspaceId: workspace.id!,
          stableId: 'compact-erasure-race',
          isPinned: false,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      initializeTestAuthServices(session.serverpod);

      final race = await _raceWithAccountDeletion(
        builder: builder,
        session: session,
        userId: userId,
        delete: () => endpoints.account.deleteCurrentUser(authenticated),
        write: () async {
          await endpoints.conversation.compact(
            authenticated,
            CompactConversationRequest(
              workspaceId: workspace.id!,
              requestId: 'compact-request-race',
              conversationId: 'compact-erasure-race',
              expectedConversationRevision: 1,
            ),
          );
        },
      );

      _expectSerializedDeletion(race);
      final jobs = await ConversationJob.db.find(
        session,
        where: (row) => row.requestId.equals('compact-request-race'),
      );
      expect(jobs.length, race.writeError == null ? 1 : 0);
    });

    test('account deletion fences conversation cancellation writes', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      final workspace = await _createSharedWorkspace(
        session,
        userId: userId,
        memberRole: 'admin',
      );
      final now = DateTime.now().toUtc();
      final conversation = await Conversation.db.insertRow(
        session,
        Conversation(
          workspaceId: workspace.id!,
          stableId: 'cancel-erasure-race',
          isPinned: false,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await ConversationTurn.db.insertRow(
        session,
        ConversationTurn(
          workspaceId: workspace.id!,
          conversationId: conversation.id!,
          requestId: 'turn-erasure-race',
          requestHash: 'hash',
          initiatorUserId: userId,
          status: 'queued',
          revision: 1,
          acceptedSequence: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      initializeTestAuthServices(session.serverpod);

      final race = await _raceWithAccountDeletion(
        builder: builder,
        session: session,
        userId: userId,
        delete: () => endpoints.account.deleteCurrentUser(authenticated),
        write: () async {
          await endpoints.conversation.cancelTurn(
            authenticated,
            CancelTurnRequest(
              workspaceId: workspace.id!,
              requestId: 'cancel-request-race',
              turnId: 'turn-erasure-race',
              expectedTurnRevision: 1,
            ),
          );
        },
      );

      _expectSerializedDeletion(race);
      final turn = await ConversationTurn.db.findFirstRow(
        session,
        where: (row) => row.requestId.equals('turn-erasure-race'),
      );
      expect(
        turn!.status,
        race.writeError == null ? 'cancelled' : 'queued',
      );
    });

    test('account deletion fences content report submissions', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      final workspace = await _createSharedWorkspace(
        session,
        userId: userId,
        memberRole: 'admin',
      );
      final target = await _createAiReportTarget(
        session,
        workspaceId: workspace.id!,
        actorUserId: userId,
      );
      initializeTestAuthServices(session.serverpod);
      const reportId = '523e4567-e89b-12d3-a456-426614174000';

      final race = await _raceWithAccountDeletion(
        builder: builder,
        session: session,
        userId: userId,
        delete: () => endpoints.account.deleteCurrentUser(authenticated),
        write: () async {
          await endpoints.workspaceContentReport.submit(
            authenticated,
            workspace.id!,
            target,
            reportId,
          );
        },
      );

      _expectSerializedDeletion(race);
      final report = await WorkspaceContentReport.db.findFirstRow(
        session,
        where: (row) => row.reportId.equals(reportId),
      );
      if (race.writeError == null) {
        expect(report?.reporterUserId, userId);
      } else {
        expect(report, isNull);
      }
    });

    test('account deletion fences content report review writes', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      final workspace = await _createSharedWorkspace(
        session,
        userId: userId,
        memberRole: 'admin',
      );
      await _createAiReportTarget(
        session,
        workspaceId: workspace.id!,
        actorUserId: userId,
      );
      const reportId = '623e4567-e89b-12d3-a456-426614174000';
      await WorkspaceContentReport.db.insertRow(
        session,
        WorkspaceContentReport(
          workspaceId: workspace.id!,
          reportId: reportId,
          resourceKind: WorkspaceResourceKind.table,
          resourceId: 'report-race-table',
          revision: 1,
          reporterUserId: const Uuid().v4().toString(),
          status: 'submitted',
          submittedAt: DateTime.now().toUtc(),
        ),
      );
      initializeTestAuthServices(session.serverpod);

      final race = await _raceWithAccountDeletion(
        builder: builder,
        session: session,
        userId: userId,
        delete: () => endpoints.account.deleteCurrentUser(authenticated),
        write: () async {
          await endpoints.workspaceContentReport.resolve(
            authenticated,
            workspace.id!,
            reportId,
            'dismiss',
          );
        },
      );

      _expectSerializedDeletion(race);
      final report = await WorkspaceContentReport.db.findFirstRow(
        session,
        where: (row) => row.reportId.equals(reportId),
      );
      expect(report, isNotNull);
      if (race.writeError == null) {
        expect(report!.reviewerUserId, userId);
      } else {
        expect(report!.reviewerUserId, isNull);
      }
      expect(
        report.status,
        race.writeError == null ? 'dismissed' : 'submitted',
      );
    });

    test(
      'account deletion fences workspace-view receipt writes',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        final workspace = await _createSharedWorkspace(
          session,
          userId: userId,
          memberRole: 'admin',
        );
        final now = DateTime.now().toUtc();
        await WorkspaceResource.db.insertRow(
          session,
          WorkspaceResource(
            workspaceId: workspace.id!,
            resourceKind: WorkspaceResourceKind.table,
            resourceId: 'receipt-race-table',
            data: jsonEncode({
              'name': 'Items',
              'labelColumnId': 'label',
              'schemaRevision': 1,
              'columns': [
                {'id': 'label', 'name': 'Title', 'type': 'text'},
              ],
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        initializeTestAuthServices(session.serverpod);

        final race = await _raceWithAccountDeletion(
          builder: builder,
          session: session,
          userId: userId,
          delete: () => endpoints.account.deleteCurrentUser(authenticated),
          write: () async {
            await endpoints.workspaceView.save(
              authenticated,
              WorkspaceViewSaveRequest(
                requestId: 'view-write-race',
                workspaceId: workspace.id!,
                viewId: 'erasure-race-view',
                expectedRevision: 0,
                definition: jsonEncode({
                  'id': 'erasure-race-view',
                  'name': 'Overview',
                  'tableId': 'receipt-race-table',
                  'parentId': null,
                  'bindings': {'title': 'label'},
                  'columnTypes': {'label': 'text'},
                  'revision': 0,
                  'definition': {
                    'version': 1,
                    'components': [
                      {
                        'id': 'root',
                        'component': 'Text',
                        'text': {'path': '/title'},
                      },
                    ],
                  },
                }),
              ),
            );
          },
        );

        _expectSerializedDeletion(race);
        expect(
          await WorkspaceMutationReceipt.db.find(
            session,
            where: (row) => row.actorUserId.equals(userId),
          ),
          isEmpty,
        );
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}

Future<CloudWorkspace> _createSharedWorkspace(
  Session session, {
  required String userId,
  String? memberRole,
}) async {
  final ownerId = const Uuid().v4().toString();
  final now = DateTime.now().toUtc();
  await AuthUser.db.insertRow(
    session,
    AuthUser(id: UuidValue.fromString(ownerId), scopeNames: const {}),
  );
  final workspace = await workspace_repo.CloudWorkspaceRepository()
      .createWorkspace(
        session,
        name: 'Shared account erasure workspace',
        ownerUserId: ownerId,
        now: now,
      );
  await _insertAccount(session, userId, '$userId@example.invalid');
  if (memberRole != null) {
    await WorkspaceMember.db.insertRow(
      session,
      WorkspaceMember(
        workspaceId: workspace.id!,
        userId: userId,
        role: memberRole,
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
  return workspace;
}

Future<void> _insertAccount(
  Session session,
  String userId,
  String email,
) async {
  await AuthUser.db.insertRow(
    session,
    AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
  );
  await EmailAccount.db.insertRow(
    session,
    EmailAccount(
      authUserId: UuidValue.fromString(userId),
      email: email,
      passwordHash: 'unused',
    ),
  );
}

BeginUploadRequest _beginUploadRequest(int workspaceId, String requestId) =>
    BeginUploadRequest(
      workspaceId: workspaceId,
      requestId: requestId,
      purpose: 'chatAttachment',
      displayName: 'test.png',
      mimeType: 'image/png',
      sizeBytes: 4,
      checksumSha256: 'a' * 64,
    );

Future<String> _createAiReportTarget(
  Session session, {
  required int workspaceId,
  required String actorUserId,
}) async {
  final now = DateTime.now().toUtc();
  const resourceId = 'report-race-table';
  final data = jsonEncode({
    'name': 'Items',
    'labelColumnId': 'label',
    'schemaRevision': 1,
    'memberAccess': {actorUserId: 'read'},
    'columns': [
      {'id': 'label', 'name': 'Name', 'type': 'text'},
    ],
  });
  await WorkspaceResource.db.insertRow(
    session,
    WorkspaceResource(
      workspaceId: workspaceId,
      resourceKind: WorkspaceResourceKind.table,
      resourceId: resourceId,
      data: data,
      revision: 1,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await WorkspaceRevision.db.insertRow(
    session,
    WorkspaceRevision(
      workspaceId: workspaceId,
      resourceKind: WorkspaceResourceKind.table,
      resourceId: resourceId,
      revision: 1,
      data: data,
      capturedAt: now,
      actorUserId: actorUserId,
      aiInvolved: true,
      operation: 'create',
    ),
  );
  return jsonEncode({'kind': 'table', 'id': resourceId, 'revision': 1});
}

Future<_AccountDeletionRace> _raceWithAccountDeletion({
  required TestSessionBuilder builder,
  required Session session,
  required String userId,
  required Future<void> Function() delete,
  required Future<void> Function() write,
}) async {
  final lockSession = builder.build();
  final lockAcquired = Completer<void>();
  final releaseLock = Completer<void>();
  final holdingLock = lockSession.db.transaction((transaction) async {
    final user = await AuthUser.db.findById(
      lockSession,
      UuidValue.fromString(userId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    expect(user, isNotNull);
    lockAcquired.complete();
    await releaseLock.future;
  });
  await lockAcquired.future.timeout(const Duration(seconds: 5));

  var writeFinished = false;
  Object? writeError;
  final writing = write().then<void>(
    (_) => writeFinished = true,
    onError: (Object error, StackTrace _) {
      writeError = error;
      writeFinished = true;
    },
  );
  var deletionFinished = false;
  Object? deletionError;
  final deleting = delete().then<void>(
    (_) => deletionFinished = true,
    onError: (Object error, StackTrace _) {
      deletionError = error;
      deletionFinished = true;
    },
  );
  await Future<void>.delayed(const Duration(milliseconds: 100));
  final writeWasBlocked = !writeFinished;
  final deletionWasBlocked = !deletionFinished;
  releaseLock.complete();
  await holdingLock.timeout(const Duration(seconds: 10));
  await Future.wait([writing, deleting]).timeout(const Duration(seconds: 10));

  return _AccountDeletionRace(
    writeWasBlocked: writeWasBlocked,
    deletionWasBlocked: deletionWasBlocked,
    writeError: writeError,
    deletionError: deletionError,
    authUserAfterDeletion: await AuthUser.db.findById(
      session,
      UuidValue.fromString(userId),
    ),
  );
}

void _expectSerializedDeletion(_AccountDeletionRace race) {
  expect(
    race.writeWasBlocked,
    isTrue,
    reason: 'write finished early; write error: ${race.writeError}',
  );
  expect(
    race.deletionWasBlocked,
    isTrue,
    reason: 'deletion finished early; deletion error: ${race.deletionError}',
  );
  expect(race.deletionError, isNull);
  expect(race.authUserAfterDeletion, isNull);
  expect(
    race.writeError,
    anyOf(
      isNull,
      isA<CloudWorkspaceException>().having(
        (error) => error.code,
        'code',
        CloudWorkspaceErrorCode.authenticationRequired,
      ),
      isA<CloudWorkspaceException>().having(
        (error) => error.code,
        'code',
        CloudWorkspaceErrorCode.permissionDenied,
      ),
      isA<ConversationException>().having(
        (error) => error.code,
        'code',
        ConversationErrorCode.permissionDenied,
      ),
    ),
  );
}

class _AccountDeletionRace {
  const _AccountDeletionRace({
    required this.writeWasBlocked,
    required this.deletionWasBlocked,
    required this.writeError,
    required this.deletionError,
    required this.authUserAfterDeletion,
  });

  final bool writeWasBlocked;
  final bool deletionWasBlocked;
  final Object? writeError;
  final Object? deletionError;
  final AuthUser? authUserAfterDeletion;
}

class _BlockingObjectScanner implements ObjectScanner {
  final started = Completer<void>();
  final result = Completer<ObjectScanResult>();

  @override
  Future<ObjectScanResult> scan({
    required String objectKey,
    required String checksumSha256,
  }) {
    started.complete();
    return result.future;
  }
}
