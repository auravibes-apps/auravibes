import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_retention.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'legacy history without attachment provenance cannot retain guessed IDs',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.database.close);
      await fixture.prepare();
      fixture.table = await fixture.tables.saveColumn(
        table: fixture.table,
        column: const WorkspaceColumn(
          id: 'files',
          name: 'Attachments',
          type: .attachment,
        ),
      );
      final _ = await fixture.tables.updateRecord(
        table: fixture.table,
        record: fixture.first,
        values: {fixture.table.labelColumnId: 'Cleared'},
      );
      final _ = await fixture.database
          .delete(fixture.database.workspaceRevisions)
          .go();
      final _ = await fixture.database
          .into(fixture.database.workspaceRevisions)
          .insert(
            WorkspaceRevisionsCompanion.insert(
              workspaceId: 'local',
              kind: 'record',
              resourceId: fixture.first.id,
              revision: 1,
              data: jsonEncode({
                'tableId': fixture.table.id,
                'values': {
                  'files': ['asset'],
                },
              }),
            ),
          );
      expect(
        await LocalWorkspaceAssetRetention(fixture.database, 'local').ids(),
        isEmpty,
      );
    },
  );

  test(
    'configured history expiry queues only assets with no retained use',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.database.close);
      await fixture.prepare();
      fixture.table = await fixture.tables.saveColumn(
        table: fixture.table,
        column: const WorkspaceColumn(
          id: 'files',
          name: 'Attachments',
          type: .attachment,
        ),
      );
      final cleared = await fixture.tables.updateRecord(
        table: fixture.table,
        record: fixture.first,
        values: {fixture.table.labelColumnId: 'Cleared'},
      );
      await fixture.database.customStatement(
        'UPDATE workspace_revisions SET captured_at = 1',
      );
      final target = WorkspaceTrashTarget(
        kind: .record,
        id: cleared.id,
        tableId: cleared.tableId,
        revision: cleared.revision,
      );
      expect(await fixture.history.history(target), isNotEmpty);
      expect(
        (await fixture.database
                .select(fixture.database.workspaceAssets)
                .getSingle())
            .status,
        'active',
      );
      await fixture.history.configure(await fixture.history.policy(), 1);
      expect(
        (await fixture.database
                .select(fixture.database.workspaceAssets)
                .getSingle())
            .status,
        'deleting',
      );
      expect(await fixture.history.history(target), isEmpty);
      expect(
        (await fixture.tables.record(cleared.tableId, cleared.id)).values,
        {fixture.table.labelColumnId: 'Cleared'},
      );
    },
  );

  test('schema restore preserves unchanged unavailable defaults and record references', () async {
    final fixture = _Fixture();
    addTearDown(fixture.database.close);
    await fixture.prepare();
    final original = fixture.table;
    final column = original.columns.singleWhere(
      (column) => column.type == .attachment,
    );
    final renamed = await fixture.tables.saveColumn(
      table: original,
      column: column.renamed('Renamed'),
    );
    await fixture.unavailable();
    await fixture.history.restore(
      .new(kind: .table, id: renamed.id, revision: renamed.revision),
      original.revision,
    );
    final visible = await fixture.tables.table(renamed.id);
    expect(
      visible.columns.singleWhere((item) => item.id == column.id).name,
      'Attachments',
    );
    final stored = await (fixture.database.select(
      fixture.database.workspaceTables,
    )..where((row) => row.id.equals(visible.id))).getSingle();
    expect(stored.columnsJson, contains('"defaultValue":["asset"]'));
    final record = await (fixture.database.select(
      fixture.database.workspaceTableRecords,
    )..where((row) => row.id.equals(fixture.first.id))).getSingle();
    expect(record.valuesJson, contains('"files":["asset"]'));
  });

  test(
    'restoring an unavailable historical asset cannot silently omit it',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.database.close);
      await fixture.prepare();
      final cleared = await fixture.tables.updateRecord(
        table: fixture.table,
        record: fixture.first,
        values: {fixture.table.labelColumnId: 'Cleared'},
      );
      await fixture.unavailable();
      await expectLater(
        fixture.history.restore(
          .new(
            kind: .record,
            id: cleared.id,
            tableId: cleared.tableId,
            revision: cleared.revision,
          ),
          1,
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await fixture.tables.record(cleared.tableId, cleared.id)).revision,
        cleared.revision,
      );
    },
  );

  test('unavailable defaults stay hidden in tables and history but survive unrelated schema edits', () async {
    final fixture = _Fixture();
    addTearDown(fixture.database.close);
    await fixture.prepare();
    await fixture.unavailable();
    final visible = await fixture.tables.table(fixture.table.id);
    final column = visible.columns.singleWhere(
      (column) => column.type == .attachment,
    );
    expect(column.defaultValue, isNull);
    final snapshots = await fixture.history.history(
      .new(kind: .table, id: visible.id, revision: visible.revision),
    );
    for (final snapshot in snapshots) {
      expect(
        jsonEncode(snapshot.data),
        isNot(contains('"defaultValue":["asset"]')),
      );
    }
    final renamed = await fixture.tables.saveColumn(
      table: visible,
      column: column.renamed('Files'),
    );
    expect(
      renamed.columns.singleWhere((item) => item.id == column.id).defaultValue,
      isNull,
    );
    final stored = await (fixture.database.select(
      fixture.database.workspaceTables,
    )..where((row) => row.id.equals(visible.id))).getSingle();
    expect(stored.columnsJson, contains('"defaultValue":["asset"]'));
  });
}

class _Fixture {
  final database = AppDatabase(connection: NativeDatabase.memory());
  late WorkspaceTable table;
  late WorkspaceRecord first;
  LocalWorkspaceTableRepository get tables => .new(database, 'local');
  LocalWorkspaceHistoryRepository get history => .new(database, 'local');

  Future<void> prepare() async {
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
    table = await tables.create(name: 'Data', labelName: 'Name');
    table = await tables.saveColumn(
      table: table,
      column: const WorkspaceColumn(
        id: 'files',
        name: 'Attachments',
        type: .attachment,
        defaultValue: ['asset'],
      ),
    );
    first = await tables.createRecord(
      table: table,
      values: {
        table.labelColumnId: 'Original',
        'files': ['asset'],
      },
    );
  }

  Future<void> unavailable() async {
    final _ =
        await (database.update(database.workspaceAssets)
              ..where((row) => row.id.equals('asset')))
            .write(const WorkspaceAssetsCompanion(status: .new('pending')));
  }
}
