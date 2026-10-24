import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as repository;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Explicit item duplication', (builder, endpoints) {
    test('copies schema or records atomically; source auth precedes durable replay', () async {
      final owner = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          owner,
          const {},
        ),
      );
      final session = authenticated.build();
      await AuthUser.db.insertRow(
        session,
        AuthUser(id: UuidValue.fromString(owner), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(owner),
          email: '$owner@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await repository.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Copies',
            ownerUserId: owner,
            now: DateTime.now().toUtc(),
          );
      final workspaceId = workspace.id!;
      Future<PatchWorkspaceStateResponse> patch(
        List<WorkspacePatchOperation> operations,
      ) => endpoints.workspaceState.patch(
        authenticated,
        PatchWorkspaceStateRequest(
          workspaceId: workspaceId,
          requestId: const Uuid().v4().toString(),
          operations: operations,
        ),
      );
      WorkspacePatchOperation create(
        WorkspaceResourceKind kind,
        String id,
        Map<String, Object?> data,
      ) => .new(
        operation: .create,
        resourceKind: kind,
        resourceId: id,
        data: jsonEncode(data),
        fieldMask: const [],
      );
      await patch([
        create(.table, 'source', {
          'name': 'Source',
          'labelColumnId': 'label',
          'schemaRevision': 1,
          'columns': [
            {'id': 'label', 'name': 'Title', 'type': 'text', 'unique': true},
          ],
        }),
      ]);
      await patch([
        create(.tableRecord, 'first', {
          'tableId': 'source',
          'schemaRevision': 1,
          'values': {'label': 'Original'},
        }),
      ]);
      final copyColumns = [
        {'id': 'label', 'name': 'Title', 'type': 'text', 'unique': true},
        {
          'id': 'amount',
          'name': 'Amount',
          'type': 'number',
          'defaultValue': 42,
        },
      ];
      final _ = await patch([
        WorkspacePatchOperation(
          operation: .update,
          resourceKind: .table,
          resourceId: 'source',
          expectedRevision: 1,
          data: jsonEncode({
            'name': 'Source',
            'labelColumnId': 'label',
            'schemaRevision': 2,
            'columns': copyColumns,
          }),
          fieldMask: const [],
        ),
      ]);
      DuplicateWorkspaceItemRequest request(
        String target, {
        bool records = false,
        int revision = 2,
      }) => .new(
        workspaceId: workspaceId,
        requestId: target,
        sourceId: 'source',
        expectedRevision: revision,
        targetId: target,
        name: target,
        copyRecords: records,
      );
      final empty = await endpoints.workspaceState.duplicateTable(
        authenticated,
        request('empty'),
      );
      expect(empty.resources, hasLength(1));
      final emptyData = jsonDecode(empty.resources.single.data) as Map;
      expect(emptyData['labelColumnId'], 'empty-c0');
      expect(emptyData.containsKey('memberAccess'), isFalse);
      final full = await endpoints.workspaceState.duplicateTable(
        authenticated,
        request('full', records: true),
      );
      expect(full.resources, hasLength(2));
      final row = full.resources.singleWhere(
        (resource) => resource.resourceKind == .tableRecord,
      );
      expect(row.resourceId, isNot('first'));
      final copiedSchema = jsonDecode(
        full.resources
            .singleWhere((resource) => resource.resourceKind == .table)
            .data,
      ) as Map;
      expect((copiedSchema['columns'] as List).last['defaultValue'], 42);
      expect((jsonDecode(row.data) as Map)['values'], {
        'full-c0': 'Original',
      });
      final replay = await endpoints.workspaceState.duplicateTable(
        authenticated,
        request('full', records: true),
      );
      expect(replay.sequence, full.sequence);
      final trashTarget = jsonEncode({
        'kind': 'record',
        'id': row.resourceId,
        'tableId': 'full',
        'revision': row.revision,
      });
      final trashPreview = jsonDecode(
        await endpoints.workspaceTrash.preview(
          authenticated,
          workspaceId,
          trashTarget,
        ),
      ) as Map;
      final trashBatch = jsonDecode(
        await endpoints.workspaceTrash.trash(
          authenticated,
          WorkspaceTrashRequest(
            workspaceId: workspaceId,
            requestId: 'trash-copied-record',
            targetJson: trashTarget,
            planToken: trashPreview['planToken'] as String,
          ),
        ),
      ) as Map;
      await expectLater(
        endpoints.workspaceState.duplicateTable(
          authenticated,
          request('full', records: true),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );
      final _ = await endpoints.workspaceTrash.restore(
        authenticated,
        workspaceId,
        trashBatch['id'] as String,
      );
      final restoredReplay = await endpoints.workspaceState.duplicateTable(
        authenticated,
        request('full', records: true),
      );
      expect(restoredReplay.sequence, full.sequence);
      await expectLater(
        endpoints.workspaceState.duplicateTable(
          authenticated,
          request('stale', revision: 99),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.conflict,
          ),
        ),
      );
      await expectLater(
        endpoints.workspaceState.duplicateTable(authenticated, request('full')),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.idempotencyConflict,
          ),
        ),
      );
      final _ = await patch([
        create(.table, 'regions', {
          'name': 'Regions',
          'labelColumnId': 'region-label',
          'schemaRevision': 1,
          'columns': [
            {'id': 'region-label', 'name': 'Region', 'type': 'text'},
          ],
        }),
        create(.table, 'contacts', {
          'name': 'Contacts',
          'labelColumnId': 'contact-label',
          'schemaRevision': 1,
          'columns': [
            {'id': 'contact-label', 'name': 'Contact', 'type': 'text'},
            {
              'id': 'contact-region',
              'name': 'Region',
              'type': 'reference',
              'targetTableId': 'regions',
            },
          ],
        }),
        create(.table, 'dependent-source', {
          'name': 'Related',
          'labelColumnId': 'lead-label',
          'schemaRevision': 1,
          'columns': [
            {'id': 'lead-label', 'name': 'Title', 'type': 'text'},
            {
              'id': 'parent',
              'name': 'Region',
              'type': 'reference',
              'targetTableId': 'regions',
            },
            {
              'id': 'dependent',
              'name': 'Contact',
              'type': 'reference',
              'targetTableId': 'contacts',
              'dependsOnColumnId': 'parent',
              'targetMatchColumnId': 'contact-region',
            },
          ],
        }),
      ]);
      final _ = await patch([
        create(.tableRecord, 'region-record', {
          'tableId': 'regions',
          'schemaRevision': 1,
          'values': {'region-label': 'North'},
        }),
        create(.tableRecord, 'contact-record', {
          'tableId': 'contacts',
          'schemaRevision': 1,
          'values': {'contact-label': 'One', 'contact-region': 'region-record'},
        }),
        create(.tableRecord, 'lead-record', {
          'tableId': 'dependent-source',
          'schemaRevision': 1,
          'values': {
            'lead-label': 'Selected',
            'parent': 'region-record',
            'dependent': 'contact-record',
          },
        }),
      ]);
      final relatedCopy = await endpoints.workspaceState.duplicateTable(
        authenticated,
        DuplicateWorkspaceItemRequest(
          workspaceId: workspaceId,
          requestId: 'copy-related',
          sourceId: 'dependent-source',
          expectedRevision: 1,
          targetId: 'related-copy',
          name: 'Related copy',
          copyRecords: true,
        ),
      );
      final relatedSchema = jsonDecode(
        relatedCopy.resources
            .singleWhere((row) => row.resourceKind == .table)
            .data,
      ) as Map;
      final relatedColumns = relatedSchema['columns'] as List;
      expect(relatedColumns.last['dependsOnColumnId'], 'related-copy-c1');
      expect(relatedColumns.last['targetMatchColumnId'], 'contact-region');
      expect(relatedColumns.last['targetTableId'], 'contacts');
      final relatedValues = (jsonDecode(
        relatedCopy.resources
            .singleWhere((row) => row.resourceKind == .tableRecord)
            .data,
      ) as Map)['values'];
      expect(relatedValues, {
        'related-copy-c0': 'Selected',
        'related-copy-c1': 'region-record',
        'related-copy-c2': 'contact-record',
      });
      final reader = const Uuid().v4().toString();
      await AuthUser.db.insertRow(
        session,
        AuthUser(id: UuidValue.fromString(reader), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(reader),
          email: '$reader@example.com',
          passwordHash: 'unused',
        ),
      );
      final now = DateTime.now().toUtc();
      await WorkspaceMember.db.insertRow(
        session,
        WorkspaceMember(
          workspaceId: workspaceId,
          userId: reader,
          role: 'member',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final readerBuilder = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          reader,
          const {},
        ),
      );
      final definition = {
        'id': 'view',
        'name': 'Configured',
        'tableId': 'source',
        'parentId': null,
        'bindings': {'title': 'label'},
        'columnTypes': {'label': 'text'},
        'revision': 0,
        'query': {
          'search': 'Original',
          'limit': 12,
          'offset': 0,
          'descending': false,
          'filterOperator': 'equals',
        },
        'summaryColumnIds': ['label'],
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
      await endpoints.workspaceView.save(
        authenticated,
        WorkspaceViewSaveRequest(
          workspaceId: workspaceId,
          requestId: 'save-view',
          viewId: 'view',
          expectedRevision: 0,
          definition: jsonEncode(definition),
        ),
      );
      final viewRequest = DuplicateWorkspaceItemRequest(
        workspaceId: workspaceId,
        requestId: 'copy-view',
        sourceId: 'view',
        expectedRevision: 1,
        targetId: 'copied-view',
        name: 'Copied view',
      );
      final copiedView = await endpoints.workspaceView.duplicate(
        authenticated,
        viewRequest,
      );
      final copiedData = jsonDecode(copiedView.data) as Map;
      expect(copiedData['bindings'], definition['bindings']);
      expect(copiedData['columnTypes'], definition['columnTypes']);
      expect(copiedData['query'], definition['query']);
      expect(copiedData['summaryColumnIds'], ['label']);
      expect(copiedData['definition'], definition['definition']);
      await expectLater(
        endpoints.workspaceView.read(readerBuilder, workspaceId, 'copied-view'),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final schema = {
        'name': 'Source',
        'labelColumnId': 'label',
        'schemaRevision': 2,
        'columns': copyColumns,
        'memberAccess': {reader: 'read'},
      };
      await patch([
        WorkspacePatchOperation(
          operation: .update,
          resourceKind: .table,
          resourceId: 'source',
          expectedRevision: 2,
          data: jsonEncode(schema),
          fieldMask: const [],
        ),
      ]);
      expect(
        (await endpoints.workspaceView.read(
          readerBuilder,
          workspaceId,
          'copied-view',
        )).stableId,
        'copied-view',
      );
      final readerTables = await endpoints.workspaceState.read(
        readerBuilder,
        ReadWorkspaceStateRequest(
          workspaceId: workspaceId,
          pages: [
            WorkspaceResourcePageRequest(resourceKind: .table, limit: 100),
          ],
          eventLimit: 0,
        ),
      );
      expect(readerTables.pages.single.resources.map((row) => row.resourceId), [
        'source',
      ]);
      await patch([
        WorkspacePatchOperation(
          operation: .update,
          resourceKind: .table,
          resourceId: 'source',
          expectedRevision: 3,
          data: jsonEncode({...schema, 'memberAccess': <String, Object?>{}}),
          fieldMask: const [],
        ),
      ]);
      await expectLater(
        endpoints.workspaceView.read(readerBuilder, workspaceId, 'copied-view'),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final _ = await endpoints.workspaceView.save(
        authenticated,
        WorkspaceViewSaveRequest(
          workspaceId: workspaceId,
          requestId: 'edit-source-view',
          viewId: 'view',
          expectedRevision: 1,
          definition: jsonEncode({
            ...definition,
            'name': 'Changed source',
            'revision': 1,
          }),
        ),
      );
      final tableReplayAfterEdit = await endpoints.workspaceState
          .duplicateTable(authenticated, request('full', records: true));
      expect(tableReplayAfterEdit.sequence, full.sequence);
      final viewReplay = await endpoints.workspaceView.duplicate(
        authenticated,
        viewRequest,
      );
      expect(viewReplay.revision, 1);
      final member = await WorkspaceMember.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspaceId) & row.userId.equals(owner),
      );
      await WorkspaceMember.db.updateRow(
        session,
        member!.copyWith(role: 'member'),
      );
      await expectLater(
        endpoints.workspaceState.duplicateTable(
          authenticated,
          request('full', records: true),
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
