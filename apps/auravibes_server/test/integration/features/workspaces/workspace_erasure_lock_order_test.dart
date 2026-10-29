import 'dart:async';

import 'package:auravibes_server/src/features/workers/worker_coordinator_repository.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/features/workspaces/workspace_erasure_cleanup.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Workspace erasure lock order',
    (builder, endpoints) {
      test(
        'cleanup and owner retry follow workspace then erasure lock order',
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
                name: 'Retry lock order',
                ownerUserId: userId,
                now: now,
              );
          await CloudWorkspace.db.updateRow(
            session,
            workspace.copyWith(
              revision: workspace.revision + 1,
              deletedAt: now,
              erasureRequestedAt: now,
              updatedAt: now,
            ),
          );
          final object = await WorkspaceObject.db.insertRow(
            session,
            WorkspaceObject(
              workspaceId: workspace.id!,
              objectKey: 'private/lock-order',
              purpose: 'workspace_asset',
              displayName: 'locked.txt',
              mimeType: 'text/plain',
              sizeBytes: 4,
              checksumSha256: 'a' * 64,
              status: 'deleting',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          final deletion = await ObjectDeletion.db.insertRow(
            session,
            ObjectDeletion(
              workspaceId: workspace.id!,
              objectId: object.id!,
              objectKey: object.objectKey,
              requestId: 'lock-order-delete-$userId',
              expectedRevision: object.revision,
              requestedAt: now,
              attempts: 8,
              availableAt: now,
              lastError: 'synthetic failure',
            ),
          );
          final requestId = 'lock-order-erasure-$userId';
          await WorkspaceErasureRequest.db.insertRow(
            session,
            WorkspaceErasureRequest(
              workspaceId: workspace.id!,
              workspaceName: workspace.name,
              ownerUserId: userId,
              requestId: requestId,
              requestHash: 'synthetic-hash',
              state: 'needsAttention',
              requestedAt: now,
              failureReason: 'objectCleanupFailed',
            ),
          );
          final lease = await const WorkerCoordinatorRepository()
              .acquireCoordinator(session, ownerId: 'erasure-lock-order-test');
          expect(lease, isNotNull);

          final deletionLockSession = builder.build();
          final deletionLocked = Completer<void>();
          final releaseDeletion = Completer<void>();
          final holdingDeletion = deletionLockSession.db.transaction((
            tx,
          ) async {
            final locked = await ObjectDeletion.db.findById(
              deletionLockSession,
              deletion.id!,
              transaction: tx,
              lockMode: LockMode.forUpdate,
            );
            expect(locked, isNotNull);
            deletionLocked.complete();
            await releaseDeletion.future;
          });
          await deletionLocked.future.timeout(const Duration(seconds: 5));

          final cleanup = WorkspaceErasureCleanup(builder.build()).purgeReady(
            lease!,
          );
          var cleanupLockedWorkspace = false;
          for (
            var attempt = 0;
            attempt < 50 && !cleanupLockedWorkspace;
            attempt++
          ) {
            cleanupLockedWorkspace = await _workspaceIsLocked(
              builder,
              workspace.id!,
            );
            if (!cleanupLockedWorkspace) {
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }
          }
          expect(cleanupLockedWorkspace, isTrue);
          final retry = endpoints.cloudWorkspace.retryWorkspaceErasure(
            authenticated,
            RetryCloudWorkspaceErasureRequest(requestId: requestId),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
          releaseDeletion.complete();

          final results = await Future.wait([cleanup, retry]).timeout(
            const Duration(seconds: 10),
          );
          await holdingDeletion.timeout(const Duration(seconds: 10));
          expect(results[0], 0);
          expect((results[1] as CloudWorkspaceErasureStatus).state, 'pending');
        },
        timeout: const Timeout(Duration(seconds: 20)),
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}

Future<bool> _workspaceIsLocked(
  TestSessionBuilder builder,
  int workspaceId,
) async {
  final session = builder.build();
  try {
    await session.db.transaction((transaction) async {
      await CloudWorkspace.db.findById(
        session,
        workspaceId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.noWait,
      );
    });
    return false;
  } on DatabaseQueryException catch (error) {
    if (error.code != '55P03') rethrow;
    return true;
  }
}
