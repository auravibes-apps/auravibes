import 'dart:typed_data';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/auth_services_test_helper.dart';
import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('AccountEndpoint', (sessionBuilder, endpoints) {
    test('requires authentication', () async {
      expect(
        endpoints.account.currentUser(sessionBuilder),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.authenticationRequired,
          ),
        ),
      );
    });

    test('requires an email account', () async {
      final userId = const Uuid().v4().toString();
      final authenticatedSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );

      expect(
        endpoints.account.currentUser(authenticatedSession),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.emailAccountRequired,
          ),
        ),
      );
    });

    test('returns the authenticated email account', () async {
      final userId = const Uuid().v4().toString();
      final authenticatedSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      await AuthUser.db.insertRow(
        authenticatedSession.build(),
        AuthUser(
          id: UuidValue.fromString(userId),
          scopeNames: const {},
        ),
      );
      await EmailAccount.db.insertRow(
        authenticatedSession.build(),
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: 'user@example.com',
          passwordHash: 'unused',
        ),
      );

      final account = await endpoints.account.currentUser(
        authenticatedSession,
      );

      expect(account.userId, userId);
      expect(account.email, 'user@example.com');
    });

    test(
      'account erasure removes personal access and secrets, not shared data',
      () async {
        final userId = const Uuid().v4().toString();
        final ownerId = const Uuid().v4().toString();
        final authenticatedSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticatedSession.build();
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
              name: 'Shared workspace',
              ownerUserId: ownerId,
              now: now,
            );
        await WorkspaceMember.db.insertRow(
          session,
          WorkspaceMember(
            workspaceId: workspace.id!,
            userId: userId,
            role: 'member',
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
            resourceId: 'shared-file',
            data: '{"name":"shared"}',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceSecret.db.insertRow(
          session,
          WorkspaceSecret(
            workspaceId: workspace.id!,
            secretKind: WorkspaceSecretKind.provider,
            scope: WorkspaceSecretScope.user,
            ownerUserId: userId,
            resourceId: 'provider-1',
            ciphertext: ByteData(1),
            nonce: ByteData(1),
            authenticationTag: ByteData(1),
            algorithm: 'test',
            keyVersion: 1,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceMutationReceipt.db.insertRow(
          session,
          WorkspaceMutationReceipt(
            workspaceId: workspace.id,
            scopeKey: 'workspace:${workspace.id}',
            actorUserId: userId,
            endpoint: 'test',
            requestId: 'request-1',
            requestHash: 'hash',
            responseJson: '{}',
            createdAt: now,
          ),
        );
        await WorkspaceAuditRecord.db.insertRow(
          session,
          WorkspaceAuditRecord(
            workspaceId: workspace.id!,
            sequence: 1,
            actorUserId: userId,
            operation: 'updated',
            createdAt: now,
          ),
        );
        await WorkspaceEvent.db.insertRow(
          session,
          WorkspaceEvent(
            eventId: const Uuid().v4().toString(),
            workspaceId: workspace.id!,
            sequence: 1,
            actorUserId: userId,
            kind: 'resourceUpdated',
            resourceKind: 'file',
            createdAt: now,
          ),
        );

        initializeTestAuthServices(session.serverpod);
        await endpoints.account.deleteCurrentUser(authenticatedSession);

        expect(
          await WorkspaceResource.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          hasLength(1),
        );
        expect(
          await WorkspaceMember.db.findFirstRow(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.userId.equals(userId),
          ),
          isNull,
        );
        expect(
          await WorkspaceSecret.db.findFirstRow(
            session,
            where: (row) => row.ownerUserId.equals(userId),
          ),
          isNull,
        );
        expect(
          await WorkspaceMutationReceipt.db.findFirstRow(
            session,
            where: (row) => row.actorUserId.equals(userId),
          ),
          isNull,
        );
        expect(
          await WorkspaceAuditRecord.db.findFirstRow(
            session,
            where: (row) => row.actorUserId.equals(userId),
          ),
          isNotNull,
        );
        expect(
          await WorkspaceEvent.db.findFirstRow(
            session,
            where: (row) => row.actorUserId.equals(userId),
          ),
          isNotNull,
        );
        expect(
          await AuthUser.db.findById(session, UuidValue.fromString(userId)),
          isNull,
        );
      },
    );
  });
}
