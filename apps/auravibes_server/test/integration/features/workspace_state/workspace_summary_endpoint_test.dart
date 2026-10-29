import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as repository;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Authorized result summaries', (builder, endpoints) {
    test(
      'all batches, exact currencies, missing values and current grants',
      () async {
        final owner = const Uuid().v4().toString();
        final reader = const Uuid().v4().toString();
        final ownerBuilder = builder.copyWith(
          authentication: .authenticationInfo(owner, const {}),
        );
        final readerBuilder = builder.copyWith(
          authentication: .authenticationInfo(reader, const {}),
        );
        final session = ownerBuilder.build();
        for (final user in [owner, reader]) {
          await AuthUser.db.insertRow(
            session,
            .new(id: .fromString(user), scopeNames: const {}),
          );
          await EmailAccount.db.insertRow(
            session,
            .new(
              authUserId: .fromString(user),
              email: '$user@example.com',
              passwordHash: 'unused',
            ),
          );
        }
        final workspace = await repository.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Summary',
              ownerUserId: owner,
              now: DateTime.now().toUtc(),
            );
        final now = DateTime.now().toUtc();
        await WorkspaceMember.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            userId: reader,
            role: 'member',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        Future<void> patch(List<WorkspacePatchOperation> operations) async {
          await endpoints.workspaceState.patch(
            ownerBuilder,
            .new(
              workspaceId: workspace.id!,
              requestId: const Uuid().v4().toString(),
              operations: operations,
            ),
          );
        }

        final schema = {
          'name': 'Items',
          'schemaRevision': 1,
          'labelColumnId': 'label',
          'columns': [
            {'id': 'label', 'name': 'Title', 'type': 'text'},
            {'id': 'cost', 'name': 'Cost', 'type': 'money'},
            {'id': 'day', 'name': 'Day', 'type': 'dateOnly'},
            {
              'id': 'instant',
              'name': 'Instant',
              'type': 'timestamp',
              'timeZone': 'UTC',
            },
          ],
          'memberAccess': {reader: 'read'},
        };
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'table',
            data: jsonEncode(schema),
            fieldMask: const [],
          ),
        ]);
        for (var start = 0; start < 103; start += 50) {
          await patch([
            for (var index = start; index < start + 50 && index < 103; index++)
              WorkspacePatchOperation(
                operation: .create,
                resourceKind: .tableRecord,
                resourceId: 'record-$index',
                data: jsonEncode({
                  'tableId': 'table',
                  'schemaRevision': 1,
                  'values': {
                    'label': 'Record $index',
                    if (index == 0)
                      'cost': {
                        'amount': '9007199254740993.000000000000000000001',
                        'currency': 'USD',
                      },
                    if (index == 100)
                      'cost': {
                        'amount': '-9007199254740993',
                        'currency': 'USD',
                      },
                    if (index == 101)
                      'cost': {'amount': '5.20', 'currency': 'EUR'},
                    if (index == 0) 'day': '2026-10-23',
                    if (index == 100) 'day': '2026-01-01',
                    if (index == 0) 'instant': '2026-10-23T10:00:00Z',
                    if (index == 100) 'instant': '2026-10-23T10:00:00.000001Z',
                  },
                }),
                fieldMask: const [],
              ),
          ]);
        }
        Future<Map<String, dynamic>> summary(
          Map<String, Object?> query,
        ) async => jsonDecode(
          await endpoints.workspaceState.summarizeRecords(
            readerBuilder,
            .new(
              workspaceId: workspace.id!,
              tableId: 'table',
              queryJson: jsonEncode(query),
              columnIds: ['cost', 'day', 'instant'],
            ),
          ),
        ) as Map<String, dynamic>;
        final all = await summary({'limit': 1, 'offset': 100});
        expect(all['count'], 103);
        final columns = all['columns'] as Map;
        expect((columns['cost'] as Map)['present'], 3);
        expect(
          (((columns['cost'] as Map)['currencies'] as Map)['USD']
              as Map)['sum'],
          '0.000000000000000000001',
        );
        expect(
          (((columns['cost'] as Map)['currencies'] as Map)['EUR']
              as Map)['sum'],
          '5.2',
        );
        expect((columns['day'] as Map)['minimum'], '2026-01-01');
        expect(
          (columns['instant'] as Map)['maximum'],
          '2026-10-23T10:00:00.000001Z',
        );
        final filtered = await summary({'search': 'Record 100'});
        expect(filtered['count'], 1);
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'table',
            expectedRevision: 1,
            data: jsonEncode({...schema, 'memberAccess': <String, String>{}}),
            fieldMask: const [],
          ),
        ]);
        await expectLater(
          summary({}),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.permissionDenied,
            ),
          ),
        );
      },
    );
  });
}
