import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Atomic record batches', (sessionBuilder, endpoints) {
    test(
      'unique swap validates final state and rolls back invalid final values',
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
        Map<String, Object?> record(String label) => {
          'tableId': 'table-one',
          'schemaRevision': 1,
          'values': {'label-one': label},
        };
        WorkspacePatchOperation write(
          String id,
          String label, {
          int? revision,
        }) => WorkspacePatchOperation(
          operation: revision == null ? .create : .update,
          resourceKind: .tableRecord,
          resourceId: id,
          expectedRevision: revision,
          data: jsonEncode(record(label)),
          fieldMask: const [],
        );
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'table-one',
            data: jsonEncode({
              'name': 'Items',
              'parentId': null,
              'labelColumnId': 'label-one',
              'schemaRevision': 1,
              'columns': [
                {
                  'id': 'label-one',
                  'name': 'Title',
                  'type': 'text',
                  'unique': true,
                },
              ],
            }),
            fieldMask: const [],
          ),
        ]);
        await patch([write('first', 'A'), write('second', 'B')]);
        final swap = PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: 'swap',
          operations: [
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .folder,
              resourceId: 'mixed-folder',
              data: jsonEncode({'name': 'Folder', 'parentId': null}),
              fieldMask: const [],
            ),
            write('first', 'B', revision: 1),
            write('second', 'A', revision: 1),
          ],
        );
        final swapped = await endpoints.workspaceState.patch(
          authenticated,
          swap,
        );
        final replayed = await endpoints.workspaceState.patch(
          authenticated,
          swap,
        );
        expect(replayed.sequence, swapped.sequence);
        await expectLater(
          endpoints.workspaceState.patch(
            authenticated,
            swap.copyWith(operations: [write('first', 'Changed', revision: 1)]),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        expect(swapped.resources.map((row) => row.revision), [1, 2, 2]);
        await expectLater(
          patch([
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .folder,
              resourceId: 'rolled-back',
              data: jsonEncode({'name': 'No partial folder', 'parentId': null}),
              fieldMask: const [],
            ),
            write('first', 'C', revision: 2),
            write('second', 'C', revision: 2),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final rows = await WorkspaceResource.db.find(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id!) &
              row.resourceKind.equals(.tableRecord),
        );
        expect(
          {
            for (final row in rows)
              row.resourceId: (jsonDecode(row.data) as Map)['values'],
          },
          {
            'first': {'label-one': 'B'},
            'second': {'label-one': 'A'},
          },
        );
        expect(
          await WorkspaceResource.db.find(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.resourceId.equals('rolled-back'),
          ),
          isEmpty,
        );
        final _ = await WorkspaceMember.db.deleteWhere(
          session,
          where: (row) => row.workspaceId.equals(workspace.id!),
        );
        await expectLater(
          endpoints.workspaceState.patch(authenticated, swap),
          throwsA(isA<CloudWorkspaceException>()),
        );
      },
    );
  });
}
