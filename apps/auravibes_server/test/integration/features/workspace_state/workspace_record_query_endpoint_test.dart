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
          'd': '${String.fromCharCode(0xc9)}cho',
          'e': '${String.fromCharCode(0xe9)}cho',
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
          jsonEncode({'search': String.fromCharCode(0xc9)}),
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
        for (final amount in [
          10,
          2,
          -9007199254740992,
          int.parse('-9007199254740993'),
        ]) {
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
          'numeric--9007199254740993',
          'numeric--9007199254740992',
          'numeric-2',
          'numeric-10',
        ]);
        final equivalentNumbers = await endpoints.workspaceState.queryRecords(
          authenticated,
          workspace.id!,
          'numeric',
          jsonEncode({'filterColumnId': 'quantity', 'filterValue': '2.0'}),
        );
        expect(equivalentNumbers.map((row) => row.resourceId), ['numeric-2']);
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'exact',
            data: jsonEncode({
              'name': 'Exact',
              'schemaRevision': 1,
              'labelColumnId': 'label',
              'columns': [
                {'id': 'label', 'name': 'Title', 'type': 'text'},
                {'id': 'cost', 'name': 'Cost', 'type': 'money'},
                {
                  'id': 'instant',
                  'name': 'Instant',
                  'type': 'timestamp',
                  'timeZone': 'UTC',
                },
              ],
            }),
            fieldMask: const [],
          ),
        ]);
        final exactValues = [
          {"id": "a", "currency": "USD", "amount": "-9007199254740993.00001"},
          {"id": "b", "currency": "USD", "amount": "-9007199254740993.00002"},
          {"id": "c", "currency": "USD", "amount": "0.00"},
          {"id": "d", "currency": "USD", "amount": "-0"},
          {"id": "e", "currency": "USD", "amount": "9007199254740993.00001"},
          {"id": "f", "currency": "EUR", "amount": "1000000000000000000000"},
          {"id": "g", "currency": "USD", "amount": "-10"},
          {"id": "h", "currency": "USD", "amount": "-2"},
          {"id": "i", "currency": "USD", "amount": "2.00000"},
          {"id": "j", "currency": "USD", "amount": "2"},
          {"id": "k", "currency": "USD", "amount": "0.000000000000000000001"},
          {"id": "l", "currency": "USD", "amount": "-0.000000000000000000001"},
          {"id": "m", "currency": "USD", "amount": "10"},
          {"id": "n", "currency": "USD", "amount": "9007199254740993.00002"},
          {"id": "o", "currency": "USD", "amount": "-0.00"},
          {"id": "p", "currency": "USD", "amount": "100"},
          {"id": "q", "currency": "JPY", "amount": "0"},
        ];
        for (final value in exactValues) {
          final id = value['id']!;
          final instant = switch (id) {
            'a' => '2026-10-23T10:00:00Z',
            'b' => '2026-10-23T10:00:00.000000Z',
            'c' => '2026-10-23T10:00:00.1Z',
            _ => '2026-10-23T10:00:00.000001Z',
          };
          await patch([
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .tableRecord,
              resourceId: 'exact-$id',
              data: jsonEncode({
                'tableId': 'exact',
                'schemaRevision': 1,
                'values': {
                  'label': id,
                  'instant': instant,
                  'cost': {
                    'currency': value['currency'],
                    'amount': value['amount'],
                  },
                },
              }),
              fieldMask: const [],
            ),
          ]);
        }
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'exact-z',
            data: jsonEncode({
              'tableId': 'exact',
              'schemaRevision': 1,
              'values': {'label': 'z'},
            }),
            fieldMask: const [],
          ),
        ]);
        Future<List<String>> exactQuery(Map<String, Object?> query) async =>
            (await endpoints.workspaceState.queryRecords(
              authenticated,
              workspace.id!,
              'exact',
              jsonEncode(query),
            )).map((row) => row.resourceId.replaceFirst('exact-', '')).toList();
        // Expected orders derived independently with Python decimal.Decimal.
        expect(await exactQuery({'sortColumnId': 'cost'}), [
          'z',
          'f',
          'q',
          'b',
          'a',
          'g',
          'h',
          'l',
          'c',
          'd',
          'o',
          'k',
          'i',
          'j',
          'm',
          'p',
          'e',
          'n',
        ]);
        expect(await exactQuery({'sortColumnId': 'cost', 'descending': true}), [
          'n',
          'e',
          'p',
          'm',
          'i',
          'j',
          'k',
          'c',
          'd',
          'o',
          'l',
          'h',
          'g',
          'a',
          'b',
          'q',
          'f',
          'z',
        ]);
        expect(
          await exactQuery({'sortColumnId': 'cost', 'offset': 2, 'limit': 2}),
          ['q', 'b', 'a'],
        );
        final instants = await exactQuery({'sortColumnId': 'instant'});
        expect(instants.take(3), ['z', 'a', 'b']);
        expect(instants.last, 'c');
        expect(
          await exactQuery({
            'filterColumnId': 'instant',
            'filterValue': '2026-10-23T10:00:00.0Z',
          }),
          ['a', 'b'],
        );
        expect(
          await exactQuery({
            'filterColumnId': 'cost',
            'filterValue': '{"currency":"USD","amount":"0"}',
          }),
          ['c', 'd', 'o'],
        );
        for (final invalid in [('instant', 'invalid'), ('cost', '{')]) {
          await expectLater(
            exactQuery({
              'filterColumnId': invalid.$1,
              'filterValue': invalid.$2,
            }),
            throwsA(
              isA<CloudWorkspaceException>().having(
                (error) => error.code,
                'code',
                CloudWorkspaceErrorCode.validationFailed,
              ),
            ),
          );
        }
        expect(
          await exactQuery({
            'filterColumnId': 'label',
            'filterValue': 'A',
            'filterOperator': 'contains',
          }),
          ['a'],
        );
        for (final operator in ['greaterThan', 'contains']) {
          await expectLater(
            exactQuery({
              'filterColumnId': 'cost',
              'filterValue': '{"currency":"USD","amount":"0"}',
              'filterOperator': operator,
            }),
            throwsA(
              isA<CloudWorkspaceException>().having(
                (error) => error.code,
                'code',
                CloudWorkspaceErrorCode.validationFailed,
              ),
            ),
          );
        }
        final largeAmount = '0.${'0' * 16381}1';
        final largeValue = {'currency': 'USD', 'amount': largeAmount};
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'exact-large',
            data: jsonEncode({
              'tableId': 'exact',
              'schemaRevision': 1,
              'values': {'label': 'Large', 'cost': largeValue},
            }),
            fieldMask: const [],
          ),
        ]);
        expect(
          await exactQuery({
            'filterColumnId': 'cost',
            'filterValue': jsonEncode(largeValue),
          }),
          ['large'],
        );
        final targetSchema = {
          'name': 'Targets',
          'labelColumnId': 'label',
          'schemaRevision': 1,
          'columns': [
            {'id': 'label', 'name': 'Title', 'type': 'text'},
          ],
        };
        final sourceSchema = {
          'name': 'Sources',
          'labelColumnId': 'label',
          'schemaRevision': 1,
          'memberAccess': {memberId: 'read'},
          'columns': [
            {'id': 'label', 'name': 'Title', 'type': 'text'},
            {
              'id': 'link',
              'name': 'Related',
              'type': 'reference',
              'targetTableId': 'reference-target',
              'referenceMultiple': false,
            },
          ],
        };
        for (final operation in [
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'reference-target',
            data: jsonEncode(targetSchema),
            fieldMask: const [],
          ),
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'hidden-target-record',
            data: jsonEncode({
              'tableId': 'reference-target',
              'schemaRevision': 1,
              'values': {'label': 'Private target'},
            }),
            fieldMask: const [],
          ),
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'reference-source',
            data: jsonEncode(sourceSchema),
            fieldMask: const [],
          ),
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'source-record',
            data: jsonEncode({
              'tableId': 'reference-source',
              'schemaRevision': 1,
              'values': {'label': 'Source', 'link': 'hidden-target-record'},
            }),
            fieldMask: const [],
          ),
        ]) {
          await patch([operation]);
        }
        Future<WorkspaceResource> sourceQuery() async =>
            (await endpoints.workspaceState.queryRecords(
              member,
              workspace.id!,
              'reference-source',
              '{}',
            )).single;
        final deniedReference = await sourceQuery();
        expect(deniedReference.data, isNot(contains('hidden-target-record')));
        expect(
          jsonDecode(deniedReference.data),
          containsPair('restrictedReferenceColumns', ['link']),
        );
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'reference-target',
            data: jsonEncode({
              ...targetSchema,
              'memberAccess': {memberId: 'read'},
            }),
            fieldMask: const [],
            expectedRevision: 1,
          ),
        ]);
        final grantedReference =
            jsonDecode((await sourceQuery()).data) as Map<String, dynamic>;
        expect(grantedReference['restrictedReferenceColumns'], isEmpty);
        expect(
          grantedReference['values'],
          containsPair('link', 'hidden-target-record'),
        );
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'reference-target',
            data: jsonEncode({
              ...targetSchema,
              'memberAccess': <String, String>{},
            }),
            fieldMask: const [],
            expectedRevision: 2,
          ),
        ]);
        final revokedReference = await sourceQuery();
        expect(revokedReference.data, isNot(contains('hidden-target-record')));
        expect(
          jsonDecode(revokedReference.data),
          containsPair('restrictedReferenceColumns', ['link']),
        );
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
