import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace tables', (sessionBuilder, endpoints) {
    test(
      'authenticated owner creates and edits table records without stale overwrite',
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
        final created = await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'table-one',
            data: jsonEncode({
              'name': 'My list',
              'parentId': null,
              'labelColumnId': 'label-one',
              'schemaRevision': 1,
              'columns': [
                {'id': 'label-one', 'name': 'Title', 'type': 'text'},
              ],
            }),
            fieldMask: const [],
          ),
        ]);
        expect(created.resources.single.revision, 1);
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'record-one',
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 1,
              'values': {'label-one': 'First'},
            }),
            fieldMask: const [],
          ),
        ]);
        final edited = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: 'record-one',
            expectedRevision: 1,
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 1,
              'values': {'label-one': 'Changed'},
            }),
            fieldMask: const [],
          ),
        ]);
        expect(edited.resources.single.revision, 2);
        await expectLater(
          patch([
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .tableRecord,
              resourceId: 'record-one',
              expectedRevision: 1,
              data: jsonEncode({
                'tableId': 'table-one',
                'schemaRevision': 1,
                'values': {'label-one': 'Stale'},
              }),
              fieldMask: const [],
            ),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final metadata = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'table-one',
            expectedRevision: 1,
            data: jsonEncode({
              'name': 'Renamed list',
              'parentId': null,
              'labelColumnId': 'label-one',
              'schemaRevision': 1,
              'columns': [
                {
                  'id': 'label-one',
                  'name': 'Title',
                  'type': 'text',
                  'options': [],
                },
              ],
            }),
            fieldMask: const [],
          ),
        ]);
        expect(metadata.resources.single.revision, 2);
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'open-draft',
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 1,
              'values': {'label-one': 'Draft before rename'},
            }),
            fieldMask: const [],
          ),
        ]);
        await expectLater(
          patch([
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .table,
              resourceId: 'table-one',
              expectedRevision: 2,
              fieldMask: const [],
              data: jsonEncode({
                'name': 'Tampered schema',
                'labelColumnId': 'label-one',
                'schemaRevision': 1,
                'columns': [
                  {'id': 'label-one', 'name': 'Changed schema', 'type': 'text'},
                ],
              }),
            ),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final renamed = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'table-one',
            expectedRevision: 2,
            data: jsonEncode({
              'name': 'My list',
              'labelColumnId': 'label-one',
              'schemaRevision': 2,
              'columns': [
                {'id': 'label-one', 'name': 'Summary', 'type': 'text'},
              ],
            }),
            fieldMask: const [],
          ),
        ]);
        expect(renamed.resources.single.revision, 3);
        await expectLater(
          patch([
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .tableRecord,
              resourceId: 'stale-schema',
              data: jsonEncode({
                'tableId': 'table-one',
                'schemaRevision': 1,
                'values': {'label-one': 'Stale'},
              }),
              fieldMask: const [],
            ),
          ]),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.staleRevision,
            ),
          ),
        );
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'record-two',
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 2,
              'values': {'label-one': 'Second'},
            }),
            fieldMask: const [],
          ),
        ]);
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: 'record-one',
            expectedRevision: 2,
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 2,
              'values': {'label-one': 'Latest'},
            }),
            fieldMask: const [],
          ),
        ]);
        final independent = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: 'record-two',
            expectedRevision: 1,
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 2,
              'values': {'label-one': 'Independent'},
            }),
            fieldMask: const [],
          ),
        ]);
        expect(independent.resources.single.revision, 2);
        final other = await repository.createWorkspace(
          session,
          name: 'Other',
          ownerUserId: userId,
          now: DateTime.now().toUtc(),
        );
        await expectLater(
          endpoints.workspaceState.patch(
            authenticated,
            PatchWorkspaceStateRequest(
              workspaceId: other.id!,
              requestId: 'foreign-table',
              operations: [
                WorkspacePatchOperation(
                  operation: .create,
                  resourceKind: .tableRecord,
                  resourceId: 'foreign-record',
                  data: jsonEncode({
                    'tableId': 'table-one',
                    'schemaRevision': 2,
                    'values': {'label-one': 'Foreign'},
                  }),
                  fieldMask: const [],
                ),
              ],
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final typedColumns = <Map<String, Object?>>[
          {'id': 'typed-label', 'name': 'Title', 'type': 'text'},
          {'id': 'count', 'name': 'Count', 'type': 'number'},
          {'id': 'done', 'name': 'Done', 'type': 'checkbox'},
          {
            'id': 'status',
            'name': 'Status',
            'type': 'singleSelect',
            'options': ['Open', 'Done'],
          },
          {
            'id': 'tags',
            'name': 'Tags',
            'type': 'multiSelect',
            'options': ['A', 'B'],
          },
          {'id': 'website', 'name': 'Website', 'type': 'url'},
          {'id': 'email', 'name': 'Email', 'type': 'email'},
          {'id': 'phone', 'name': 'Phone', 'type': 'phone'},
        ];
        final typedSchema = {
          'name': 'Typed',
          'labelColumnId': 'typed-label',
          'schemaRevision': 1,
          'columns': typedColumns,
        };
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'typed-table',
            data: jsonEncode(typedSchema),
            fieldMask: const [],
          ),
        ]);
        final typedValues = <String, Object?>{
          'typed-label': '',
          'count': 0,
          'done': false,
          'status': 'Open',
          'tags': ['A', 'B'],
          'website': 'https://example.com',
          'email': 'david@example.com',
          'phone': '+1 (555) 123-4567 ext. 12',
        };
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'typed-record',
            data: jsonEncode({
              'tableId': 'typed-table',
              'schemaRevision': 1,
              'values': typedValues,
            }),
            fieldMask: const [],
          ),
        ]);
        for (final invalid in <Map<String, Object?>>[
          {'count': '0'},
          {'done': 'false'},
          {
            'status': ['Open'],
          },
          {'tags': 'A'},
          {
            'tags': ['A', 'A'],
          },
          {'status': 'Unknown'},
          {'website': 'javascript:alert(1)'},
          {'email': 'missing-at'},
          {'phone': 'call me'},
          {'count': null},
          {'unknown': 'field'},
        ]) {
          await expectLater(
            patch([
              WorkspacePatchOperation(
                operation: .update,
                resourceKind: .tableRecord,
                resourceId: 'typed-record',
                expectedRevision: 1,
                data: jsonEncode({
                  'tableId': 'typed-table',
                  'schemaRevision': 1,
                  'values': {...typedValues, ...invalid},
                }),
                fieldMask: const [],
              ),
            ]),
            throwsA(
              isA<CloudWorkspaceException>().having(
                (error) => error.code,
                'code',
                CloudWorkspaceErrorCode.validationFailed,
              ),
            ),
          );
        }
        await expectLater(
          patch([
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .table,
              resourceId: 'typed-table',
              expectedRevision: 1,
              data: jsonEncode({
                ...typedSchema,
                'schemaRevision': 2,
                'columns': [
                  for (final column in typedColumns)
                    if (column['id'] == 'status')
                      {
                        ...column,
                        'options': ['Done'],
                      }
                    else
                      column,
                ],
              }),
              fieldMask: const [],
            ),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final typedRead = await endpoints.workspaceState.read(
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
        final retained = typedRead.pages.single.resources.firstWhere(
          (row) => row.resourceId == 'typed-record',
        );
        expect(
          (jsonDecode(retained.data) as Map<String, dynamic>)['values'],
          typedValues,
        );
        expect(retained.revision, 1);
        final outsiderId = const Uuid().v4().toString();
        await AuthUser.db.insertRow(
          session,
          AuthUser(
            id: UuidValue.fromString(outsiderId),
            scopeNames: const {},
          ),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(outsiderId),
            email: '$outsiderId@example.com',
            passwordHash: 'unused',
          ),
        );
        final outsider = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            outsiderId,
            const {},
          ),
        );
        await expectLater(
          endpoints.workspaceState.read(
            outsider,
            ReadWorkspaceStateRequest(
              workspaceId: workspace.id!,
              pages: [
                WorkspaceResourcePageRequest(resourceKind: .table, limit: 100),
              ],
              eventLimit: 0,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final now = DateTime.now().toUtc();
        await WorkspaceMember.db.insertRow(
          session,
          WorkspaceMember(
            workspaceId: workspace.id!,
            userId: outsiderId,
            role: 'admin',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await expectLater(
          endpoints.workspaceState.patch(
            outsider,
            PatchWorkspaceStateRequest(
              workspaceId: workspace.id!,
              requestId: 'admin-edit',
              operations: [
                WorkspacePatchOperation(
                  operation: .create,
                  resourceKind: .tableRecord,
                  resourceId: 'denied',
                  data: jsonEncode({
                    'tableId': 'table-one',
                    'schemaRevision': 2,
                    'values': {'label-one': 'Denied'},
                  }),
                  fieldMask: const [],
                ),
              ],
            ),
          ),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.permissionDenied,
            ),
          ),
        );
        await expectLater(
          endpoints.workspaceState.read(
            sessionBuilder,
            ReadWorkspaceStateRequest(
              workspaceId: workspace.id!,
              pages: [
                WorkspaceResourcePageRequest(resourceKind: .table, limit: 100),
              ],
              eventLimit: 0,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
      },
    );
  });
}
