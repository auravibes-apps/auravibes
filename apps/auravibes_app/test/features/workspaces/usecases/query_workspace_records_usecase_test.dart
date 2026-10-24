import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/query_workspace_records_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search and stable pages return only matching table records', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('one'),
            name: 'One',
            type: .local,
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final table = await tables.create(name: 'List', labelName: 'Title');
    for (final value in ['Zulu', 'Alpha', 'Other', '\u00c9cho', '\u00e9cho']) {
      final _ = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: value},
      );
    }
    final query = QueryWorkspaceRecordsUsecase(
      LocalWorkspaceRecordQueryRepository(database, 'one'),
    );
    final first = await query(table.id, const WorkspaceRecordQuery(limit: 1));
    expect(first.records.single.values[table.labelColumnId], 'Alpha');
    expect(first.hasMore, isTrue);
    final second = await query(
      table.id,
      const WorkspaceRecordQuery(offset: 1, limit: 1),
    );
    expect(second.records.single.values[table.labelColumnId], 'Other');
    final search = await query(
      table.id,
      const WorkspaceRecordQuery(search: 'zU'),
    );
    expect(search.records.single.values[table.labelColumnId], 'Zulu');
    expect(search.hasMore, isFalse);
    final accented = await query(
      table.id,
      const WorkspaceRecordQuery(search: '\u00c9'),
    );
    expect(accented.records.single.values[table.labelColumnId], '\u00c9cho');
    final numeric = await tables.create(name: 'Numbers', labelName: 'Title');
    final schema = await tables.saveColumn(
      table: numeric,
      column: const WorkspaceColumn(id: '', name: 'Quantity', type: .number),
    );
    final quantity = schema.columns.last.id;
    for (final amount in [10, 2]) {
      final _ = await tables.createRecord(
        table: schema,
        values: {schema.labelColumnId: 'Value $amount', quantity: amount},
      );
    }
    final sorted = await query(
      schema.id,
      WorkspaceRecordQuery(sortColumnId: quantity),
    );
    expect(sorted.records.map((record) => record.values[quantity]), [2, 10]);
    final filtered = await query(
      schema.id,
      WorkspaceRecordQuery(filterColumnId: quantity, filterValue: '10'),
    );
    expect(filtered.records.single.values[quantity], 10);
  });
}
