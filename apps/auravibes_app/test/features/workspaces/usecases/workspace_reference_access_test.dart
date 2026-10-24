import 'dart:convert';

import 'package:auravibes_app/data/repositories/cloud_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/preview_workspace_column_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud use case edits unrelated fields with required hidden links '
      'and refuses redacted schema preview', () async {
    final now = DateTime.utc(2026);
    WorkspaceResource resource(
      WorkspaceResourceKind kind,
      String id,
      Map<String, Object?> data,
    ) => WorkspaceResource(
      workspaceId: 1,
      resourceKind: kind,
      resourceId: id,
      data: jsonEncode(data),
      revision: 1,
      createdAt: now,
      updatedAt: now,
    );
    final tableRow = resource(.table, 'source', {
      'name': 'Source',
      'labelColumnId': 'label',
      'schemaRevision': 1,
      'canManageTable': true,
      'canEditRecords': true,
      'columns': [
        {'id': 'label', 'name': 'Name', 'type': 'text'},
        {
          'id': 'link',
          'name': 'Link',
          'type': 'reference',
          'targetTableId': 'private',
          'referenceMultiple': true,
          'required': true,
        },
      ],
    });
    var recordRow = resource(.tableRecord, 'record', {
      'tableId': 'source',
      'schemaRevision': 1,
      'values': {'label': 'Before'},
      'restrictedReferenceColumns': ['link'],
    });
    var sent = <String, dynamic>{};
    final store = CloudWorkspaceResourceStore.forTesting(
      watch: (_) => const Stream.empty(),
      patch: ({required requestId, required operations}) async {
        sent = jsonDecode(
          operations.single.data ??
              (throw StateError('Missing record payload')),
        ) as Map<String, dynamic>;
        recordRow = recordRow.copyWith(
          data: jsonEncode({
            ...sent,
            'restrictedReferenceColumns': ['link'],
          }),
        );

        return PatchWorkspaceStateResponse(resources: [recordRow], sequence: 2);
      },
      putSecret: (_) => throw StateError('Unexpected credential operation'),
      mutateCredential: (_) =>
          throw StateError('Unexpected credential operation'),
      read: ({required pages, required eventLimit, afterSequence}) async =>
          ReadWorkspaceStateResponse(
            pages: [
              WorkspaceResourcePage(
                resourceKind: pages.single.resourceKind,
                resources: [
                  if (pages.single.resourceKind == .table)
                    tableRow
                  else
                    recordRow,
                ],
              ),
            ],
            currentSequence: 1,
            events: [],
            requiresSnapshot: false,
          ),
    );
    final tables = OrganizeWorkspaceTablesUsecase(
      CloudWorkspaceTableRepository(store),
    );
    final table = await tables.table('source');
    final record = await tables.record('source', 'record');
    expect(
      WorkspaceTableConstraints.defaults(table.columns, const {}),
      isEmpty,
    );
    final edited = await tables.updateRecord(
      table: table,
      record: record,
      values: {'label': 'After'},
    );
    expect(edited.values, {'label': 'After'});
    expect(sent['values'], {'label': 'After'});
    await expectLater(
      PreviewWorkspaceColumnUsecase(tables)
          .call(table: table, column: table.columns.last),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.denied,
          'denied',
          true,
        ),
      ),
    );
  });
}
