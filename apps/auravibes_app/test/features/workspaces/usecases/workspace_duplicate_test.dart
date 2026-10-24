import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('table duplication copies schema, not records, unless explicitly chosen', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database.into(database.workspaces).insert(WorkspacesCompanion.insert(id: const Value('copy'), name: 'Copy', type: .local));
    final repository = LocalWorkspaceTableRepository(database, 'copy');
    final tables = OrganizeWorkspaceTablesUsecase(repository);
    final source = await tables.create(name: 'Source', labelName: 'Title');
    final record = await tables.createRecord(table: source, values: {source.labelColumnId: 'Original'});
    final empty = await repository.duplicate(source: source, targetId: 'copy-empty', name: 'Empty', requestId: 'empty');
    expect(empty.id, isNot(source.id));
    expect(empty.labelColumnId, isNot(source.labelColumnId));
    expect(empty.columns.single.name, 'Title');
    expect(await tables.records(empty.id), isEmpty);
    final full = await repository.duplicate(source: source, targetId: 'copy-full', name: 'Full', requestId: 'full', copyRecords: true);
    final copied = await tables.records(full.id);
    expect(copied.single.id, isNot(record.id));
    expect(copied.single.values, {full.labelColumnId: 'Original'});
    await repository.duplicate(source: source, targetId: 'copy-full', name: 'Full', requestId: 'full', copyRecords: true);
    expect(await tables.records(full.id), hasLength(1));
  });
}
