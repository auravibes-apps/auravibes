import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(await tables.members(table.id), isEmpty);
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
    await database.close();
    final reopened = AppDatabase(connection: NativeDatabase(file));
    addTearDown(reopened.close);
    final retained = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(reopened, 'one'),
    );
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
            final now = DateTime.now().toUtc();
            final row = WorkspaceResource(
              workspaceId: 1,
              resourceKind: operation.resourceKind,
              resourceId: operation.resourceId,
              data: operation.data ?? (throw StateError('Missing data')),
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
                          'canManageTable': true,
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
      expect(await tables.records(table.id), hasLength(2));
      expect((await tables.list()).single.id, table.id);
    },
  );
}
