import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace folders', (sessionBuilder, endpoints) {
    test(
      'authenticated folder creation rejects foreign parents and cycles',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
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
            email: '$userId@example.com',
            passwordHash: 'unused',
          ),
        );
        final repository = workspace_repo.CloudWorkspaceRepository();
        final workspace = await repository.createWorkspace(
          session,
          name: 'Folders',
          ownerUserId: userId,
          now: DateTime.now().toUtc(),
        );
        final other = await repository.createWorkspace(
          session,
          name: 'Other',
          ownerUserId: userId,
          now: DateTime.now().toUtc(),
        );

        Future<PatchWorkspaceStateResponse> create(
          int workspaceId,
          String id,
          String? parentId,
        ) => endpoints.workspaceState.patch(
          authenticated,
          PatchWorkspaceStateRequest(
            workspaceId: workspaceId,
            requestId: const Uuid().v4().toString(),
            operations: [
              WorkspacePatchOperation(
                operation: .create,
                resourceKind: .folder,
                resourceId: id,
                data: jsonEncode({'name': id, 'parentId': parentId}),
                fieldMask: const [],
              ),
            ],
          ),
        );
        await create(workspace.id!, 'parent', null);
        await create(workspace.id!, 'child', 'parent');
        final read = await endpoints.workspaceState.read(
          authenticated,
          ReadWorkspaceStateRequest(
            workspaceId: workspace.id!,
            pages: [
              WorkspaceResourcePageRequest(resourceKind: .folder, limit: 100),
            ],
            eventLimit: 0,
          ),
        );
        expect(
          read.pages.single.resources.map((r) => r.resourceId),
          containsAll(['parent', 'child']),
        );
        await expectLater(
          create(other.id!, 'foreign', 'parent'),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceState.patch(
            authenticated,
            PatchWorkspaceStateRequest(
              workspaceId: workspace.id!,
              requestId: 'cycle',
              operations: [
                WorkspacePatchOperation(
                  operation: .update,
                  resourceKind: .folder,
                  resourceId: 'parent',
                  expectedRevision: 1,
                  data: jsonEncode({'name': 'parent', 'parentId': 'child'}),
                  fieldMask: const [],
                ),
              ],
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final outsiderId = const Uuid().v4().toString();
        await AuthUser.db.insertRow(
          session,
          AuthUser(
            id: UuidValue.fromString(outsiderId),
            scopeNames: const {},
          ),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(outsiderId),
            email: '$outsiderId@example.com',
            passwordHash: 'unused',
          ),
        );
        final outsider = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            outsiderId,
            const {},
          ),
        );
        await expectLater(
          endpoints.workspaceState.read(
            outsider,
            ReadWorkspaceStateRequest(
              workspaceId: workspace.id!,
              pages: [
                WorkspaceResourcePageRequest(resourceKind: .folder, limit: 100),
              ],
              eventLimit: 0,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceState.read(
            sessionBuilder,
            ReadWorkspaceStateRequest(
              workspaceId: workspace.id!,
              pages: [
                WorkspaceResourcePageRequest(resourceKind: .folder, limit: 100),
              ],
              eventLimit: 0,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
      },
    );
  });
}
