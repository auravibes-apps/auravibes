import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reference IDs survive target renames and reject foreign targets', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    for (final id in ['one', 'two']) {
      await database.into(database.workspaces).insert(
        WorkspacesCompanion.insert(id: Value(id), name: id, type: .local),
      );
    }
    final tables = OrganizeWorkspaceTablesUsecase(LocalWorkspaceTableRepository(database, 'one'));
    final foreign = OrganizeWorkspaceTablesUsecase(LocalWorkspaceTableRepository(database, 'two'));
    var target = await tables.create(name: 'People', labelName: 'Name');
    final person = await tables.createRecord(table: target, values: {target.labelColumnId: 'Ada'});
    var source = await tables.create(name: 'Tasks', labelName: 'Title');
    source = await tables.saveColumn(table: source, column: WorkspaceColumn(
      id: '', name: 'Owner', type: .reference, targetTableId: target.id,
    ));
    final references = BrowseWorkspaceReferencesUsecase(LocalWorkspaceReferenceRepository(database, 'one'));
    final link = source.columns.last.id;
    final task = await tables.createRecord(table: source, values: {link: person.id});
    final options = await references.targets(sourceTableId: source.id, columnId: link, search: 'ada');
    expect(options.records.map((row) => row.id), [person.id]);
    expect(options.nextId, isNull);
    final reverse = await references.reverse(tableId: target.id, recordId: person.id);
    expect(reverse.records.map((row) => row.id), [task.id]);
    target = await tables.updateMetadata(table: target, name: 'Contacts', parentId: null);
    expect((await tables.record(source.id, task.id)).values[link], person.id);
    final other = await foreign.create(name: 'Other', labelName: 'Name');
    final outsider = await foreign.createRecord(table: other, values: {});
    await expectLater(tables.updateRecord(table: source, record: task,
      values: {link: outsider.id}), throwsA(isA<WorkspaceTableException>()));
    await expectLater(tables.saveColumn(table: source, column: WorkspaceColumn(
      id: '', name: 'Invalid', type: .reference, targetTableId: other.id,
    )), throwsA(isA<WorkspaceTableException>()));
  });
}
