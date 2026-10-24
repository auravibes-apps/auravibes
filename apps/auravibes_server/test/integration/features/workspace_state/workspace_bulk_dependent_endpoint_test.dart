import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Bulk dependent relationships', (builder, endpoints) {
    test(
      'target and source move together while outside links and roles remain enforced',
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
        await patch([
          _create(
            .tableRecord,
            'source-one',
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
              'target-one',
              1,
              record('targets', {'parent': 'parent-two'}),
            ),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final combined = await patch([
          _update(
            .tableRecord,
            'target-one',
            1,
            record('targets', {'parent': 'parent-two'}),
          ),
          _update(
            .tableRecord,
            'source-one',
            1,
            record('source', {
              'parent': 'parent-two',
              'dependent': 'target-one',
            }),
          ),
        ]);
        expect(combined.resources.map((row) => row.revision), [2, 2]);
        await patch([
          _create(
            .tableRecord,
            'outside',
            record('source', {
              'parent': 'parent-two',
              'dependent': 'target-one',
            }),
          ),
        ]);
        await expectLater(
          patch([
            _update(
              .tableRecord,
              'target-one',
              2,
              record('targets', {'parent': 'parent-one'}),
            ),
            _update(
              .tableRecord,
              'source-one',
              2,
              record('source', {
                'parent': 'parent-one',
                'dependent': 'target-one',
              }),
            ),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final target = await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(wid) & row.resourceId.equals('target-one'),
        );
        expect(target?.revision, 2);
        final current = await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(wid) & row.resourceId.equals('source-one'),
        );
        expect((jsonDecode(current!.data) as Map)['values'], {
          'parent': 'parent-two',
          'dependent': 'target-one',
        });
        await endpoints.workspaceState.patch(
          member,
          PatchWorkspaceStateRequest(
            workspaceId: wid,
            requestId: 'member-batch',
            operations: [
              _update(
                .tableRecord,
                'source-one',
                2,
                record('source', {
                  'parent': 'parent-two',
                  'dependent': 'target-two',
                }),
              ),
              _update(
                .tableRecord,
                'outside',
                1,
                record('source', {
                  'parent': 'parent-two',
                  'dependent': 'target-two',
                }),
              ),
            ],
          ),
        );
        final grant = await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(wid) &
              row.resourceKind.equals(.table) &
              row.resourceId.equals('source'),
        );
        await patch([
          _update(.table, 'source', grant!.revision, {
            ...sourceSchema,
            'memberAccess': {memberId: 'read'},
          }),
        ]);
        await expectLater(
          endpoints.workspaceState.patch(
            member,
            PatchWorkspaceStateRequest(
              workspaceId: wid,
              requestId: 'member-batch',
              operations: [
                _update(
                  .tableRecord,
                  'source-one',
                  2,
                  record('source', {
                    'parent': 'parent-two',
                    'dependent': 'target-two',
                  }),
                ),
                _update(
                  .tableRecord,
                  'outside',
                  1,
                  record('source', {
                    'parent': 'parent-two',
                    'dependent': 'target-two',
                  }),
                ),
              ],
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
