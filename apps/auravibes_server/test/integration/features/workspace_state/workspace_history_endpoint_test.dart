import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspaces;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace history', (builder, endpoints) {
    test('restore validates current revisions; purge denies old replay and identity reuse', () async {
      final ownerId = const Uuid().v4().toString();
      final owner = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          ownerId,
          const {},
        ),
      );
      final session = owner.build();
      final _ = await AuthUser.db.insertRow(
        session,
        AuthUser(id: UuidValue.fromString(ownerId), scopeNames: const {}),
      );
      final _ = await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(ownerId),
          email: '$ownerId@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspaces.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'History',
            ownerUserId: ownerId,
            now: DateTime.now().toUtc(),
          );
      final wid = workspace.id!;
      Future<PatchWorkspaceStateResponse> patch(
        List<WorkspacePatchOperation> operations,
        String requestId,
      ) => endpoints.workspaceState.patch(
        owner,
        PatchWorkspaceStateRequest(
          workspaceId: wid,
          requestId: requestId,
          operations: operations,
        ),
      );
      WorkspacePatchOperation create(
        WorkspaceResourceKind kind,
        String id,
        Map<String, Object?> data,
      ) => WorkspacePatchOperation(
        operation: .create,
        resourceKind: kind,
        resourceId: id,
        data: jsonEncode(data),
        fieldMask: const [],
      );
      final createRequest = [
        create(.table, 'table', {
          'name': 'Data',
          'labelColumnId': 'label',
          'schemaRevision': 1,
          'columns': [
            {'id': 'label', 'name': 'Name', 'type': 'text'},
          ],
        }),
        create(.tableRecord, 'record', {
          'tableId': 'table',
          'schemaRevision': 1,
          'values': {'label': 'First'},
        }),
      ];
      final _ = await patch(createRequest, 'create');
      final _ = await patch([
        WorkspacePatchOperation(
          operation: .update,
          resourceKind: .tableRecord,
          resourceId: 'record',
          expectedRevision: 1,
          data: jsonEncode({
            'tableId': 'table',
            'schemaRevision': 1,
            'values': {'label': 'Second'},
          }),
          fieldMask: const [],
        ),
      ], 'update');
      String target(int revision) => jsonEncode({
        'kind': 'record',
        'id': 'record',
        'tableId': 'table',
        'revision': revision,
      });
      final revisions = await endpoints.workspaceHistory.history(
        owner,
        wid,
        target(2),
      );
      expect(revisions.map((row) => jsonDecode(row)['revision']), [2, 1]);
      final _ = await patch([WorkspacePatchOperation(operation: .update, resourceKind: .table, resourceId: 'table', expectedRevision: 1, data: jsonEncode({'name': 'Data', 'labelColumnId': 'label', 'schemaRevision': 2, 'columns': [{'id': 'label', 'name': 'Renamed', 'type': 'text'}]}), fieldMask: const [])], 'rename-schema');
      await endpoints.workspaceHistory.restore(
        owner,
        WorkspaceHistoryRestoreRequest(workspaceId: wid, targetJson: target(2), revision: 1, requestId: 'restore'),
      );
      final restored = await endpoints.workspaceReference.record(
        owner,
        WorkspaceReferenceRecordRequest(
          workspaceId: wid,
          tableId: 'table',
          recordId: 'record',
        ),
      );
      expect(restored.revision, 3);
      expect(jsonDecode(restored.data)['values'], {'label': 'First'});
      await endpoints.workspaceHistory.restore(owner, WorkspaceHistoryRestoreRequest(workspaceId: wid, targetJson: jsonEncode({'kind': 'table', 'id': 'table', 'revision': 2}), revision: 1, requestId: 'restore-schema'));
      final schemaHistory = await endpoints.workspaceHistory.history(owner, wid, jsonEncode({'kind': 'table', 'id': 'table', 'revision': 3}));
      expect(schemaHistory.map((row) => jsonDecode(row)['revision']), [3, 2, 1]);
      expect(jsonDecode(schemaHistory.first)['data']['columns'][0]['name'], 'Name');

      await expectLater(
        endpoints.workspaceHistory.restore(owner, WorkspaceHistoryRestoreRequest(workspaceId: wid, targetJson: target(2), revision: 1, requestId: 'stale')),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        endpoints.workspaceHistory.history(owner, wid + 1, target(3)),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final plan = jsonDecode(
        await endpoints.workspaceTrash.preview(owner, wid, target(3)),
      ) as Map<String, dynamic>;
      final _ = await endpoints.workspaceTrash.trash(
        owner,
        WorkspaceTrashRequest(
          workspaceId: wid,
          requestId: 'trash',
          targetJson: target(3),
          planToken: plan['planToken'] as String,
        ),
      );
      await endpoints.workspaceHistory.permanentlyDelete(owner, wid, target(3));
      await expectLater(
        patch(createRequest, 'create'),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        patch([
          create(.tableRecord, 'record', {
            'tableId': 'table',
            'schemaRevision': 1,
            'values': {'label': 'Recreated'},
          }),
        ], 'recreate'),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final receipts = await WorkspaceMutationReceipt.db.find(
        session,
        where: (row) => row.workspaceId.equals(wid),
      );
      for (final receipt in receipts) {
        expect(receipt.responseJson, isNot(contains('First')));
        expect(receipt.responseJson, isNot(contains('Second')));
      }

      final viewRequest = WorkspaceViewSaveRequest(workspaceId: wid, requestId: 'create-view', viewId: 'view', expectedRevision: 0, definition: jsonEncode({'id': 'view', 'name': 'Overview', 'tableId': 'table', 'bindings': {'title': 'label'}, 'columnTypes': {'label': 'text'}, 'revision': 0, 'definition': {'version': 1, 'components': [{'id': 'root', 'component': 'Text', 'text': {'path': '/title'}}]}}));
      final view = await endpoints.workspaceView.save(owner, viewRequest);
      final viewTarget = jsonEncode({'kind': 'view', 'id': 'view', 'revision': view.revision});
      final viewPlan = jsonDecode(await endpoints.workspaceTrash.preview(owner, wid, viewTarget)) as Map<String, dynamic>;
      final _ = await endpoints.workspaceTrash.trash(owner, WorkspaceTrashRequest(workspaceId: wid, requestId: 'trash-view', targetJson: viewTarget, planToken: viewPlan['planToken'] as String));
      await endpoints.workspaceHistory.permanentlyDelete(owner, wid, viewTarget);
      await expectLater(endpoints.workspaceView.save(owner, viewRequest), throwsA(isA<CloudWorkspaceException>()));
      await expectLater(endpoints.workspaceView.save(owner, viewRequest.copyWith(requestId: 'recreate-view')), throwsA(isA<CloudWorkspaceException>()));
      final membership = await WorkspaceMember.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(wid) & row.userId.equals(ownerId),
      );
      final _ = await WorkspaceMember.db.deleteRow(session, membership!);
      await expectLater(
        endpoints.workspaceHistory.history(
          owner,
          wid,
          jsonEncode({'kind': 'table', 'id': 'table', 'revision': 1}),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        patch(createRequest, 'create'),
        throwsA(isA<CloudWorkspaceException>()),
      );
    });
    test('history hides revoked reference targets and retained hidden links block purge', () async {
      final ownerId = const Uuid().v4().toString();
      final readerId = const Uuid().v4().toString();
      final owner = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          ownerId,
          const {},
        ),
      );
      final reader = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          readerId,
          const {},
        ),
      );
      final session = owner.build();
      for (final id in [ownerId, readerId]) {
        final _ = await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(id), scopeNames: const {}),
        );
        final _ = await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(id),
            email: '$id@example.com',
            passwordHash: 'unused',
          ),
        );
      }
      final now = DateTime.now().toUtc();
      final workspace = await workspaces.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'References',
            ownerUserId: ownerId,
            now: now,
          );
      final wid = workspace.id!;
      final _ = await WorkspaceMember.db.insertRow(
        session,
        WorkspaceMember(
          workspaceId: wid,
          userId: readerId,
          role: 'member',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      WorkspacePatchOperation create(
        WorkspaceResourceKind kind,
        String id,
        Map<String, Object?> data,
      ) => WorkspacePatchOperation(
        operation: .create,
        resourceKind: kind,
        resourceId: id,
        data: jsonEncode(data),
        fieldMask: const [],
      );
      Future<PatchWorkspaceStateResponse> patch(
        List<WorkspacePatchOperation> operations,
      ) => endpoints.workspaceState.patch(
        owner,
        PatchWorkspaceStateRequest(
          workspaceId: wid,
          requestId: const Uuid().v4().toString(),
          operations: operations,
        ),
      );
      final _ = await patch([
        create(.table, 'targets', {
          'name': 'Targets',
          'labelColumnId': 'target-label',
          'schemaRevision': 1,
          'columns': [
            {'id': 'target-label', 'name': 'Name', 'type': 'text'},
          ],
        }),
        create(.tableRecord, 'hidden-target', {
          'tableId': 'targets',
          'schemaRevision': 1,
          'values': {'target-label': 'Secret label'},
        }),
        create(.table, 'sources', {
          'name': 'Sources',
          'labelColumnId': 'source-label',
          'schemaRevision': 1,
          'memberAccess': {readerId: 'edit'},
          'columns': [
            {'id': 'source-label', 'name': 'Name', 'type': 'text'},
            {
              'id': 'link',
              'name': 'Link',
              'type': 'reference',
              'targetTableId': 'targets',
            },
          ],
        }),
        create(.tableRecord, 'source', {
          'tableId': 'sources',
          'schemaRevision': 1,
          'values': {'source-label': 'Source', 'link': 'hidden-target'},
        }),
      ]);
      final _ = await patch([
        WorkspacePatchOperation(
          operation: .update,
          resourceKind: .tableRecord,
          resourceId: 'source',
          expectedRevision: 1,
          data: jsonEncode({
            'tableId': 'sources',
            'schemaRevision': 1,
            'values': {'source-label': 'Cleared'},
          }),
          fieldMask: const [],
        ),
      ]);
      final target = jsonEncode({
        'kind': 'record',
        'id': 'source',
        'tableId': 'sources',
        'revision': 2,
      });
      final history = await endpoints.workspaceHistory.history(
        reader,
        wid,
        target,
      );
      expect(history.length, 2);
      expect(history.join(), isNot(contains('hidden-target')));
      expect(history.join(), isNot(contains('Secret label')));
      await expectLater(
        endpoints.workspaceHistory.restore(
          reader,
          WorkspaceHistoryRestoreRequest(workspaceId: wid, targetJson: target, revision: 1, requestId: 'restore-hidden'),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final deletedTarget = jsonEncode({
        'kind': 'record',
        'id': 'hidden-target',
        'tableId': 'targets',
        'revision': 1,
      });
      final plan = jsonDecode(
        await endpoints.workspaceTrash.preview(owner, wid, deletedTarget),
      ) as Map<String, dynamic>;
      final _ = await endpoints.workspaceTrash.trash(
        owner,
        WorkspaceTrashRequest(
          workspaceId: wid,
          requestId: 'trash-hidden',
          targetJson: deletedTarget,
          planToken: plan['planToken'] as String,
        ),
      );
      await expectLater(
        endpoints.workspaceHistory.permanentlyDelete(owner, wid, deletedTarget),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        endpoints.workspaceHistory.permanentlyDelete(
          reader,
          wid,
          deletedTarget,
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      expect((await endpoints.workspaceTrash.list(owner, wid)).length, 1);
    });
  });
}
