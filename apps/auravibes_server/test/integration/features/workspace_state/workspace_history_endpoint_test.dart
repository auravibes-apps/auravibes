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
      await endpoints.workspaceHistory.restore(
        owner,
        wid,
        target(2),
        1,
        'restore',
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
      await expectLater(
        endpoints.workspaceHistory.restore(owner, wid, target(2), 1, 'stale'),
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
  });
}
