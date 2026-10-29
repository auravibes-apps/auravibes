import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_csv_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/export_workspace_csv_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_usecase.dart';
import 'package:csv/csv.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CSV preserves asset IDs without duplicating bytes', () async {
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
    final _ = await database
        .into(database.workspaceAssets)
        .insert(
          WorkspaceAssetsCompanion.insert(
            id: const .new('asset'),
            workspaceId: 'local',
            name: 'notes.txt',
            mimeType: 'text/plain',
            sizeBytes: 5,
            checksum: 'a' * 64,
            status: const .new('active'),
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'local'),
    );
    var table = await tables.create(name: 'Items', labelName: 'Name');
    table = await tables.saveColumn(
      table: table,
      column: const WorkspaceColumn(
        id: '',
        name: 'Attachments',
        type: .attachment,
      ),
    );
    final assetColumn = table.columns
        .singleWhere((column) => column.type == .attachment)
        .id;
    final repository = LocalWorkspaceCsvRepository(database, 'local');
    final usecase = WorkspaceCsvUsecase(repository);
    final input = usecase.read(
      csv.encode([
        ['Name', 'Attachments'],
        [
          'Notes',
          jsonEncode(['asset']),
        ],
      ]),
    );
    final preview = await usecase.preview(
      table: table,
      input: input,
      mapping: {0: table.labelColumnId, 1: assetColumn},
    );
    expect(preview.errors, isEmpty);
    await usecase.commit(preview);
    final rows = await tables.records(table.id);
    expect(rows.single.values[assetColumn], ['asset']);
    final exported = await ExportWorkspaceCsvUsecase(repository)(table.id);
    expect(csv.decode(exported).last.last, jsonEncode(['asset']));
    expect(await database.select(database.workspaceAssets).get(), hasLength(1));
    final _ =
        await (database.update(database.workspaceAssets)
              ..where((row) => row.id.equals('asset')))
            .write(const WorkspaceAssetsCompanion(status: .new('pending')));
    final hidden = await tables.record(table.id, rows.single.id);
    expect(hidden.values, isNot(contains(assetColumn)));
    expect(hidden.restrictedReferenceColumns, contains(assetColumn));
    final history = await LocalWorkspaceHistoryRepository(database, 'local')
        .history(
          .new(
            kind: .record,
            id: hidden.id,
            tableId: table.id,
            revision: hidden.revision,
          ),
        );
    expect(history, isNotEmpty);
    for (final snapshot in history) {
      expect(snapshot.data['values'] as Map, isNot(contains(assetColumn)));
    }
    final hiddenExport = await ExportWorkspaceCsvUsecase(repository)(table.id);
    expect(csv.decode(hiddenExport).last.last, '');
    final _ = await tables.updateRecord(
      table: table,
      record: hidden,
      values: {table.labelColumnId: 'Edited'},
    );
    final stored = await (database.select(
      database.workspaceTableRecords,
    )..where((row) => row.id.equals(hidden.id))).getSingle();
    expect((jsonDecode(stored.valuesJson) as Map)[assetColumn], ['asset']);

    await expectLater(
      usecase.preview(
        table: table,
        input: usecase.read(
          csv.encode([
            ['Name', 'Attachments'],
            [
              'Guessed',
              jsonEncode(['missing']),
            ],
          ]),
        ),
        mapping: {0: table.labelColumnId, 1: assetColumn},
      ),
      throwsA(isA<WorkspaceTableException>()),
    );
    expect(await tables.records(table.id), hasLength(1));
  });
}
