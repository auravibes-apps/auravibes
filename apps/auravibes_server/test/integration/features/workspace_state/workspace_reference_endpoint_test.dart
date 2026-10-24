import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Linked records', (builder, endpoints) {
    test(
      'current grants hide labels, fields and counts while retaining links',
      () async {
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
          await AuthUser.db.insertRow(
            session,
            AuthUser(id: UuidValue.fromString(id), scopeNames: const {}),
          );
          await EmailAccount.db.insertRow(
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
              name: 'Relations',
              ownerUserId: ownerId,
              now: DateTime.now().toUtc(),
            );
        final wid = workspace.id!;
        final now = DateTime.now().toUtc();
        await WorkspaceMember.db.insertRow(
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
        Map<String, Object?> schema(
          String name, {
          bool shared = true,
          bool source = false,
        }) => {
          'name': name,
          'labelColumnId': 'label',
          'schemaRevision': 1,
          'memberAccess': {if (shared) memberId: 'edit'},
          'columns': [
            {'id': 'label', 'name': 'Name', 'type': 'text'},
            if (source)
              {
                'id': 'link',
                'name': 'Links',
                'type': 'reference',
                'targetTableId': 'target',
                'referenceMultiple': true,
              },
          ],
        };
        await patch([
          _create(.table, 'target', schema('People')),
          _create(.table, 'source', schema('Tasks', source: true)),
        ]);
        await patch([
          _create(.tableRecord, 'person', {
            'tableId': 'target',
            'schemaRevision': 1,
            'values': {'label': 'Private Ada'},
          }),
          _create(.tableRecord, 'task', {
            'tableId': 'source',
            'schemaRevision': 1,
            'values': {
              'label': 'Work',
              'link': ['person'],
            },
          }),
        ]);
        final sourceSchema = schema('Tasks', source: true);
        sourceSchema['schemaRevision'] = 2;
        final linkColumn = (sourceSchema['columns'] as List).last as Map;
        linkColumn['required'] = true;
        linkColumn['defaultValue'] = ['person'];
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'source',
            expectedRevision: 1,
            data: jsonEncode(sourceSchema),
            fieldMask: const [],
          ),
        ]);
        expect(
          (await endpoints.workspaceReference.tableTargets(
            member,
            WorkspaceReferenceTableRequest(
              workspaceId: wid,
              tableId: 'target',
              search: 'Ada',
            ),
          )).single.resourceId,
          'person',
        );
        final choices = await endpoints.workspaceReference.targets(
          member,
          WorkspaceReferenceTargetRequest(
            workspaceId: wid,
            sourceTableId: 'source',
            columnId: 'link',
            search: 'ada',
            afterId: null,
          ),
        );
        expect(choices.map((row) => row.resourceId), ['person']);
        final reverse = await endpoints.workspaceReference.reverse(
          member,
          WorkspaceReferenceRecordRequest(
            workspaceId: wid,
            tableId: 'target',
            recordId: 'person',
            afterId: null,
          ),
        );
        expect(reverse.map((row) => row.resourceId), ['task']);
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'target',
            expectedRevision: 1,
            data: jsonEncode(schema('People', shared: false)),
            fieldMask: const [],
          ),
        ]);
        await expectLater(
          endpoints.workspaceReference.targets(
            member,
            WorkspaceReferenceTargetRequest(
              workspaceId: wid,
              sourceTableId: 'source',
              columnId: 'link',
              search: '',
              afterId: null,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceReference.reverse(
            member,
            WorkspaceReferenceRecordRequest(
              workspaceId: wid,
              tableId: 'target',
              recordId: 'person',
              afterId: null,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceReference.tableTargets(
            member,
            WorkspaceReferenceTableRequest(workspaceId: wid, tableId: 'target'),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final schemaRead = await endpoints.workspaceState.read(
          member,
          ReadWorkspaceStateRequest(
            workspaceId: wid,
            pages: [
              WorkspaceResourcePageRequest(resourceKind: .table, limit: 100),
            ],
            eventLimit: 0,
          ),
        );
        final projectedSource = schemaRead.pages.single.resources.single;
        final projectedColumns = _data(projectedSource)['columns'] as List;
        expect(
          (projectedColumns.last as Map).containsKey('defaultValue'),
          false,
        );
        expect(jsonEncode(schemaRead.toJson()), isNot(contains('person')));
        final read = await endpoints.workspaceState.read(
          member,
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
        final visible = read.pages.single.resources.single;
        expect(visible.resourceId, 'task');
        expect((_data(visible)['values'] as Map).containsKey('link'), false);
        expect(jsonEncode(read.toJson()), isNot(contains('Private Ada')));
        final request = PatchWorkspaceStateRequest(
          workspaceId: wid,
          requestId: 'edit-hidden-link',
          operations: [
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .tableRecord,
              resourceId: 'task',
              expectedRevision: 1,
              data: jsonEncode({
                'tableId': 'source',
                'schemaRevision': 2,
                'values': {'label': 'Updated'},
              }),
              fieldMask: const [],
            ),
          ],
        );
        final updated = await endpoints.workspaceState.patch(member, request);
        expect(
          (_data(updated.resources.single)['values'] as Map).containsKey(
            'link',
          ),
          false,
        );
        final replay = await endpoints.workspaceState.patch(member, request);
        expect(
          (_data(replay.resources.single)['values'] as Map).containsKey('link'),
          false,
        );
        final ownerRead = await endpoints.workspaceState.read(
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
        final retained = ownerRead.pages.single.resources.firstWhere(
          (row) => row.resourceId == 'task',
        );
        expect((_data(retained)['values'] as Map)['link'], ['person']);
        expect((_data(retained)['values'] as Map)['label'], 'Updated');
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'target',
            expectedRevision: 2,
            data: jsonEncode(schema('People')),
            fieldMask: const [],
          ),
        ]);
        expect(
          (await endpoints.workspaceReference.targets(
            member,
            WorkspaceReferenceTargetRequest(
              workspaceId: wid,
              sourceTableId: 'source',
              columnId: 'link',
              search: '',
              afterId: null,
            ),
          )).single.resourceId,
          'person',
        );
        final legacyMetadata = schema('Renamed people');
        legacyMetadata['columns'] = [
          for (final column in legacyMetadata['columns'] as List)
            <String, Object?>{
              ...(column as Map).cast<String, Object?>(),
              'targetTableId': null,
              'referenceMultiple': false,
            },
        ];
        final renamedLegacy = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'target',
            expectedRevision: 3,
            data: jsonEncode(legacyMetadata),
            fieldMask: const [],
          ),
        ]);
        expect(_data(renamedLegacy.resources.single)['schemaRevision'], 1);
        expect(_data(renamedLegacy.resources.single)['name'], 'Renamed people');
        final capitalAccent = String.fromCharCode(0x00c9);
        final lowerAccent = String.fromCharCode(0x00e9);
        await patch([
          _create(.tableRecord, 'accent-person', {
            'tableId': 'target',
            'schemaRevision': 1,
            'values': {'label': '${capitalAccent}va'},
          }),
        ]);
        for (final search in [capitalAccent, lowerAccent]) {
          final matches = await endpoints.workspaceReference.tableTargets(
            member,
            WorkspaceReferenceTableRequest(
              workspaceId: wid,
              tableId: 'target',
              search: search,
            ),
          );
          expect(
            matches.map((row) => row.resourceId),
            search == capitalAccent ? ['accent-person'] : isEmpty,
          );
        }
        await patch([
          _create(
            .table,
            'hidden-source',
            schema('Hidden', shared: false, source: true),
          ),
        ]);
        for (var start = 0; start < 52; start += 26) {
          await patch([
            for (var index = start; index < start + 26; index++)
              _create(.tableRecord, 'batch-$index', {
                'tableId': 'target',
                'schemaRevision': 1,
                'values': {'label': 'Batch $index'},
              }),
          ]);
          await patch([
            for (var index = start; index < start + 26; index++)
              _create(.tableRecord, 'aaa-hidden-$index', {
                'tableId': 'hidden-source',
                'schemaRevision': 1,
                'values': {
                  'label': 'Hidden $index',
                  'link': ['person'],
                },
              }),
          ]);
        }
        final first = await endpoints.workspaceReference.targets(
          member,
          WorkspaceReferenceTargetRequest(
            workspaceId: wid,
            sourceTableId: 'source',
            columnId: 'link',
            search: 'Batch',
            afterId: null,
          ),
        );
        expect(first.length, 51);
        final second = await endpoints.workspaceReference.targets(
          member,
          WorkspaceReferenceTargetRequest(
            workspaceId: wid,
            sourceTableId: 'source',
            columnId: 'link',
            search: 'Batch',
            afterId: first[49].resourceId,
          ),
        );
        expect(second.length, 2);
        expect(
          {
            ...first.take(50).map((row) => row.resourceId),
            ...second.map((row) => row.resourceId),
          }.length,
          52,
        );
        final visibleReverse = await endpoints.workspaceReference.reverse(
          member,
          WorkspaceReferenceRecordRequest(
            workspaceId: wid,
            tableId: 'target',
            recordId: 'person',
            afterId: null,
          ),
        );
        expect(visibleReverse.map((row) => row.resourceId), ['task']);
        final foreignWorkspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Other',
              ownerUserId: ownerId,
              now: DateTime.now().toUtc(),
            );
        await endpoints.workspaceState.patch(
          owner,
          PatchWorkspaceStateRequest(
            workspaceId: foreignWorkspace.id!,
            requestId: 'foreign-table',
            operations: [
              _create(.table, 'foreign-table', schema('Other', shared: false)),
            ],
          ),
        );
        final invalidSchema = schema('Tasks', source: true);
        invalidSchema['schemaRevision'] = 3;
        (invalidSchema['columns'] as List).add({
          'id': 'foreign-link',
          'name': 'Foreign',
          'type': 'reference',
          'targetTableId': 'foreign-table',
        });
        await expectLater(
          patch([
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .table,
              resourceId: 'source',
              expectedRevision: 2,
              data: jsonEncode(invalidSchema),
              fieldMask: const [],
            ),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceReference.targets(
            member,
            WorkspaceReferenceTargetRequest(
              workspaceId: foreignWorkspace.id!,
              sourceTableId: 'source',
              columnId: 'link',
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
      },
    );
  });
}

WorkspacePatchOperation _create(
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
Map<String, dynamic> _data(WorkspaceResource row) =>
    jsonDecode(row.data) as Map<String, dynamic>;
