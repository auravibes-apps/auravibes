import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved View persistence, repair and revision behavior', _persistence);
}

Future<void> _persistence() async {
  final database = AppDatabase(connection: NativeDatabase.memory());
  addTearDown(database.close);
  final _ = await database
      .into(database.workspaces)
      .insert(
        WorkspacesCompanion.insert(
          id: const Value('workspace'),
          name: 'Workspace',
          type: .local,
        ),
      );
  final tables = OrganizeWorkspaceTablesUsecase(
    LocalWorkspaceTableRepository(database, 'workspace'),
  );
  var table = await tables.create(name: 'Items', labelName: 'Title');
  final views = ManageWorkspaceViewsUsecase(
    LocalWorkspaceViewRepository(database, 'workspace'),
    tables,
    .new(LocalWorkspaceRecordQueryRepository(database, 'workspace')),
    .new(LocalWorkspaceReferenceRepository(database, 'workspace')),
  );
  final first = await views.create(
    name: 'Overview',
    table: table,
    columnIds: [table.labelColumnId],
  );
  expect((await views.open(first.id)).records, isEmpty);
  final record = await tables.createRecord(
    table: table,
    values: {table.labelColumnId: 'First'},
  );
  expect((await views.open(first.id)).records.single.id, record.id);
  table = await tables.renameLabel(table: table, name: 'Renamed');
  final reopened = await views.open(first.id);
  expect(reopened.needsRepair, isFalse);
  expect(reopened.view.bindings.values.single, table.labelColumnId);

  table = await tables.saveColumn(
    table: table,
    column: const WorkspaceColumn(id: '', name: 'Amount', type: .number),
  );
  final amountId = table.columns.last.id;
  final typedView = await views.create(
    name: 'Numbers',
    table: table,
    columnIds: [amountId],
  );
  table = await tables.saveColumn(
    table: table,
    column: .new(id: amountId, name: 'Amount'),
  );
  expect((await views.open(typedView.id)).needsRepair, isTrue);
  await expectLater(
    views.restore(typedView, typedView),
    throwsA(isA<WorkspaceTableException>()),
  );
  final second = await views.save(first, requestId: 'save-once');
  expect(
    (await views.save(first, requestId: 'save-once')).revision,
    second.revision,
  );
  await expectLater(views.save(first), throwsA(isA<WorkspaceTableException>()));
  final restored = await views.restore(
    second,
    (await views.history(first.id)).first,
  );
  expect(restored.revision, 3);
  expect((await views.history(first.id)).length, 3);
  final _ = await database
      .into(database.workspaces)
      .insert(
        WorkspacesCompanion.insert(
          id: const Value('foreign'),
          name: 'Other',
          type: .local,
        ),
      );
  final foreignTables = OrganizeWorkspaceTablesUsecase(
    LocalWorkspaceTableRepository(database, 'foreign'),
  );
  final other = ManageWorkspaceViewsUsecase(
    LocalWorkspaceViewRepository(database, 'foreign'),
    foreignTables,
    .new(LocalWorkspaceRecordQueryRepository(database, 'foreign')),
    .new(LocalWorkspaceReferenceRepository(database, 'foreign')),
  );
  final foreignTable = await foreignTables.create(
    name: 'Foreign',
    labelName: 'Title',
  );
  final forged = WorkspaceView(
    id: first.id,
    name: 'Forged',
    tableId: foreignTable.id,
    bindings: {'field0': foreignTable.labelColumnId},
    columnTypes: {foreignTable.labelColumnId: 'text'},
    definition: first.definition,
    revision: 0,
  );
  await expectLater(
    other.save(forged),
    throwsA(isA<WorkspaceTableException>()),
  );
  expect((await views.open(first.id)).view.name, 'Overview');
  await expectLater(
    other.open(first.id),
    throwsA(isA<WorkspaceTableException>()),
  );
}
