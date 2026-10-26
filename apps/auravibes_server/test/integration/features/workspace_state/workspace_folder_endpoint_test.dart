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
        expect(
          (jsonDecode(read.pages.single.resources.first.data)
              as Map)['canManageFolder'],
          isTrue,
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
        Future<PatchWorkspaceStateResponse> moveChild(
          String requestId,
          int revision,
          String? parentId,
        ) => endpoints.workspaceState.patch(
          authenticated,
          PatchWorkspaceStateRequest(
            workspaceId: workspace.id!,
            requestId: requestId,
            operations: [
              WorkspacePatchOperation(
                operation: .update,
                resourceKind: .folder,
                resourceId: 'child',
                expectedRevision: revision,
                data: jsonEncode({
                  'name': 'Renamed child',
                  'parentId': parentId,
                }),
                fieldMask: const [],
              ),
            ],
          ),
        );
        final moved = await moveChild('move-child', 1, null);
        expect(
          (moved.resources.single.resourceId, moved.resources.single.revision),
          ('child', 2),
        );
        expect(
          (jsonDecode(moved.resources.single.data) as Map)['name'],
          'Renamed child',
        );
        await expectLater(
          moveChild('stale-child', 1, 'parent'),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await create(other.id!, 'foreign-parent', null);
        await expectLater(
          moveChild('foreign-move', 2, 'foreign-parent'),
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
        final now = DateTime.now().toUtc();
        final member = await WorkspaceMember.db.insertRow(
          session,
          WorkspaceMember(
            workspaceId: workspace.id!,
            userId: outsiderId,
            role: 'member',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        Future<ReadWorkspaceStateResponse> readAsMember() =>
            endpoints.workspaceState.read(
              outsider,
              ReadWorkspaceStateRequest(
                workspaceId: workspace.id!,
                pages: [
                  WorkspaceResourcePageRequest(
                    resourceKind: .folder,
                    limit: 100,
                  ),
                ],
                eventLimit: 0,
              ),
            );
        final memberRead = await readAsMember();
        expect(
          (jsonDecode(memberRead.pages.single.resources.first.data)
              as Map)['canManageFolder'],
          isFalse,
        );
        Future<PatchWorkspaceStateResponse> memberMove(String id) =>
            endpoints.workspaceState.patch(
              outsider,
              PatchWorkspaceStateRequest(
                workspaceId: workspace.id!,
                requestId: id,
                operations: [
                  WorkspacePatchOperation(
                    operation: .update,
                    resourceKind: .folder,
                    resourceId: 'child',
                    expectedRevision: 2,
                    data: jsonEncode({
                      'name': 'Admin rename',
                      'parentId': 'parent',
                    }),
                    fieldMask: const [],
                  ),
                ],
              ),
            );
        await expectLater(
          memberMove('member-move-denied'),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final _ = await WorkspaceMember.db.updateRow(
          session,
          member.copyWith(role: 'admin'),
        );
        final adminRead = await readAsMember();
        expect(
          (jsonDecode(adminRead.pages.single.resources.first.data)
              as Map)['canManageFolder'],
          isTrue,
        );
        expect((await memberMove('admin-move')).resources.single.revision, 3);
        await expectLater(
          endpoints.workspaceState.patch(
            authenticated,
            PatchWorkspaceStateRequest(
              workspaceId: workspace.id!,
              requestId: 'mixed-missing-view',
              operations: [
                WorkspacePatchOperation(
                  operation: .create,
                  resourceKind: .folder,
                  resourceId: 'partial-folder',
                  data: jsonEncode({'name': 'Partial'}),
                  fieldMask: const [],
                ),
              ],
              viewMoves: [
                WorkspaceViewMove(id: 'missing-view', expectedRevision: 1),
              ],
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final afterMixed = await readAsMember();
        expect(
          afterMixed.pages.single.resources.any(
            (row) => row.resourceId == 'partial-folder',
          ),
          isFalse,
        );
      },
    );

    test('workspace snapshot reads reject erasure-pending data', () async {
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
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: '$userId@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Pending erasure',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      final now = DateTime.now().toUtc();
      await WorkspaceResource.db.insertRow(
        session,
        WorkspaceResource(
          workspaceId: workspace.id!,
          resourceKind: WorkspaceResourceKind.folder,
          resourceId: 'sensitive-folder',
          data: jsonEncode({'name': 'Sensitive folder'}),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await CloudWorkspace.db.updateRow(
        session,
        workspace.copyWith(erasureRequestedAt: now),
      );

      await expectLater(
        endpoints.workspaceState.read(
          authenticated,
          ReadWorkspaceStateRequest(
            workspaceId: workspace.id!,
            pages: [
              WorkspaceResourcePageRequest(
                resourceKind: WorkspaceResourceKind.folder,
                limit: 10,
              ),
            ],
            eventLimit: 10,
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );
    });
  });
}
