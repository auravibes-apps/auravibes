import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/preview_workspace_column_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'constraint previews require corrections and never discard values',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('preview'),
              name: 'Preview',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'preview'),
      );
      var table = await tables.create(name: 'Items', labelName: 'Title');
      table = await tables.saveColumn(
        table: table,
        column: const WorkspaceColumn(id: '', name: 'Value'),
      );
      final id = table.columns.last.id;
      final first = await tables.createRecord(
        table: table,
        values: {id: 'not a number'},
      );
      final second = await tables.createRecord(
        table: table,
        values: {id: 'not a number'},
      );
      final requiredColumn = WorkspaceColumn(
        id: table.labelColumnId,
        name: 'Title',
        isRequired: true,
      );
      expect(
        (await PreviewWorkspaceColumnUsecase(
          tables,
        ).call(table: table, column: requiredColumn)).length,
        2,
      );
      await expectLater(
        tables.saveColumn(table: table, column: requiredColumn),
        throwsA(isA<WorkspaceTableException>()),
      );
      final unchanged = await tables.saveColumn(
        table: table,
        column: table.columns.last,
      );
      expect(unchanged.schemaRevision, table.schemaRevision);
      table = unchanged;
      final unique = WorkspaceColumn(id: id, name: 'Value', isUnique: true);
      expect(
        (await PreviewWorkspaceColumnUsecase(
          tables,
        ).call(table: table, column: unique)).map((record) => record.id),
        [first.id, second.id],
      );
      await expectLater(
        tables.saveColumn(table: table, column: unique),
        throwsA(isA<WorkspaceTableException>()),
      );
      final number = WorkspaceColumn(id: id, name: 'Value', type: .number);
      expect(
        (await PreviewWorkspaceColumnUsecase(
          tables,
        ).call(table: table, column: number)).length,
        2,
      );
      await expectLater(
        tables.saveColumn(table: table, column: number),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await tables.record(table.id, first.id)).values[id],
        'not a number',
      );
      expect(
        (await tables.table(table.id)).schemaRevision,
        table.schemaRevision,
      );
      final _ = await tables.updateRecord(
        table: table,
        record: first,
        values: {id: 'corrected'},
      );
      table = await tables.saveColumn(table: table, column: unique);
      expect(table.columns.last.id, id);
      final stale = table;
      table = await tables.saveColumn(
        table: table,
        column: .new(id: id, name: 'Value', isRequired: true, isUnique: true),
      );
      await expectLater(
        Future.sync(
          () => tables.updateRecord(
            table: stale,
            record: second,
            values: const {},
          ),
        ),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.conflict,
            'conflict',
            true,
          ),
        ),
      );
      await expectLater(
        tables.updateRecord(
          table: table,
          record: second,
          values: {id: 'corrected'},
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );
  test(
    'required unique defaults reject duplicates and preserve explicit zero',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('constraints'),
              name: 'Constraints',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'constraints'),
      );
      var table = await tables.create(name: 'Items', labelName: 'Title');
      table = await tables.saveColumn(
        table: table,
        column: const WorkspaceColumn(
          id: '',
          name: 'Count',
          type: .number,
          isRequired: true,
          isUnique: true,
          defaultValue: 5,
        ),
      );
      final id = table.columns.last.id;
      table = await tables.saveColumn(
        table: table,
        column: const WorkspaceColumn(
          id: '',
          name: 'Enabled',
          type: .checkbox,
          isRequired: true,
          defaultValue: false,
        ),
      );
      final checkboxId = table.columns.last.id;
      table = await tables.saveColumn(
        table: table,
        column: const WorkspaceColumn(
          id: '',
          name: 'Note',
          isRequired: true,
          defaultValue: '',
        ),
      );
      final textId = table.columns.last.id;
      final first = await tables.createRecord(table: table, values: const {});
      expect(first.values[checkboxId], false);
      expect(first.values[textId], '');
      expect((await tables.table(table.id)).columns.last.isRequired, true);
      expect(first.values[id], 5);
      final zero = await tables.createRecord(table: table, values: {id: 0});
      expect(zero.values[id], 0);
      await expectLater(
        Future.sync(() => tables.createRecord(table: table, values: const {})),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect((await tables.records(table.id)).length, 2);
      await expectLater(
        Future.sync(
          () => tables.updateRecord(
            table: table,
            record: first,
            values: const {},
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );
  test(
    'table rename and move preserve record identity and open schema drafts',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('one'),
              name: 'One',
              type: .local,
            ),
          );
      final folders = OrganizeWorkspaceFoldersUsecase(
        LocalWorkspaceFolderRepository(database, 'one'),
      );
      final destination = await folders.create(name: 'Archive');
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'one'),
      );
      final original = await tables.create(
        name: 'Original',
        labelName: 'Title',
      );
      final record = await tables.createRecord(
        table: original,
        values: {original.labelColumnId: 'Preserved'},
      );
      final moved = await tables.updateMetadata(
        table: original,
        name: '  Renamed  ',
        parentId: destination.id,
      );
      expect(
        (id: moved.id, name: moved.name, parentId: moved.parentId),
        (id: original.id, name: 'Renamed', parentId: destination.id),
      );
      expect(
        (schema: moved.schemaRevision, label: moved.labelColumnId),
        (schema: original.schemaRevision, label: original.labelColumnId),
      );
      expect((await tables.record(moved.id, record.id)).values, {
        original.labelColumnId: 'Preserved',
      });
      final second = await tables.createRecord(
        table: original,
        values: {original.labelColumnId: 'Open draft'},
      );
      expect((await tables.record(moved.id, second.id)).values, {
        original.labelColumnId: 'Open draft',
      });
      expect(await tables.list(), isEmpty);
      expect(
        (await tables.list(parentId: destination.id)).single.id,
        original.id,
      );
      await expectLater(
        tables.updateMetadata(table: original, name: 'Stale', parentId: null),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );

  test(
    'formatted columns reject malformed values without changing records',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('one'),
              name: 'One',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'one'),
      );
      var table = await tables.create(name: 'List', labelName: 'Title');
      final values = <String, Object?>{};
      final invalid = <String, Object?>{};
      for (final example in [
        (
          type: WorkspaceColumnType.url,
          valid: 'https://example.com/path?q=1',
          invalid: 'javascript:alert(1)',
        ),
        (
          type: WorkspaceColumnType.email,
          valid: 'david@example.com',
          invalid: 'missing-at',
        ),
        (
          type: WorkspaceColumnType.phone,
          valid: '+1 (555) 123-4567 ext. 12',
          invalid: 'call me',
        ),
      ]) {
        table = await tables.saveColumn(
          table: table,
          column: .new(id: '', name: example.type.name, type: example.type),
        );
        values[table.columns.last.id] = example.valid;
        invalid[table.columns.last.id] = example.invalid;
      }
      final record = await tables.createRecord(table: table, values: values);
      for (final entry in invalid.entries) {
        await expectLater(
          Future.sync(
            () => tables.updateRecord(
              table: table,
              record: record,
              values: {...values, entry.key: entry.value},
            ),
          ),
          throwsA(isA<WorkspaceTableException>()),
        );
      }
      expect((await tables.record(table.id, record.id)).values, values);
      await expectLater(
        Future.sync(
          () => tables.createRecord(
            table: table,
            values: {table.labelColumnId: null},
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );
  test('selection cardinality and configured choices survive edits', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('one'),
            name: 'One',
            type: .local,
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    var table = await tables.create(name: 'List', labelName: 'Title');
    table = await tables.saveColumn(
      table: table,
      column: const .new(
        id: '',
        name: 'Status',
        type: .singleSelect,
        options: ['Open', 'Done'],
      ),
    );
    final single = table.columns.last;
    table = await tables.saveColumn(
      table: table,
      column: const .new(
        id: '',
        name: 'Tags',
        type: .multiSelect,
        options: ['A', 'B'],
      ),
    );
    final multiple = table.columns.last;
    final record = await tables.createRecord(
      table: table,
      values: {
        single.id: 'Open',
        multiple.id: ['A', 'B'],
      },
    );
    expect((await tables.record(table.id, record.id)).values, {
      single.id: 'Open',
      multiple.id: ['A', 'B'],
    });
    for (final invalid in <Map<String, Object?>>[
      {
        single.id: ['Open'],
      },
      {multiple.id: 'A'},
      {single.id: 'Unknown'},
      {
        multiple.id: ['A', 'A'],
      },
    ]) {
      await expectLater(
        Future.sync(() => tables.createRecord(table: table, values: invalid)),
        throwsA(isA<WorkspaceTableException>()),
      );
    }
    await expectLater(
      tables.saveColumn(
        table: table,
        column: .new(
          id: single.id,
          name: 'Status',
          type: .singleSelect,
          options: ['Done'],
        ),
      ),
      throwsA(isA<WorkspaceTableException>()),
    );
    expect((await tables.table(table.id)).schemaRevision, table.schemaRevision);
    expect(
      (await tables.record(table.id, record.id)).values[single.id],
      'Open',
    );
  });
  test(
    'checkbox columns persist false without treating it as missing',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('one'),
              name: 'One',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'one'),
      );
      final initial = await tables.create(name: 'List', labelName: 'Title');
      final table = await tables.saveColumn(
        table: initial,
        column: const .new(id: '', name: 'Done', type: .checkbox),
      );
      final column = table.columns.last;
      final record = await tables.createRecord(
        table: table,
        values: {column.id: false, table.labelColumnId: ''},
      );
      expect((await tables.record(table.id, record.id)).values, {
        column.id: false,
        table.labelColumnId: '',
      });
      await expectLater(
        Future.sync(
          () => tables.createRecord(table: table, values: {column.id: 'false'}),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );
  test('number columns persist zero separately from a missing value', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('one'),
            name: 'One',
            type: .local,
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final initial = await tables.create(name: 'List', labelName: 'Title');
    final table = await tables.saveColumn(
      table: initial,
      column: const .new(id: '', name: 'Count', type: .number),
    );
    final number = table.columns.last;
    final zero = await tables.createRecord(
      table: table,
      values: {number.id: 0},
    );
    final missing = await tables.createRecord(table: table, values: {});
    expect((await tables.record(table.id, zero.id)).values[number.id], 0);
    expect(
      (await tables.record(table.id, missing.id)).values.containsKey(number.id),
      false,
    );
    expect(
      (await tables.table(table.id)).columns.last.type,
      WorkspaceColumnType.number,
    );
  });
  test('create a table and independently edit openable text records', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('one'),
            name: 'One',
            type: .local,
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final table = await tables.create(name: 'My list', labelName: 'Title');
    expect(table.canManage, true);
    expect(table.canEditRecords, true);
    expect(table.supportsSharing, false);
    final column = table.columns.single;
    final first = await tables.createRecord(
      table: table,
      values: {column.id: 'First'},
    );
    final second = await tables.createRecord(
      table: table,
      values: {column.id: 'Second'},
    );
    final edited = await tables.updateRecord(
      table: table,
      record: first,
      values: {column.id: 'Changed'},
    );
    final otherEdited = await tables.updateRecord(
      table: table,
      record: second,
      values: {column.id: 'Also changed'},
    );
    expect(edited.id, first.id);
    expect(otherEdited.id, second.id);
    expect(
      (await tables.record(table.id, first.id)).values[column.id],
      'Changed',
    );
    expect((await tables.records(table.id)).length, 2);
    expect((await tables.list()).single.id, table.id);
  });
  test('stale record and schema writes preserve current values', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('one'),
            name: 'One',
            type: .local,
          ),
        );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final table = await tables.create(name: 'List', labelName: 'Title');
    final column = table.columns.single.id;
    final record = await tables.createRecord(
      table: table,
      values: {column: 'Original'},
    );
    final edited = await tables.updateRecord(
      table: table,
      record: record,
      values: {column: 'Changed'},
    );
    await expectLater(
      tables.updateRecord(
        table: table,
        record: record,
        values: {column: 'Stale'},
      ),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.conflict,
          'conflict',
          true,
        ),
      ),
    );
    final renamed = await tables.renameLabel(table: table, name: 'Summary');
    expect(renamed.columns.single.id, column);
    expect(renamed.columns.single.name, 'Summary');
    await expectLater(
      tables.createRecord(table: table, values: {column: 'Stale schema'}),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.conflict,
          'conflict',
          true,
        ),
      ),
    );
    await expectLater(
      tables.renameLabel(table: table, name: 'Stale title'),
      throwsA(isA<WorkspaceTableException>()),
    );
    final fresh = await tables.updateRecord(
      table: renamed,
      record: edited,
      values: {column: 'Latest'},
    );
    expect(fresh.values[column], 'Latest');
    expect((await tables.records(table.id)).length, 1);
  });
  test('local tables survive reopen and stay in their workspace', () async {
    final directory = await Directory.systemTemp.createTemp(
      'workspace-tables-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/tables.sqlite');
    final database = AppDatabase(connection: NativeDatabase(file));
    for (final id in ['one', 'two']) {
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(id: .new(id), name: id, type: .local),
          );
    }
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final table = await tables.create(name: 'List', labelName: 'Title');
    final record = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'Retained'},
    );
    final other = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'two'),
    );
    expect(await other.list(), isEmpty);
    await expectLater(
      other.table(table.id),
      throwsA(isA<WorkspaceTableException>()),
    );
    await expectLater(
      other.createRecord(table: table, values: {}),
      throwsA(isA<WorkspaceTableException>()),
    );
    final renamed = await tables.updateMetadata(
      table: table,
      name: 'Retained name',
      parentId: null,
    );
    expect(renamed.schemaRevision, table.schemaRevision);
    await database.close();
    final reopened = AppDatabase(connection: NativeDatabase(file));
    addTearDown(reopened.close);
    final retained = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(reopened, 'one'),
    );
    expect((await retained.table(table.id)).name, 'Retained name');
    expect(
      (await retained.table(table.id)).columns.single.id,
      table.labelColumnId,
    );
    expect(
      (await retained.record(table.id, record.id)).values[table.labelColumnId],
      'Retained',
    );
  });
  test(
    'cloud tables create and edit records through paginated remote state',
    () async {
      final rows = <WorkspaceResource>[];
      var canEditRecords = true;
      var canManage = true;
      final store = CloudWorkspaceResourceStore.forTesting(
        watch: (_) => const Stream.empty(),
        patch: ({required requestId, required operations}) async {
          final results = <WorkspaceResource>[];
          for (final operation in operations) {
            final index = rows.indexWhere(
              (row) =>
                  row.resourceKind == operation.resourceKind &&
                  row.resourceId == operation.resourceId,
            );
            final payload = jsonDecode(
              operation.data ?? (throw StateError('Missing data')),
            ) as Map<String, dynamic>;
            if (operation.resourceKind == .table) {
              if (index < 0) {
                payload['memberAccess'] = {'viewer': 'read'};
              } else {
                expect(payload['memberAccess'], {'viewer': 'read'});
              }
            }
            final now = DateTime.now().toUtc();
            final row = WorkspaceResource(
              workspaceId: 1,
              resourceKind: operation.resourceKind,
              resourceId: operation.resourceId,
              data: jsonEncode(payload),
              revision: index < 0 ? 1 : rows[index].revision + 1,
              createdAt: now,
              updatedAt: now,
            );
            if (index < 0) {
              rows.add(row);
            } else {
              rows[index] = row;
            }
            results.add(row);
          }

          return PatchWorkspaceStateResponse(
            resources: results,
            sequence: rows.length,
          );
        },
        putSecret: (_) => throw StateError('Unexpected secret'),
        mutateCredential: (_) => throw StateError('Unexpected credential'),
        read: ({required pages, required eventLimit, afterSequence}) async {
          final request = pages.single;
          final matching = rows
              .where((row) => row.resourceKind == request.resourceKind)
              .toList();
          final index = request.afterResourceId == null
              ? 0
              : matching.indexWhere(
                      (row) => row.resourceId == request.afterResourceId,
                    ) +
                    1;
          final page = matching
              .skip(index)
              .take(1)
              .map(
                (row) => row.resourceKind == WorkspaceResourceKind.table
                    ? row.copyWith(
                        data: jsonEncode({
                          ...jsonDecode(row.data) as Map<String, dynamic>,
                          'canManageTable': canManage,
                          'canEditRecords': canEditRecords,
                        }),
                      )
                    : row,
              )
              .toList();

          return ReadWorkspaceStateResponse(
            pages: [
              WorkspaceResourcePage(
                resourceKind: request.resourceKind,
                resources: page,
                nextResourceId: index + 1 < matching.length
                    ? page.single.resourceId
                    : null,
              ),
            ],
            currentSequence: rows.length,
            events: [],
            requiresSnapshot: false,
          );
        },
      );
      final tables = OrganizeWorkspaceTablesUsecase(
        CloudWorkspaceTableRepository(store),
      );
      expect(await tables.list(), isEmpty);
      final table = await tables.create(name: 'My list', labelName: 'Title');
      final first = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'First'},
      );
      final second = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Second'},
      );
      final edited = await tables.updateRecord(
        table: table,
        record: first,
        values: {table.labelColumnId: 'Changed'},
      );
      expect(edited.id, first.id);
      expect(
        (await tables.record(table.id, first.id)).values[table.labelColumnId],
        'Changed',
      );
      expect(
        (await tables.record(table.id, second.id)).values[table.labelColumnId],
        'Second',
      );
      final renamed = await tables.renameLabel(table: table, name: 'Summary');
      expect(renamed.labelColumnId, table.labelColumnId);
      expect(renamed.columns.single.name, 'Summary');
      canEditRecords = false;
      canManage = false;
      final readOnly = await tables.table(table.id);
      expect(
        () => tables.createRecord(
          table: readOnly,
          values: {table.labelColumnId: 'Denied'},
        ),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.denied,
            'denied',
            true,
          ),
        ),
      );
      expect(
        () => tables.updateMetadata(
          table: readOnly,
          name: 'Denied',
          parentId: null,
        ),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.denied,
            'denied',
            true,
          ),
        ),
      );
      expect(await tables.records(table.id), hasLength(2));
      expect((await tables.list()).single.id, table.id);
      canEditRecords = true;
      canManage = true;
      var typed = renamed;
      final typedValues = <String, Object?>{typed.labelColumnId: ''};
      for (final example
          in <
            ({WorkspaceColumnType type, Object? value, List<String> options})
          >[
            (type: .number, value: 0, options: []),
            (type: .checkbox, value: false, options: []),
            (type: .singleSelect, value: 'A', options: ['A', 'B']),
            (type: .multiSelect, value: ['A', 'B'], options: ['A', 'B']),
            (type: .url, value: 'https://example.com', options: []),
            (type: .email, value: 'david@example.com', options: []),
            (type: .phone, value: '+1 (555) 123-4567', options: []),
          ]) {
        typed = await tables.saveColumn(
          table: typed,
          column: .new(
            id: '',
            name: example.type.name,
            type: example.type,
            options: example.options,
          ),
        );
        typedValues[typed.columns.last.id] = example.value;
      }
      final typedRecord = await tables.createRecord(
        table: typed,
        values: typedValues,
      );
      expect(
        (await tables.record(typed.id, typedRecord.id)).values,
        typedValues,
      );
      final unchanged = await tables.saveColumn(
        table: typed,
        column: typed.columns.last,
      );
      expect(unchanged.schemaRevision, typed.schemaRevision);
      typed = unchanged;
      final moved = await tables.updateMetadata(
        table: typed,
        name: 'Renamed remotely',
        parentId: null,
      );
      final refreshed = OrganizeWorkspaceTablesUsecase(
        CloudWorkspaceTableRepository(store),
      );
      final reopened = await refreshed.table(moved.id);
      expect(
        (id: reopened.id, name: reopened.name, schema: reopened.schemaRevision),
        (id: typed.id, name: 'Renamed remotely', schema: typed.schemaRevision),
      );
      expect(
        (await refreshed.record(moved.id, typedRecord.id)).values,
        typedValues,
      );
      expect(
        (await tables.table(typed.id)).columns.map((column) => column.type),
        containsAll(WorkspaceColumnType.values),
      );
    },
  );
}
