import 'dart:convert';

import 'package:auravibes_server/src/features/objects/object_cleanup_service.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:auravibes_server/src/features/objects/testing/in_memory_object_store.dart';
import 'package:auravibes_server/src/features/workers/worker_coordinator_repository.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/auth_services_test_helper.dart';
import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Cloud workspace erasure', (builder, endpoints) {
    test(
      'keeps a tombstone until retries erase assets and workspace data',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Erase me',
              ownerUserId: userId,
              now: now,
            );
        final legacyWorkspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Legacy deleted workspace',
              ownerUserId: userId,
              now: now,
            );
        await session.db.transaction((transaction) async {
          await workspace_repo.CloudWorkspaceRepository().softDeleteWorkspace(
            session,
            workspace: legacyWorkspace,
            now: now,
            transaction: transaction,
          );
        });
        final object = await WorkspaceObject.db.insertRow(
          session,
          WorkspaceObject(
            workspaceId: workspace.id!,
            objectKey: 'private/erase-me',
            purpose: 'workspace_asset',
            displayName: 'private.txt',
            mimeType: 'text/plain',
            sizeBytes: 4,
            checksumSha256: 'a' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceResource.db.insertRow(
          session,
          WorkspaceResource(
            workspaceId: workspace.id!,
            resourceKind: WorkspaceResourceKind.file,
            resourceId: 'file-1',
            data: jsonEncode({
              'assetId': '${object.id}',
              'name': 'private.txt',
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final request = EraseCloudWorkspaceRequest(
          workspaceId: workspace.id!,
          confirmationName: workspace.name,
          requestId: const Uuid().v4().toString(),
          expectedWorkspaceRevision: workspace.revision,
        );
        final initialStatus = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          request,
        );
        expect(initialStatus.state, 'pending');
        final legacyCandidates = await endpoints.cloudWorkspace
            .listOwnedDeletedWorkspacesForErasure(authenticated);
        expect(legacyCandidates, hasLength(1));
        expect(legacyCandidates.single.id, legacyWorkspace.id);

        final tombstone = await CloudWorkspace.db.findById(
          session,
          workspace.id!,
        );
        expect(tombstone?.deletedAt, isNotNull);
        expect(tombstone?.erasureRequestedAt, isNotNull);
        expect(
          await WorkspaceResource.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          hasLength(1),
        );
        expect(
          await WorkspaceSecret.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          isEmpty,
        );
        final deletion = await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        );
        expect(deletion?.objectKey, 'private/erase-me');

        final store = _RetryingObjectStore()
          ..objects['private/erase-me'] = ObjectMetadata(
            sizeBytes: 4,
            mimeType: 'text/plain',
            checksumSha256: 'a' * 64,
          );
        final lease = await const WorkerCoordinatorRepository()
            .acquireCoordinator(session, ownerId: 'erasure-test');
        expect(lease, isNotNull);
        final cleanup = ObjectCleanupService(store: store);

        await expectLater(
          endpoints.account.deleteCurrentUser(authenticated),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.workspaceErasurePending,
            ),
          ),
        );

        final otherUserId = const Uuid().v4().toString();
        final otherAccount = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            otherUserId,
            const {},
          ),
        );
        final otherSession = otherAccount.build();
        await AuthUser.db.insertRow(
          otherSession,
          AuthUser(id: UuidValue.fromString(otherUserId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          otherSession,
          EmailAccount(
            authUserId: UuidValue.fromString(otherUserId),
            email: '$otherUserId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        expect(
          await endpoints.cloudWorkspace.listWorkspaceErasures(otherAccount),
          isEmpty,
        );
        expect(
          await endpoints.cloudWorkspace.listOwnedDeletedWorkspacesForErasure(
            otherAccount,
          ),
          isEmpty,
        );
        await expectLater(
          endpoints.cloudWorkspace.retryWorkspaceErasure(
            otherAccount,
            RetryCloudWorkspaceErasureRequest(requestId: request.requestId),
          ),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.workspaceNotFound,
            ),
          ),
        );

        for (var attempt = 0; attempt < 8; attempt++) {
          await cleanup.runOnce(session, coordinator: lease!);
          final failedDeletion = await ObjectDeletion.db.findFirstRow(
            session,
            where: (row) => row.objectId.equals(object.id!),
          );
          expect(failedDeletion?.attempts, attempt + 1);
          await ObjectDeletion.db.updateRow(
            session,
            failedDeletion!.copyWith(availableAt: DateTime.now().toUtc()),
          );
        }
        final attention = await endpoints.cloudWorkspace.listWorkspaceErasures(
          authenticated,
        );
        expect(attention.single.state, 'needsAttention');
        final replay = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          request,
        );
        expect(replay.requestId, attention.single.requestId);
        expect(replay.workspaceId, attention.single.workspaceId);
        expect(replay.state, attention.single.state);
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );
        expect(
          await WorkspaceResource.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          hasLength(1),
        );

        final retried = await endpoints.cloudWorkspace.retryWorkspaceErasure(
          authenticated,
          RetryCloudWorkspaceErasureRequest(requestId: request.requestId),
        );
        expect(retried.state, 'pending');
        store.failDeletes = false;
        await cleanup.runOnce(session, coordinator: lease!);

        expect(store.deleteAttempts, 9);
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNull,
        );
        expect(
          await WorkspaceResource.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          isEmpty,
        );
        expect(await WorkspaceObject.db.findById(session, object.id!), isNull);
        final complete = await endpoints.cloudWorkspace.listWorkspaceErasures(
          authenticated,
        );
        expect(complete.single.state, 'complete');
        expect(complete.single.completedAt, isNotNull);
        await expectLater(
          endpoints.account.deleteCurrentUser(authenticated),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.ownershipTransferRequired,
            ),
          ),
        );
        final remainingOwned = await endpoints.cloudWorkspace
            .listOwnedDeletedWorkspacesForErasure(authenticated);
        expect(remainingOwned.single.id, legacyWorkspace.id);

        final legacyRequest = EraseCloudWorkspaceRequest(
          workspaceId: legacyWorkspace.id!,
          confirmationName: legacyWorkspace.name,
          requestId: const Uuid().v4().toString(),
          expectedWorkspaceRevision: legacyWorkspace.revision + 1,
        );
        final legacyComplete = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          legacyRequest,
        );
        expect(legacyComplete.state, 'complete');
        expect(
          await CloudWorkspace.db.findById(session, legacyWorkspace.id!),
          isNull,
        );

        initializeTestAuthServices(session.serverpod);
        await endpoints.account.deleteCurrentUser(authenticated);
        expect(
          await WorkspaceErasureRequest.db.find(
            session,
            where: (row) => row.ownerUserId.equals(userId),
          ),
          isEmpty,
        );
      },
    );
  });
}

class _RetryingObjectStore extends InMemoryObjectStore {
  bool failDeletes = true;
  int deleteAttempts = 0;

  @override
  Future<void> delete(String key) async {
    deleteAttempts++;
    if (failDeletes) throw StateError('temporary object-store failure');
    await super.delete(key);
  }
}
