import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as repository;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Atomic Directory moves', (builder, endpoints) {
    test(
      'mixed moves roll back, hash every item and reauthorize replay',
      () async {
        final owner = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: .authenticationInfo(owner, const {}),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          .new(id: .fromString(owner), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          .new(
            authUserId: .fromString(owner),
            email: '$owner@example.com',
            passwordHash: 'unused',
          ),
        );
        final workspace = await repository.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Directory',
              ownerUserId: owner,
              now: DateTime.now().toUtc(),
            );
        final schema = <String, Object?>{
          'name': 'Items',
          'labelColumnId': 'label',
          'schemaRevision': 1,
          'columns': [
            {'id': 'label', 'name': 'Title', 'type': 'text'},
          ],
        };
        Future<PatchWorkspaceStateResponse> patch(
          String requestId,
          List<WorkspacePatchOperation> operations, {
          List<WorkspaceViewMove>? viewMoves,
        }) => endpoints.workspaceState.patch(
          authenticated,
          .new(
            workspaceId: workspace.id!,
            requestId: requestId,
            operations: operations,
            viewMoves: viewMoves,
          ),
        );
        final createOperations = [
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .folder,
            resourceId: 'destination',
            data: jsonEncode({'name': 'Destination'}),
            fieldMask: const [],
          ),
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .folder,
            resourceId: 'folder',
            data: jsonEncode({'name': 'Folder'}),
            fieldMask: const [],
          ),
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'table',
            data: jsonEncode(schema),
            fieldMask: const [],
          ),
        ];
        final created = await patch('create-items', createOperations);
        final legacy = PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: 'create-items',
          operations: createOperations,
        ).toJson();
        final _ = legacy.remove('viewMoves');
        final legacyHash = base64UrlEncode(
          (await Sha256().hash(utf8.encode(jsonEncode(legacy)))).bytes,
        );
        final receipt = await WorkspaceMutationReceipt.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id!) &
              row.requestId.equals('create-items'),
        );
        expect(receipt?.requestHash, legacyHash);
        final legacyReplay = await patch(
          'create-items',
          createOperations,
          viewMoves: [],
        );
        expect(legacyReplay.sequence, created.sequence);
        final definition = {
          'id': 'view',
          'name': 'Overview',
          'tableId': 'table',
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
        };
        final _ = await endpoints.workspaceView.save(
          authenticated,
          .new(
            requestId: 'create-view',
            workspaceId: workspace.id!,
            viewId: 'view',
            expectedRevision: 0,
            definition: jsonEncode(definition),
          ),
        );
        List<WorkspacePatchOperation> operations({int folderRevision = 1}) => [
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .folder,
            resourceId: 'folder',
            data: jsonEncode({'name': 'Folder', 'parentId': 'destination'}),
            fieldMask: const [],
            expectedRevision: folderRevision,
          ),
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'table',
            data: jsonEncode({...schema, 'parentId': 'destination'}),
            fieldMask: const [],
            expectedRevision: 1,
          ),
        ];
        Future<WorkspaceView> view() =>
            endpoints.workspaceView.read(authenticated, workspace.id!, 'view');
        Future<WorkspaceResource> folder() async {
          final response = await endpoints.workspaceState.read(
            authenticated,
            .new(
              workspaceId: workspace.id!,
              pages: [
                WorkspaceResourcePageRequest(resourceKind: .folder, limit: 100),
              ],
              eventLimit: 0,
            ),
          );

          return response.pages.single.resources.singleWhere(
            (row) => row.resourceId == 'folder',
          );
        }

        await expectLater(
          patch(
            'stale-view',
            operations(),
            viewMoves: [
              WorkspaceViewMove(
                id: 'view',
                expectedRevision: 999,
                parentId: 'destination',
              ),
            ],
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        expect((await folder()).revision, 1);
        expect((await view()).revision, 1);
        final moves = [
          WorkspaceViewMove(
            id: 'view',
            expectedRevision: 1,
            name: 'Renamed overview',
            parentId: 'destination',
          ),
        ];
        final first = await patch('mixed', operations(), viewMoves: moves);
        expect((await folder()).revision, 2);
        expect((await view()).revision, 2);
        expect(jsonDecode((await view()).data)['parentId'], 'destination');
        expect(jsonDecode((await view()).data)['bindings'], {'title': 'label'});
        expect(jsonDecode((await view()).data)['name'], 'Renamed overview');
        final replay = await patch('mixed', operations(), viewMoves: moves);
        expect(replay.sequence, first.sequence);
        expect((await view()).revision, 2);
        await expectLater(
          patch(
            'mixed',
            operations(),
            viewMoves: [
              WorkspaceViewMove(
                id: 'view',
                expectedRevision: 1,
                parentId: 'destination',
                name: 'Changed retry',
              ),
            ],
          ),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.idempotencyConflict,
            ),
          ),
        );
        final member = (await WorkspaceMember.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id!) & row.userId.equals(owner),
        ))!;
        final _ = await WorkspaceMember.db.updateRow(
          session,
          member.copyWith(role: 'admin'),
        );
        await expectLater(
          patch('mixed', operations(), viewMoves: moves),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final _ = await WorkspaceMember.db.updateRow(session, member);
        final only = await patch(
          'view-only',
          [],
          viewMoves: [WorkspaceViewMove(id: 'view', expectedRevision: 2)],
        );
        expect(only.resources, isEmpty);
        expect((await view()).revision, 3);
        expect(jsonDecode((await view()).data)['parentId'], isNull);
        await expectLater(
          patch(
            'stale-folder',
            operations(folderRevision: 999),
            viewMoves: [
              WorkspaceViewMove(
                id: 'view',
                expectedRevision: 3,
                parentId: 'destination',
              ),
            ],
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        expect((await view()).revision, 3);
        expect(jsonDecode((await view()).data)['parentId'], isNull);
        await expectLater(
          patch(
            'over-limit',
            operations(),
            viewMoves: .generate(
              49,
              (index) =>
                  WorkspaceViewMove(id: 'view-$index', expectedRevision: 1),
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
      },
    );
  });
}
