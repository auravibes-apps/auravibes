import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/edit_workspace_records_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'atomic selection swaps unique labels without an intermediate conflict',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('bulk'),
              name: 'Bulk',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'bulk'),
      );
      var table = await tables.create(name: 'Items', labelName: 'Title');
      table = await tables.saveColumn(
        table: table,
        column: .new(id: table.labelColumnId, name: 'Title', isUnique: true),
      );
      final first = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'A'},
      );
      final second = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'B'},
      );
      final swap = [
        WorkspaceRecordChange(
          table: table,
          record: first,
          values: {table.labelColumnId: 'B'},
        ),
        WorkspaceRecordChange(
          table: table,
          record: second,
          values: {table.labelColumnId: 'A'},
        ),
      ];
      await LocalWorkspaceRecordBatchRepository(
        database,
        'bulk',
      ).apply(swap, requestId: 'swap');
      expect(
        (await tables.record(table.id, first.id)).values[table.labelColumnId],
        'B',
      );
      expect(
        (await tables.record(table.id, second.id)).values[table.labelColumnId],
        'A',
      );
      final batch = LocalWorkspaceRecordBatchRepository(database, 'bulk');
      await batch.apply(swap, requestId: 'swap');
      final currentFirst = await tables.record(table.id, first.id);
      final currentSecond = await tables.record(table.id, second.id);
      expect(currentFirst.revision, 2);
      final duplicates = [
        WorkspaceRecordChange(
          table: table,
          record: currentFirst,
          values: {table.labelColumnId: 'C'},
        ),
        WorkspaceRecordChange(
          table: table,
          record: currentSecond,
          values: {table.labelColumnId: 'C'},
        ),
      ];
      await expectLater(
        batch.apply(duplicates, requestId: 'duplicate'),
        throwsA(isA<WorkspaceTableException>()),
      );
      final stale = [
        WorkspaceRecordChange(
          table: table,
          record: currentFirst,
          values: {table.labelColumnId: 'D'},
        ),
        WorkspaceRecordChange(
          table: table,
          record: second,
          values: {table.labelColumnId: 'E'},
        ),
      ];
      await expectLater(
        batch.apply(stale, requestId: 'stale'),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect((await tables.record(table.id, first.id)).values, {
        table.labelColumnId: 'B',
      });
      expect((await tables.record(table.id, second.id)).revision, 2);
    },
  );
  test('one request ID cannot address a different frozen selection', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('receipt'),
            name: 'Receipt',
            type: .local,
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'receipt'),
    );
    final table = await tables.create(name: 'Items', labelName: 'Title');
    final one = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'A'},
    );
    final two = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'B'},
    );
    final batch = LocalWorkspaceRecordBatchRepository(database, 'receipt');
    final originalSelection = [
      WorkspaceRecordChange(
        table: table,
        record: one,
        values: {table.labelColumnId: 'C'},
      ),
    ];
    await batch.apply(originalSelection, requestId: 'same');
    final changedSelection = [
      WorkspaceRecordChange(
        table: table,
        record: two,
        values: {table.labelColumnId: 'D'},
      ),
    ];
    await expectLater(
      batch.apply(changedSelection, requestId: 'same'),
      throwsA(isA<WorkspaceTableException>()),
    );
    expect(
      (await tables.record(table.id, two.id)).values[table.labelColumnId],
      'B',
    );
  });
  test(
    'persisted bulk retry survives reopening without another revision',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'workspace-bulk-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final file = File('${temporary.path}/workspace.sqlite');
      final database = AppDatabase(connection: NativeDatabase(file));
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('persisted'),
              name: 'Persisted',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'persisted'),
      );
      final table = await tables.create(name: 'Items', labelName: 'Title');
      final one = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'A'},
      );
      final two = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'B'},
      );
      final changes = [
        WorkspaceRecordChange(
          table: table,
          record: one,
          values: {table.labelColumnId: 'C'},
        ),
        WorkspaceRecordChange(
          table: table,
          record: two,
          values: {table.labelColumnId: 'D'},
        ),
      ];
      await LocalWorkspaceRecordBatchRepository(
        database,
        'persisted',
      ).apply(changes, requestId: 'persist');
      await database.close();
      final reopened = AppDatabase(connection: NativeDatabase(file));
      addTearDown(reopened.close);
      await LocalWorkspaceRecordBatchRepository(
        reopened,
        'persisted',
      ).apply(changes, requestId: 'persist');
      final persisted = LocalWorkspaceTableRepository(reopened, 'persisted');
      expect((await persisted.record(table.id, one.id)).revision, 2);
      expect(
        (await persisted.record(table.id, two.id)).values[table.labelColumnId],
        'D',
      );
    },
  );
  test('bulk dependencies preserve outside links', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('local'),
            name: 'Local',
            type: .local,
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'local'),
    );
    final parents = await tables.create(name: 'Groups', labelName: 'Name');
    final first = await tables.createRecord(table: parents, values: {});
    final second = await tables.createRecord(table: parents, values: {});
    var targets = await tables.create(name: 'People', labelName: 'Name');
    targets = await tables.saveColumn(
      table: targets,
      column: .new(
        id: '',
        name: 'Group',
        type: .reference,
        targetTableId: parents.id,
      ),
    );
    final targetParent = targets.columns.last.id;
    final one = await tables.createRecord(
      table: targets,
      values: {targetParent: first.id},
    );
    final two = await tables.createRecord(
      table: targets,
      values: {targetParent: second.id},
    );
    var source = await tables.create(name: 'Tasks', labelName: 'Name');
    source = await tables.saveColumn(
      table: source,
      column: .new(
        id: '',
        name: 'Group',
        type: .reference,
        targetTableId: parents.id,
      ),
    );
    final parent = source.columns.last.id;
    source = await tables.saveColumn(
      table: source,
      column: .fromJson({
        'id': '',
        'name': 'Person',
        'type': 'reference',
        'targetTableId': targets.id,
        'dependsOnColumnId': parent,
        'targetMatchColumnId': targetParent,
      }),
    );
    final dependent = source.columns.last.id;

    final record = await tables.createRecord(
      table: source,
      values: {parent: first.id, dependent: one.id},
    );
    final batch = LocalWorkspaceRecordBatchRepository(database, 'local');
    final parentOnly = [
      WorkspaceRecordChange(
        table: targets,
        record: one,
        values: {targetParent: second.id},
      ),
    ];
    await expectLater(
      batch.apply(parentOnly, requestId: 'invalid'),
      throwsA(isA<WorkspaceTableException>()),
    );
    expect((await tables.record(targets.id, one.id)).revision, 1);
    final combined = [
      WorkspaceRecordChange(
        table: targets,
        record: one,
        values: {targetParent: second.id},
      ),
      WorkspaceRecordChange(
        table: source,
        record: record,
        values: {parent: second.id, dependent: one.id},
      ),
    ];
    await batch.apply(combined, requestId: 'combined');
    expect(
      (await tables.record(targets.id, one.id)).values[targetParent],
      second.id,
    );
    expect(
      (await tables.record(source.id, record.id)).values[parent],
      second.id,
    );
    expect((await tables.record(targets.id, two.id)).revision, 1);
  });
  test(
    'approval freezes selected rows and cancellation never writes',
    () async {
      final repository = _Batch();
      final usecase = EditWorkspaceRecordsUsecase(repository);
      final values = <String, Object?>{'label': 'A'};
      final changes = [
        _change('one', values),
        _change('two', {'label': 'B'}),
      ];
      expect(
        await usecase.apply(
          changes,
          requestId: 'cancelled',
          approve: (snapshot) async {
            values['label'] = 'changed';
            changes.clear();
            expect(snapshot.map((change) => change.record.id), ['one', 'two']);

            return false;
          },
        ),
        false,
      );
      expect(repository.applied, isNull);
      final _ = await usecase.apply(
        [
          _change('one', {'label': 'A'}),
        ],
        approve: (_) async => throw StateError('must not ask'),
        mode: .allowAll,
        requestId: 'allow-all',
      );
      expect(repository.applied?.single.values, {'label': 'A'});
      final _ = await usecase.apply(
        [_change('one', values)],
        requestId: 'approved',
        approve: (snapshot) async {
          values['label'] = 'later';

          return true;
        },
      );
      expect(repository.applied?.single.values, {'label': 'changed'});
    },
  );
}

WorkspaceRecordChange _change(String id, Map<String, Object?> values) =>
    WorkspaceRecordChange(
      table: const WorkspaceTable(
        id: 'table',
        name: 'Items',
        labelColumnId: 'label',
        columns: [],
        revision: 1,
        schemaRevision: 1,
      ),
      record: .new(id: id, tableId: 'table', values: const {}, revision: 1),
      values: values,
    );

class _Batch implements WorkspaceRecordBatchRepository {
  List<WorkspaceRecordChange>? applied;
  @override
  Future<void> apply(
    List<WorkspaceRecordChange> changes, {
    required String requestId,
  }) async {
    applied = changes;
  }
}
