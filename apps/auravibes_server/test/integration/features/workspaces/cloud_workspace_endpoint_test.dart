import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('CloudWorkspaceEndpoint', (sessionBuilder, endpoints) {
    test('limits the number of workspaces owned by one account', () async {
      final userId = const Uuid().v4().toString();
      final authenticatedSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticatedSession.build();
      await AuthUser.db.insertRow(
        session,
        AuthUser(
          id: UuidValue.fromString(userId),
          scopeNames: const {},
        ),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: 'workspace-owner@example.com',
          passwordHash: 'unused',
        ),
      );

      for (
        var index = 0;
        index < workspace_repo.CloudWorkspaceRepository.maxOwnedWorkspaces;
        index += 1
      ) {
        await endpoints.cloudWorkspace.createWorkspace(
          authenticatedSession,
          CreateCloudWorkspaceRequest(
            name: 'Workspace $index',
            requestId: const Uuid().v4().toString(),
          ),
        );
      }

      expect(
        endpoints.cloudWorkspace.createWorkspace(
          authenticatedSession,
          CreateCloudWorkspaceRequest(
            name: 'One too many',
            requestId: const Uuid().v4().toString(),
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.conflict,
          ),
        ),
      );
      expect(
        await CloudWorkspace.db.count(
          session,
          where: (table) => table.ownerUserId.equals(userId),
        ),
        workspace_repo.CloudWorkspaceRepository.maxOwnedWorkspaces,
      );
    });
  });
}
