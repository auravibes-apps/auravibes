import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace CSV', (sessionBuilder, endpoints) {
    test(
      'authenticated preview leaves no records, events or replay receipt',
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
          name: 'Tables',
          ownerUserId: userId,
          now: DateTime.now().toUtc(),
        );

        Future<PatchWorkspaceStateResponse> patch(
          List<WorkspacePatchOperation> operations,
        ) => endpoints.workspaceState.patch(
          authenticated,
          PatchWorkspaceStateRequest(
            workspaceId: workspace.id!,
            requestId: const Uuid().v4().toString(),
            operations: operations,
          ),
        );
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'items',
            fieldMask: const [],
            data: jsonEncode({
              'name': 'Items',
              'parentId': null,
              'labelColumnId': 'title',
              'schemaRevision': 1,
              'columns': [
                {
                  'id': 'title',
                  'name': 'Title',
                  'type': 'text',
                  'unique': true,
                },
              ],
            }),
          ),
        ]);
        final request = PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: 'csv-preview',
          operations: [
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .tableRecord,
              resourceId: 'imported',
              fieldMask: const [],
              data: jsonEncode({
                'tableId': 'items',
                'schemaRevision': 1,
                'values': {'title': 'Imported'},
              }),
            ),
          ],
        );
        final before = await endpoints.workspaceState.read(
          authenticated,
          ReadWorkspaceStateRequest(
            workspaceId: workspace.id!,
            pages: [
              WorkspaceResourcePageRequest(
                resourceKind: .tableRecord,
                limit: 100,
              ),
            ],
            eventLimit: 100,
          ),
        );
        final preview = await endpoints.workspaceCsv.preview(
          authenticated,
          request,
        );
        expect(preview.resources.single.resourceId, 'imported');
        final after = await endpoints.workspaceState.read(
          authenticated,
          ReadWorkspaceStateRequest(
            workspaceId: workspace.id!,
            pages: [
              WorkspaceResourcePageRequest(
                resourceKind: .tableRecord,
                limit: 100,
              ),
            ],
            eventLimit: 100,
          ),
        );
        expect(after.pages.single.resources, isEmpty);
        expect(after.currentSequence, before.currentSequence);
        final committed = await endpoints.workspaceState.patch(
          authenticated,
          request,
        );
        expect(committed.resources.single.resourceId, 'imported');
        expect(committed.sequence, before.currentSequence + 1);
        await expectLater(
          endpoints.workspaceCsv.preview(
            authenticated,
            request.copyWith(
              viewMoves: [WorkspaceViewMove(id: 'view', expectedRevision: 1)],
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final duplicate = request.copyWith(
          requestId: 'csv-duplicate',
          operations: [
            request.operations.single.copyWith(resourceId: 'first-duplicate'),
            request.operations.single.copyWith(resourceId: 'second-duplicate'),
          ],
        );
        await expectLater(
          endpoints.workspaceCsv.preview(authenticated, duplicate),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceState.patch(authenticated, duplicate),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final stale = request.copyWith(
          requestId: 'stale-import',
          operations: [
            request.operations.single.copyWith(
              resourceId: 'stale-record',
              data: jsonEncode({
                'tableId': 'items',
                'schemaRevision': 1,
                'values': {'title': 'Another'},
              }),
            ),
          ],
        );
        await endpoints.workspaceCsv.preview(authenticated, stale);
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'items',
            expectedRevision: 1,
            fieldMask: const [],
            data: jsonEncode({
              'name': 'Items',
              'parentId': null,
              'labelColumnId': 'title',
              'schemaRevision': 2,
              'columns': [
                {
                  'id': 'title',
                  'name': 'Title',
                  'type': 'text',
                  'unique': true,
                },
                {'id': 'flag', 'name': 'Flag', 'type': 'checkbox'},
              ],
            }),
          ),
        ]);
        await expectLater(
          endpoints.workspaceState.patch(authenticated, stale),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.staleRevision,
            ),
          ),
        );
        final retained = await endpoints.workspaceState.read(
          authenticated,
          ReadWorkspaceStateRequest(
            workspaceId: workspace.id!,
            pages: [
              WorkspaceResourcePageRequest(
                resourceKind: .tableRecord,
                limit: 100,
              ),
            ],
            eventLimit: 100,
          ),
        );
        expect(retained.pages.single.resources.map((row) => row.resourceId), [
          'imported',
        ]);
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'source',
            fieldMask: const [],
            data: jsonEncode({
              'name': 'Source',
              'parentId': null,
              'labelColumnId': 'title',
              'schemaRevision': 1,
              'columns': [
                {'id': 'title', 'name': 'Title', 'type': 'text'},
                {
                  'id': 'link',
                  'name': 'Link',
                  'type': 'reference',
                  'targetTableId': 'items',
                },
              ],
            }),
          ),
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'source-row',
            fieldMask: const [],
            data: jsonEncode({
              'tableId': 'source',
              'schemaRevision': 1,
              'values': {'title': 'Source', 'link': 'imported'},
            }),
          ),
        ]);
        final target = jsonEncode({
          'kind': 'table',
          'id': 'items',
          'revision': 2,
        });
        final plan = jsonDecode(
          await endpoints.workspaceTrash.preview(
            authenticated,
            workspace.id!,
            target,
          ),
        ) as Map<String, dynamic>;
        final _ = await endpoints.workspaceTrash.trash(
          authenticated,
          WorkspaceTrashRequest(
            workspaceId: workspace.id!,
            requestId: 'csv-trash',
            targetJson: target,
            planToken: plan['planToken'] as String,
          ),
        );
        final proof = jsonDecode(
          await endpoints.workspaceTrash.deletedReference(
            authenticated,
            workspace.id!,
            'items',
            'imported',
          ),
        );
        expect(proof, isA<Map<String, dynamic>>());
        expect(
          await endpoints.workspaceTrash.deletedReference(
            authenticated,
            workspace.id!,
            'items',
            'missing',
          ),
          'null',
        );
        final exportPage = await endpoints.workspaceState.read(
          authenticated,
          ReadWorkspaceStateRequest(
            workspaceId: workspace.id!,
            pages: [
              WorkspaceResourcePageRequest(
                resourceKind: .tableRecord,
                limit: 100,
              ),
            ],
            eventLimit: 0,
          ),
        );
        final sourceRow = exportPage.pages.single.resources.single;
        expect(sourceRow.resourceId, 'source-row');
        expect(jsonDecode(sourceRow.data)['values']['link'], 'imported');
        final member = await WorkspaceMember.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id!) & row.userId.equals(userId),
        );
        await WorkspaceMember.db.updateRow(
          session,
          member!.copyWith(removedAt: DateTime.now().toUtc()),
        );
        await expectLater(
          endpoints.workspaceTrash.deletedReference(
            authenticated,
            workspace.id!,
            'items',
            'imported',
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceCsv.preview(authenticated, request),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.membershipRequired,
            ),
          ),
        );
        await expectLater(
          endpoints.workspaceState.patch(authenticated, request),
          throwsA(isA<CloudWorkspaceException>()),
        );
      },
    );
  });
}
