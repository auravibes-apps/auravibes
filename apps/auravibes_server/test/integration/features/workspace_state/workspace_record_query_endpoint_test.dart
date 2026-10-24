import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace record queries', (sessionBuilder, endpoints) {
    test(
      'bounded authenticated queries preserve search and stable pages',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = sessionBuilder.copyWith(
          authentication: .authenticationInfo(userId, const {}),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          .new(id: .fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          .new(
            authUserId: .fromString(userId),
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
          .new(
            workspaceId: workspace.id!,
            requestId: const Uuid().v4().toString(),
            operations: operations,
          ),
        );
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'query-table',
            data: jsonEncode({
              'name': 'Query',
              'labelColumnId': 'label',
              'schemaRevision': 1,
              'columns': [
                {'id': 'label', 'name': 'Title', 'type': 'text'},
              ],
            }),
            fieldMask: const [],
          ),
        ]);
        for (final entry in {
          'a': 'Zulu',
          'b': 'Alpha',
          'c': 'Other',
          'd': '\u00c9cho',
          'e': '\u00e9cho',
        }.entries) {
          await patch([
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .tableRecord,
              resourceId: entry.key,
              data: jsonEncode({
                'tableId': 'query-table',
                'schemaRevision': 1,
                'values': {'label': entry.value},
              }),
              fieldMask: const [],
            ),
          ]);
        }
        final memberId = const Uuid().v4().toString();
        final member = sessionBuilder.copyWith(
          authentication: .authenticationInfo(memberId, const {}),
        );
        await AuthUser.db.insertRow(
          session,
          .new(id: .fromString(memberId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          .new(
            authUserId: .fromString(memberId),
            email: '$memberId@example.com',
            passwordHash: 'unused',
          ),
        );
        await WorkspaceMember.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            userId: memberId,
            role: 'member',
            revision: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        await expectLater(
          endpoints.workspaceState.queryRecords(
            member,
            workspace.id!,
            'query-table',
            '{}',
          ),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.permissionDenied,
            ),
          ),
        );
        Future<void> grant(int revision, Map<String, String> access) async {
          await patch([
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .table,
              resourceId: 'query-table',
              data: jsonEncode({
                'name': 'Query',
                'labelColumnId': 'label',
                'schemaRevision': 1,
                'columns': [
                  {'id': 'label', 'name': 'Title', 'type': 'text'},
                ],
                'memberAccess': access,
              }),
              fieldMask: const [],
              expectedRevision: revision,
            ),
          ]);
        }

        await grant(1, {memberId: 'read'});
        expect(
          (await endpoints.workspaceState.queryRecords(
            member,
            workspace.id!,
            'query-table',
            '{}',
          )).length,
          5,
        );
        await grant(2, {});
        await expectLater(
          endpoints.workspaceState.queryRecords(
            member,
            workspace.id!,
            'query-table',
            '{}',
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final first = await endpoints.workspaceState.queryRecords(
          authenticated,
          workspace.id!,
          'query-table',
          jsonEncode({'limit': 1}),
        );
        expect(first.map((row) => row.resourceId), ['b', 'c']);
        final search = await endpoints.workspaceState.queryRecords(
          authenticated,
          workspace.id!,
          'query-table',
          jsonEncode({'search': 'zU'}),
        );
        expect(search.single.resourceId, 'a');
        final accented = await endpoints.workspaceState.queryRecords(
          authenticated,
          workspace.id!,
          'query-table',
          jsonEncode({'search': '\u00c9'}),
        );
        expect(accented.single.resourceId, 'd');
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'numeric',
            data: jsonEncode({
              'name': 'Numbers',
              'schemaRevision': 1,
              'labelColumnId': 'label',
              'columns': [
                {'id': 'label', 'name': 'Title', 'type': 'text'},
                {'id': 'quantity', 'name': 'Quantity', 'type': 'number'},
              ],
            }),
            fieldMask: const [],
          ),
        ]);
        for (final amount in [10, 2]) {
          await patch([
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .tableRecord,
              resourceId: 'numeric-$amount',
              data: jsonEncode({
                'tableId': 'numeric',
                'schemaRevision': 1,
                'values': {'label': 'Value $amount', 'quantity': amount},
              }),
              fieldMask: const [],
            ),
          ]);
        }
        final numeric = await endpoints.workspaceState.queryRecords(
          authenticated,
          workspace.id!,
          'numeric',
          jsonEncode({'sortColumnId': 'quantity'}),
        );
        expect(numeric.map((row) => row.resourceId), [
          'numeric-2',
          'numeric-10',
        ]);
        await expectLater(
          endpoints.workspaceState.queryRecords(
            authenticated,
            workspace.id!,
            'query-table',
            jsonEncode({'limit': 101}),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceState.queryRecords(
            sessionBuilder,
            workspace.id!,
            'query-table',
            '{}',
          ),
          throwsA(anything),
        );
      },
    );
  });
}
