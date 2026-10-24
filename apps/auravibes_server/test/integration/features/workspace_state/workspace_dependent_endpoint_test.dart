import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Dependent relationships', (builder, endpoints) {
    test(
      'filters and every mutation enforce current compatible parents',
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
              name: 'Dependent',
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
          List<Map<String, Object?>> columns, {
          bool shared = true,
        }) => {
          'name': 'Table',
          'labelColumnId': 'label',
          'schemaRevision': 1,
          'memberAccess': {if (shared) memberId: 'edit'},
          'columns': [
            {'id': 'label', 'name': 'Name', 'type': 'text'},
            ...columns,
          ],
        };
        Map<String, Object?> link(String id, String target) => {
          'id': id,
          'name': id,
          'type': 'reference',
          'targetTableId': target,
        };
        final parentSchema = schema([]);
        await patch([_create(.table, 'parents', parentSchema)]);
        final targetSchema = schema([link('parent', 'parents')]);
        await patch([_create(.table, 'targets', targetSchema)]);
        final sourceSchema = schema([
          link('parent', 'parents'),
          {
            ...link('dependent', 'targets'),
            'dependsOnColumnId': 'parent',
            'targetMatchColumnId': 'parent',
          },
        ]);
        await patch([_create(.table, 'source', sourceSchema)]);
        Map<String, Object?> record(
          String table,
          Map<String, Object?> values,
        ) => {'tableId': table, 'schemaRevision': 1, 'values': values};
        await patch([
          _create(.tableRecord, 'parent-one', record('parents', {})),
          _create(.tableRecord, 'parent-two', record('parents', {})),
        ]);
        await patch([
          _create(
            .tableRecord,
            'target-one',
            record('targets', {'label': 'Ada', 'parent': 'parent-one'}),
          ),
          _create(
            .tableRecord,
            'target-two',
            record('targets', {'label': 'Grace', 'parent': 'parent-two'}),
          ),
        ]);
        for (var index = 0; index < 52; index++) {
          await patch([
            _create(
              .tableRecord,
              'a-nonmatching-$index',
              record('targets', {'parent': 'parent-two'}),
            ),
          ]);
        }
        Future<List<WorkspaceResource>> options(String? parent) =>
            endpoints.workspaceReference.targets(
              member,
              WorkspaceReferenceTargetRequest(
                workspaceId: wid,
                sourceTableId: 'source',
                columnId: 'dependent',
                parentId: parent,
              ),
            );
        expect((await options('parent-one')).map((row) => row.resourceId), [
          'target-one',
        ]);
        expect(await options(null), isEmpty);
        await expectLater(
          options('target-one'),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await patch([
          _create(
            .tableRecord,
            'task',
            record('source', {
              'parent': 'parent-one',
              'dependent': 'target-one',
            }),
          ),
        ]);
        await expectLater(
          patch([
            _update(
              .tableRecord,
              'task',
              1,
              record('source', {
                'parent': 'parent-two',
                'dependent': 'target-one',
              }),
            ),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final valid = await patch([
          _update(
            .tableRecord,
            'task',
            1,
            record('source', {
              'parent': 'parent-two',
              'dependent': 'target-two',
            }),
          ),
        ]);
        expect((jsonDecode(valid.resources.single.data) as Map)['values'], {
          'parent': 'parent-two',
          'dependent': 'target-two',
        });
        await expectLater(
          patch([
            _update(
              .tableRecord,
              'task',
              2,
              record('source', {'dependent': 'target-two'}),
            ),
          ]),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.incompatibleRelationship,
            ),
          ),
        );
        await expectLater(
          patch([_update(.tableRecord, 'task', 1, record('source', {}))]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          patch([
            _update(
              .tableRecord,
              'target-two',
              1,
              record('targets', {'parent': 'parent-one'}),
            ),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final hidden = {...targetSchema, 'memberAccess': <String, String>{}};
        await patch([_update(.table, 'targets', 1, hidden)]);
        await expectLater(
          options('parent-one'),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceState.patch(
            member,
            PatchWorkspaceStateRequest(
              workspaceId: wid,
              requestId: 'hidden-parent-change',
              operations: [
                _update(
                  .tableRecord,
                  'task',
                  2,
                  record('source', {'parent': 'parent-one'}),
                ),
              ],
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final source = await endpoints.workspaceReference.record(
          member,
          WorkspaceReferenceRecordRequest(
            workspaceId: wid,
            tableId: 'source',
            recordId: 'task',
          ),
        );
        expect((jsonDecode(source.data) as Map)['values'], {
          'parent': 'parent-two',
        });
        final retained = await endpoints.workspaceState.patch(
          member,
          PatchWorkspaceStateRequest(
            workspaceId: wid,
            requestId: 'hidden-unrelated-edit',
            operations: [
              _update(
                .tableRecord,
                'task',
                2,
                record('source', {'parent': 'parent-two', 'label': 'Edited'}),
              ),
            ],
          ),
        );
        expect(retained.resources.single.revision, 3);
        await patch([_update(.table, 'targets', 2, targetSchema)]);
        final legacyRoundTrip = {
          ...targetSchema,
          'name': 'Renamed target',
          'columns': [
            for (final column in (targetSchema['columns'] as List).cast<Map>())
              {
                ...column,
                'dependsOnColumnId': null,
                'targetMatchColumnId': null,
              },
          ],
        };
        final renamed = await patch([
          _update(.table, 'targets', 3, legacyRoundTrip),
        ]);
        expect(
          (jsonDecode(renamed.resources.single.data) as Map)['schemaRevision'],
          1,
        );

        expect(
          (jsonDecode(
            (await endpoints.workspaceReference.record(
              owner,
              WorkspaceReferenceRecordRequest(
                workspaceId: wid,
                tableId: 'source',
                recordId: 'task',
              ),
            )).data,
          ) as Map)['values'],
          {
            'parent': 'parent-two',
            'dependent': 'target-two',
            'label': 'Edited',
          },
        );
        await patch([_update(.tableRecord, 'task', 3, record('source', {}))]);
        final defaultSchema = {
          ...sourceSchema,
          'schemaRevision': 2,
          'columns': [
            {'id': 'label', 'name': 'Name', 'type': 'text'},
            {...link('parent', 'parents'), 'defaultValue': 'parent-one'},
            {
              ...link('dependent', 'targets'),
              'dependsOnColumnId': 'parent',
              'targetMatchColumnId': 'parent',
              'defaultValue': 'target-one',
            },
          ],
        };
        await patch([_update(.table, 'source', 1, defaultSchema)]);
        final defaultRecord = await patch([
          _create(.tableRecord, 'defaults', {
            'tableId': 'source',
            'schemaRevision': 2,
            'values': <String, Object?>{},
          }),
        ]);
        expect(
          (jsonDecode(defaultRecord.resources.single.data) as Map)['values'],
          {'parent': 'parent-one', 'dependent': 'target-one'},
        );
        await expectLater(
          patch([
            _create(.tableRecord, 'incompatible-default', {
              'tableId': 'source',
              'schemaRevision': 2,
              'values': {'parent': 'parent-two'},
            }),
          ]),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.incompatibleRelationship,
            ),
          ),
        );
        final explicitRecord = await patch([
          _create(.tableRecord, 'explicit', {
            'tableId': 'source',
            'schemaRevision': 2,
            'values': {'parent': 'parent-two', 'dependent': 'target-two'},
          }),
        ]);
        expect(
          (jsonDecode(explicitRecord.resources.single.data) as Map)['values'],
          {'parent': 'parent-two', 'dependent': 'target-two'},
        );
        await patch([
          _update(.table, 'parents', 1, {
            ...parentSchema,
            'memberAccess': <String, String>{},
          }),
        ]);
        final parentHidden = await endpoints.workspaceReference.record(
          member,
          WorkspaceReferenceRecordRequest(
            workspaceId: wid,
            tableId: 'source',
            recordId: 'explicit',
          ),
        );
        expect((jsonDecode(parentHidden.data) as Map)['values'], {
          'dependent': 'target-two',
        });
        await endpoints.workspaceState.patch(
          member,
          PatchWorkspaceStateRequest(
            workspaceId: wid,
            requestId: 'parent-hidden-unrelated',
            operations: [
              _update(.tableRecord, 'explicit', 1, {
                'tableId': 'source',
                'schemaRevision': 2,
                'values': {
                  'dependent': 'target-two',
                  'label': 'Still editable',
                },
              }),
            ],
          ),
        );
        await expectLater(
          options('parent-one'),
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
WorkspacePatchOperation _update(
  WorkspaceResourceKind kind,
  String id,
  int revision,
  Map<String, Object?> data,
) => WorkspacePatchOperation(
  operation: .update,
  resourceKind: kind,
  resourceId: id,
  expectedRevision: revision,
  data: jsonEncode(data),
  fieldMask: const [],
);
