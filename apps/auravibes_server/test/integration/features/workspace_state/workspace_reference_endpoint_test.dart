import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart' as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Linked records', (builder, endpoints) {
    test('current grants hide labels, fields and counts while retaining links', () async {
      final ownerId = const Uuid().v4().toString();
      final memberId = const Uuid().v4().toString();
      final owner = builder.copyWith(authentication: AuthenticationOverride.authenticationInfo(ownerId, const {}));
      final member = builder.copyWith(authentication: AuthenticationOverride.authenticationInfo(memberId, const {}));
      final session = owner.build();
      for (final id in [ownerId, memberId]) {
        await AuthUser.db.insertRow(session, AuthUser(id: UuidValue.fromString(id), scopeNames: const {}));
        await EmailAccount.db.insertRow(session, EmailAccount(authUserId: UuidValue.fromString(id), email: '$id@example.com', passwordHash: 'unused'));
      }
      final workspace = await workspace_repo.CloudWorkspaceRepository().createWorkspace(session,
        name: 'Relations', ownerUserId: ownerId, now: DateTime.now().toUtc());
      final wid = workspace.id!;
      final now = DateTime.now().toUtc();
      await WorkspaceMember.db.insertRow(session, WorkspaceMember(workspaceId: wid,
        userId: memberId, role: 'member', revision: 1, createdAt: now, updatedAt: now));
      Future<PatchWorkspaceStateResponse> patch(List<WorkspacePatchOperation> operations) =>
        endpoints.workspaceState.patch(owner, PatchWorkspaceStateRequest(workspaceId: wid,
          requestId: const Uuid().v4().toString(), operations: operations));
      Map<String, Object?> schema(String name, {bool shared = true, bool source = false}) => {
        'name': name, 'labelColumnId': 'label', 'schemaRevision': 1,
        'memberAccess': {if (shared) memberId: 'edit'}, 'columns': [
          {'id': 'label', 'name': 'Name', 'type': 'text'},
          if (source) {'id': 'link', 'name': 'Links', 'type': 'reference', 'targetTableId': 'target', 'referenceMultiple': true},
        ],
      };
      await patch([_create(.table, 'target', schema('People')), _create(.table, 'source', schema('Tasks', source: true))]);
      await patch([_create(.tableRecord, 'person', {'tableId': 'target', 'schemaRevision': 1, 'values': {'label': 'Private Ada'}}),
        _create(.tableRecord, 'task', {'tableId': 'source', 'schemaRevision': 1, 'values': {'label': 'Work', 'link': ['person']}})]);
      final choices = await endpoints.workspaceReference.targets(member, wid, 'source', 'link', 'ada', null);
      expect(choices.map((row) => row.resourceId), ['person']);
      final reverse = await endpoints.workspaceReference.reverse(member, wid, 'target', 'person', null);
      expect(reverse.map((row) => row.resourceId), ['task']);
      await patch([WorkspacePatchOperation(operation: .update, resourceKind: .table, resourceId: 'target',
        expectedRevision: 1, data: jsonEncode(schema('People', shared: false)), fieldMask: const [])]);
      await expectLater(endpoints.workspaceReference.targets(member, wid, 'source', 'link', '', null), throwsA(isA<CloudWorkspaceException>()));
      await expectLater(endpoints.workspaceReference.reverse(member, wid, 'target', 'person', null), throwsA(isA<CloudWorkspaceException>()));
      final read = await endpoints.workspaceState.read(member, ReadWorkspaceStateRequest(workspaceId: wid,
        pages: [WorkspaceResourcePageRequest(resourceKind: .tableRecord, limit: 100)], eventLimit: 0));
      final visible = read.pages.single.resources.single;
      expect(visible.resourceId, 'task');
      expect((_data(visible)['values'] as Map).containsKey('link'), false);
      expect(jsonEncode(read.toJson()), isNot(contains('Private Ada')));
      final request = PatchWorkspaceStateRequest(workspaceId: wid, requestId: 'edit-hidden-link', operations: [
        WorkspacePatchOperation(operation: .update, resourceKind: .tableRecord, resourceId: 'task', expectedRevision: 1,
          data: jsonEncode({'tableId': 'source', 'schemaRevision': 1, 'values': {'label': 'Updated'}}), fieldMask: const []),
      ]);
      final updated = await endpoints.workspaceState.patch(member, request);
      expect((_data(updated.resources.single)['values'] as Map).containsKey('link'), false);
      final replay = await endpoints.workspaceState.patch(member, request);
      expect((_data(replay.resources.single)['values'] as Map).containsKey('link'), false);
      final ownerRead = await endpoints.workspaceState.read(owner, ReadWorkspaceStateRequest(workspaceId: wid,
        pages: [WorkspaceResourcePageRequest(resourceKind: .tableRecord, limit: 100)], eventLimit: 0));
      final retained = ownerRead.pages.single.resources.firstWhere((row) => row.resourceId == 'task');
      expect((_data(retained)['values'] as Map)['link'], ['person']);
      expect((_data(retained)['values'] as Map)['label'], 'Updated');
      await patch([WorkspacePatchOperation(operation: .update, resourceKind: .table, resourceId: 'target',
        expectedRevision: 2, data: jsonEncode(schema('People')), fieldMask: const [])]);
      expect((await endpoints.workspaceReference.targets(member, wid, 'source', 'link', '', null)).single.resourceId, 'person');
    });
  });
}

WorkspacePatchOperation _create(WorkspaceResourceKind kind, String id, Map<String, Object?> data) =>
  WorkspacePatchOperation(operation: .create, resourceKind: kind, resourceId: id, data: jsonEncode(data), fieldMask: const []);
Map<String, dynamic> _data(WorkspaceResource row) => jsonDecode(row.data) as Map<String, dynamic>;
