import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace trash', (builder, endpoints) {
    test(
      'folder trash is atomic and recovery checks current membership',
      () async {
        final ownerId = const Uuid().v4().toString();
        final owner = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            ownerId,
            const {},
          ),
        );
        final session = owner.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(ownerId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(ownerId),
            email: '$ownerId@example.com',
            passwordHash: 'unused',
          ),
        );
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Trash',
              ownerUserId: ownerId,
              now: DateTime.now().toUtc(),
            );
        final wid = workspace.id!;
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
        Future<Map<String, dynamic>> trashTarget(
          String kind,
          String id,
          int revision, {
          String? tableId,
        }) async {
          final encoded = jsonEncode({
            'kind': kind,
            'id': id,
            'revision': revision,
            'tableId': ?tableId,
          });
          final plan = jsonDecode(
            await endpoints.workspaceTrash.preview(owner, wid, encoded),
          ) as Map<String, dynamic>;
          return jsonDecode(
            await endpoints.workspaceTrash.trash(
              owner,
              WorkspaceTrashRequest(
                workspaceId: wid,
                requestId: const Uuid().v4().toString(),
                targetJson: encoded,
                planToken: plan['planToken'] as String,
              ),
            ),
          ) as Map<String, dynamic>;
        }

        await endpoints.workspaceState.patch(
          owner,
          PatchWorkspaceStateRequest(
            workspaceId: wid,
            requestId: 'create',
            operations: [
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
                data: jsonEncode({
                  'name': 'Table',
                  'parentId': 'folder',
                  'labelColumnId': 'label',
                  'schemaRevision': 1,
                  'columns': [
                    {'id': 'label', 'name': 'Name', 'type': 'text'},
                  ],
                }),
                fieldMask: const [],
              ),
              WorkspacePatchOperation(
                operation: .create,
                resourceKind: .tableRecord,
                resourceId: 'record',
                data: jsonEncode({
                  'tableId': 'table',
                  'schemaRevision': 1,
                  'values': {'label': 'Retained'},
                }),
                fieldMask: const [],
              ),
            ],
          ),
        );
        final _ = await patch([
          create(.tableRecord, 'earlier', {
            'tableId': 'table',
            'schemaRevision': 1,
            'values': {'label': 'Earlier'},
          }),
          create(.table, 'outside', {
            'name': 'Outside',
            'labelColumnId': 'label',
            'schemaRevision': 1,
            'columns': [
              {'id': 'label', 'name': 'Name', 'type': 'text'},
              {
                'id': 'link',
                'name': 'Link',
                'type': 'reference',
                'targetTableId': 'table',
              },
            ],
          }),
          create(.tableRecord, 'outside-record', {
            'tableId': 'outside',
            'schemaRevision': 1,
            'values': {'label': 'Outside', 'link': 'record'},
          }),
        ]);
        final earlierBatch = await trashTarget(
          'record',
          'earlier',
          1,
          tableId: 'table',
        );
        final viewRequest = WorkspaceViewSaveRequest(
          workspaceId: wid,
          viewId: 'view',
          requestId: 'create-view',
          expectedRevision: 0,
          definition: jsonEncode({
            'id': 'view',
            'name': 'Overview',
            'tableId': 'table',
            'parentId': 'folder',
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
          }),
        );
        final _ = await endpoints.workspaceView.save(owner, viewRequest);
        final ownerMember = await WorkspaceMember.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(wid) & row.userId.equals(ownerId),
        );
        final target = jsonEncode({
          'kind': 'folder',
          'id': 'folder',
          'revision': 1,
        });
        final preview = jsonDecode(
          await endpoints.workspaceTrash.preview(owner, wid, target),
        ) as Map<String, dynamic>;
        final batch = jsonDecode(
          await endpoints.workspaceTrash.trash(
            owner,
            WorkspaceTrashRequest(
              workspaceId: wid,
              requestId: 'trash-op',
              targetJson: target,
              planToken: preview['planToken'] as String,
            ),
          ),
        ) as Map<String, dynamic>;
        expect(batch['affectedCount'], 4);
        await expectLater(
          endpoints.workspaceView.read(owner, wid, 'view'),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceView.history(owner, wid, 'view'),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceView.save(owner, viewRequest),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final _ = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: 'outside-record',
            expectedRevision: 1,
            data: jsonEncode({
              'tableId': 'outside',
              'schemaRevision': 1,
              'values': {
                'label': 'Edited while target trashed',
                'link': 'record',
              },
            }),
            fieldMask: const [],
          ),
        ]);
        final outsideState = await endpoints.workspaceState.read(
          owner,
          ReadWorkspaceStateRequest(
            workspaceId: wid,
            pages: [
              WorkspaceResourcePageRequest(
                resourceKind: .tableRecord,
                limit: 100,
              ),
            ],
            eventLimit: 0,
          ),
        );
        final outsideRow = outsideState.pages.single.resources.single;
        expect(outsideRow.resourceId, 'outside-record');
        expect(
          (jsonDecode(outsideRow.data)['values'] as Map)['link'],
          'record',
        );
        final replay = jsonDecode(
          await endpoints.workspaceTrash.trash(
            owner,
            WorkspaceTrashRequest(
              workspaceId: wid,
              requestId: 'trash-op',
              targetJson: target,
              planToken: preview['planToken'] as String,
            ),
          ),
        ) as Map<String, dynamic>;
        expect(replay['id'], batch['id']);
        final deleted = jsonDecode(
          await endpoints.workspaceTrash.deletedReference(
            owner,
            wid,
            'table',
            'record',
          ),
        ) as Map<String, dynamic>;
        expect(deleted['batchId'], batch['id']);
        expect(deleted['canRestore'], isTrue);
        await expectLater(
          endpoints.workspaceState.patch(
            owner,
            PatchWorkspaceStateRequest(
              workspaceId: wid,
              requestId: 'bypass',
              operations: [
                WorkspacePatchOperation(
                  operation: .delete,
                  resourceKind: .folder,
                  resourceId: 'folder',
                  expectedRevision: 2,
                  fieldMask: const [],
                ),
              ],
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final page = await endpoints.workspaceState.read(
          owner,
          ReadWorkspaceStateRequest(
            workspaceId: wid,
            pages: [
              WorkspaceResourcePageRequest(resourceKind: .folder, limit: 100),
            ],
            eventLimit: 0,
          ),
        );
        expect(page.pages.single.resources, isEmpty);
        await WorkspaceMember.db.updateRow(
          session,
          ownerMember!.copyWith(removedAt: DateTime.now().toUtc()),
        );
        await expectLater(
          endpoints.workspaceTrash.restore(owner, wid, batch['id'] as String),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceTrash.trash(
            owner,
            WorkspaceTrashRequest(
              workspaceId: wid,
              requestId: 'trash-op',
              targetJson: target,
              planToken: preview['planToken'] as String,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await WorkspaceMember.db.updateRow(
          session,
          ownerMember.copyWith(removedAt: null),
        );
        await endpoints.workspaceTrash.restore(
          owner,
          wid,
          batch['id'] as String,
        );
        await endpoints.workspaceTrash.restore(
          owner,
          wid,
          batch['id'] as String,
        );
        final restored = await endpoints.workspaceState.read(
          owner,
          ReadWorkspaceStateRequest(
            workspaceId: wid,
            pages: [
              WorkspaceResourcePageRequest(resourceKind: .folder, limit: 100),
            ],
            eventLimit: 0,
          ),
        );
        expect(restored.pages.single.resources.single.resourceId, 'folder');
        expect(
          (await endpoints.workspaceView.read(owner, wid, 'view')).revision,
          3,
        );
        final targets = await endpoints.workspaceReference.tableTargets(
          owner,
          WorkspaceReferenceTableRequest(
            workspaceId: wid,
            tableId: 'table',
            search: '',
          ),
        );
        expect(targets.map((row) => row.resourceId), ['record']);
        expect(
          (await endpoints.workspaceTrash.list(
            owner,
            wid,
          )).map((encoded) => jsonDecode(encoded)['id']),
          contains(earlierBatch['id']),
        );
        final _ = await patch([
          create(.folder, 'parent', {'name': 'Parent'}),
          create(.folder, 'child', {'name': 'Child', 'parentId': 'parent'}),
        ]);
        final staleTarget = jsonEncode({
          'kind': 'folder',
          'id': 'parent',
          'revision': 1,
        });
        final stalePlan = jsonDecode(
          await endpoints.workspaceTrash.preview(owner, wid, staleTarget),
        ) as Map<String, dynamic>;
        final _ = await patch([
          create(.folder, 'new-child', {
            'name': 'New child',
            'parentId': 'parent',
          }),
        ]);
        await expectLater(
          endpoints.workspaceTrash.trash(
            owner,
            WorkspaceTrashRequest(
              workspaceId: wid,
              requestId: 'stale-plan',
              targetJson: staleTarget,
              planToken: stalePlan['planToken'] as String,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final childBatch = await trashTarget('folder', 'child', 1);
        final parentBatch = await trashTarget('folder', 'parent', 1);
        final fallback = jsonDecode(
          await endpoints.workspaceTrash.restore(
            owner,
            wid,
            childBatch['id'] as String,
          ),
        ) as Map<String, dynamic>;
        expect(fallback['movedToRoot'], isTrue);
        final _ = await endpoints.workspaceTrash.restore(
          owner,
          wid,
          parentBatch['id'] as String,
        );
        final folders = await endpoints.workspaceState.read(
          owner,
          ReadWorkspaceStateRequest(
            workspaceId: wid,
            pages: [
              WorkspaceResourcePageRequest(resourceKind: .folder, limit: 100),
            ],
            eventLimit: 0,
          ),
        );
        final child = folders.pages.single.resources.singleWhere(
          (row) => row.resourceId == 'child',
        );
        expect(jsonDecode(child.data)['parentId'], isNull);
      },
    );
    test('record recovery uses current grants for read-only, revoked and editable members', () async {
      final ownerId = const Uuid().v4().toString();
      final memberId = const Uuid().v4().toString();
      final owner = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          ownerId,
          const {},
        ),
      );
      final member = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          memberId,
          const {},
        ),
      );
      final session = owner.build();
      for (final id in [ownerId, memberId]) {
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
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Grants',
            ownerUserId: ownerId,
            now: DateTime.now().toUtc(),
          );
      final wid = workspace.id!;
      final now = DateTime.now().toUtc();
      final _ = await WorkspaceMember.db.insertRow(
        session,
        WorkspaceMember(
          workspaceId: wid,
          userId: memberId,
          role: 'member',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final schema = {
        'name': 'Owned',
        'labelColumnId': 'label',
        'schemaRevision': 1,
        'memberAccess': {memberId: 'edit'},
        'columns': [
          {'id': 'label', 'name': 'Name', 'type': 'text', 'unique': true},
        ],
      };
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
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .table,
          resourceId: 'table',
          data: jsonEncode(schema),
          fieldMask: const [],
        ),
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .tableRecord,
          resourceId: 'record',
          data: jsonEncode({
            'tableId': 'table',
            'schemaRevision': 1,
            'values': {'label': 'Record'},
          }),
          fieldMask: const [],
        ),
      ]);
      var revision = 1;
      Future<void> grant(String? access) async {
        final _ = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'table',
            expectedRevision: revision++,
            data: jsonEncode({
              ...schema,
              'memberAccess': {memberId: ?access},
            }),
            fieldMask: const [],
          ),
        ]);
      }

      final target = jsonEncode({
        'kind': 'record',
        'id': 'record',
        'tableId': 'table',
        'revision': 1,
      });
      final plan = jsonDecode(
        await endpoints.workspaceTrash.preview(member, wid, target),
      ) as Map<String, dynamic>;
      final batch = jsonDecode(
        await endpoints.workspaceTrash.trash(
          member,
          WorkspaceTrashRequest(
            workspaceId: wid,
            requestId: 'member-trash',
            targetJson: target,
            planToken: plan['planToken'] as String,
          ),
        ),
      ) as Map<String, dynamic>;
      final id = batch['id'] as String;
      await grant(null);
      expect(await endpoints.workspaceTrash.list(member, wid), isEmpty);
      expect(
        await endpoints.workspaceTrash.deletedReference(
          member,
          wid,
          'table',
          'record',
        ),
        'null',
      );
      await expectLater(
        endpoints.workspaceTrash.restore(member, wid, id),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        endpoints.workspaceTrash.trash(
          member,
          WorkspaceTrashRequest(
            workspaceId: wid,
            requestId: 'member-trash',
            targetJson: target,
            planToken: plan['planToken'] as String,
          ),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await grant('read');
      final readOnly = jsonDecode(
        (await endpoints.workspaceTrash.list(member, wid)).single,
      ) as Map<String, dynamic>;
      expect(readOnly['canRestore'], isFalse);
      expect(
        jsonDecode(
          await endpoints.workspaceTrash.deletedReference(
            member,
            wid,
            'table',
            'record',
          ),
        )['canRestore'],
        isFalse,
      );
      await expectLater(
        endpoints.workspaceTrash.restore(member, wid, id),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await grant('edit');
      final _ = await patch([
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .tableRecord,
          resourceId: 'replacement',
          data: jsonEncode({
            'tableId': 'table',
            'schemaRevision': 1,
            'values': {'label': 'Record'},
          }),
          fieldMask: const [],
        ),
      ]);
      await expectLater(
        endpoints.workspaceTrash.restore(member, wid, id),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final active = await endpoints.workspaceReference.tableTargets(
        member,
        WorkspaceReferenceTableRequest(
          workspaceId: wid,
          tableId: 'table',
          search: '',
        ),
      );
      expect(active.map((row) => row.resourceId), ['replacement']);
      final _ = await patch([
        WorkspacePatchOperation(
          operation: .update,
          resourceKind: .tableRecord,
          resourceId: 'replacement',
          expectedRevision: 1,
          data: jsonEncode({
            'tableId': 'table',
            'schemaRevision': 1,
            'values': {'label': 'Different'},
          }),
          fieldMask: const [],
        ),
      ]);
      final _ = await endpoints.workspaceTrash.restore(member, wid, id);
      expect(
        (await endpoints.workspaceReference.record(
          member,
          WorkspaceReferenceRecordRequest(
            workspaceId: wid,
            tableId: 'table',
            recordId: 'record',
          ),
        )).resourceId,
        'record',
      );
    });
  });
}
