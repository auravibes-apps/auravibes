import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_retention.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'bulk preserves hidden retained cells through unrelated edits',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.database.close);
      await fixture.prepare();
      await fixture.unavailable();
      final change = WorkspaceRecordChange(
        table: fixture.table,
        record: fixture.first,
        values: {fixture.table.labelColumnId: 'Changed'},
      );
      final batch = LocalWorkspaceRecordBatchRepository(
        fixture.database,
        'local',
      );
      await batch.apply([change], requestId: 'keep-hidden-asset');
      final hidden = await fixture.tables.record(
        fixture.table.id,
        fixture.first.id,
      );
      expect(hidden.values[fixture.table.labelColumnId], 'Changed');
      expect(hidden.values.containsKey('files'), isFalse);
      final _ = await fixture.database
          .update(fixture.database.workspaceAssets)
          .write(const WorkspaceAssetsCompanion(status: .new('active')));
      expect(
        (await fixture.tables.record(
          fixture.table.id,
          fixture.first.id,
        )).values['files'],
        ['asset'],
      );
    },
  );

  test(
    'bulk cannot authorize an attachment through its own staged value',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.database.close);
      await fixture.prepare();
      final _ = await fixture.database
          .into(fixture.database.workspaceAssets)
          .insert(
            WorkspaceAssetsCompanion.insert(
              id: const .new('forbidden'),
              workspaceId: 'local',
              name: 'private.txt',
              mimeType: 'text/plain',
              sizeBytes: 5,
              checksum: 'b' * 64,
              status: const .new('active'),
            ),
          );
      final _ = await fixture.database
          .into(fixture.database.workspaceFiles)
          .insert(
            WorkspaceFilesCompanion.insert(
              id: const .new('trashed-file'),
              workspaceId: 'local',
              name: 'Trashed',
              assetId: 'forbidden',
              creationHash: 'original',
              deletedAt: .new(DateTime.utc(2026)),
            ),
          );
      final values = {
        fixture.table.labelColumnId: 'Guessed',
        'files': ['forbidden'],
      };
      await expectLater(
        fixture.tables.updateRecord(
          table: fixture.table,
          record: fixture.first,
          values: values,
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      final change = WorkspaceRecordChange(
        table: fixture.table,
        record: fixture.first,
        values: values,
      );
      final batch = LocalWorkspaceRecordBatchRepository(
        fixture.database,
        'local',
      );
      await expectLater(
        batch.apply([change], requestId: 'guess-asset'),
        throwsA(isA<WorkspaceTableException>()),
      );
      final stored = await fixture.tables.record(
        fixture.table.id,
        fixture.first.id,
      );
      expect(stored.values['files'], ['asset']);
      expect(stored.values[fixture.table.labelColumnId], 'Original');
    },
  );

  test(
    'duplicated attachment cells retain shared assets after source purge',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.database.close);
      await fixture.prepare();
      final source = fixture.table;
      final copy = await fixture.tables.duplicate(
        .new(
          kind: .table,
          sourceId: source.id,
          expectedRevision: source.revision,
          targetId: 'copy',
          requestId: 'copy-request',
          name: 'Copy',
          copyRecords: true,
        ),
      );
      final attachment = copy.columns.singleWhere(
        (column) => column.type == .attachment,
      );
      expect(attachment.defaultValue, ['asset']);
      expect(
        (await fixture.tables.records(copy.id)).single.values[attachment.id],
        ['asset'],
      );
      final target = WorkspaceTrashTarget(
        kind: .table,
        id: source.id,
        revision: source.revision,
      );
      final trash = ManageWorkspaceTrashUsecase(
        LocalWorkspaceTrashRepository(fixture.database, 'local'),
      );
      final _ = await trash.apply(target, approve: (_) async => true);
      await fixture.history.permanentlyDelete(target);
      expect(
        (await fixture.tables.records(copy.id)).single.values[attachment.id],
        ['asset'],
      );
      final retained = await fixture.database
          .select(fixture.database.workspaceAssets)
          .get();
      expect(retained, hasLength(1));
      expect(retained.single.id, 'asset');
      expect(retained.single.status, 'active');
    },
  );

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
        revision: cleared.revision,
        tableId: cleared.tableId,
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

  test('schema restore keeps hidden defaults and attachments', () async {
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

  test('hidden defaults survive unrelated schema edits', () async {
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
  WorkspaceTable? _table;
  WorkspaceRecord? _first;
  WorkspaceTable get table =>
      _table ?? (throw StateError('Fixture not prepared'));
  WorkspaceRecord get first =>
      _first ?? (throw StateError('Fixture not prepared'));
  LocalWorkspaceTableRepository get tables => .new(database, 'local');
  LocalWorkspaceHistoryRepository get history => .new(database, 'local');

  set table(WorkspaceTable value) => _table = value;
  set first(WorkspaceRecord value) => _first = value;

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
