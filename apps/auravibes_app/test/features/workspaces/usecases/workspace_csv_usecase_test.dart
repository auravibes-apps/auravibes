import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_csv_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/export_workspace_csv_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_usecase.dart';
import 'package:csv/csv.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CSV preview maps columns without writes, then commits all records',
    () async {
      final db = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(db.close);
      final _ = await db
          .into(db.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('csv'),
              name: 'CSV',
              type: .local,
            ),
          );
      final tables = LocalWorkspaceTableRepository(db, 'csv');
      final table = await tables.create(name: 'Items', labelName: 'Title');
      final csv = WorkspaceCsvUsecase(LocalWorkspaceCsvRepository(db, 'csv'));
      final input = csv.read('Name\r\n"Hello,\nworld"\r\n"A ""quote"""\r\n');
      final preview = await csv.preview(
        table: table,
        input: input,
        mapping: {0: table.labelColumnId},
      );
      expect(preview.errors, isEmpty);
      expect(await tables.records(table.id), isEmpty);
      await csv.commit(preview);
      expect(
        (await tables.records(table.id))
            .map((row) => row.values[table.labelColumnId]),
        ['Hello,\nworld', 'A "quote"'],
      );
    },
  );
  test(
    'trashed target exports retained IDs through explicit read proof',
    () async {
      final db = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(db.close);
      final _ = await db
          .into(db.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('csv'),
              name: 'CSV',
              type: .local,
            ),
          );
      final tables = LocalWorkspaceTableRepository(db, 'csv');
      final target = await tables.create(name: 'Target', labelName: 'Name');
      final linked = await tables.createRecord(
        table: target,
        values: {target.labelColumnId: 'Private deleted label'},
      );
      var source = await tables.create(name: 'Source', labelName: 'Name');
      source = await tables.saveColumn(
        table: source,
        column: .new(
          id: 'link',
          name: 'Link',
          type: .reference,
          targetTableId: target.id,
        ),
      );
      final _ = await tables.createRecord(
        table: source,
        values: {source.columns.last.id: linked.id},
      );
      final trash = LocalWorkspaceTrashRepository(db, 'csv');
      final plan = await trash.preview(
        .new(kind: .table, id: target.id, revision: target.revision),
      );
      final _ = await trash.trash(plan.target, planToken: plan.planToken);
      final csv = LocalWorkspaceCsvRepository(db, 'csv');
      expect(await csv.readableDeletedReference(target.id, linked.id), isTrue);
      expect(await csv.readableDeletedReference(target.id, 'missing'), isFalse);
      final output = await ExportWorkspaceCsvUsecase(csv)(source.id);
      expect(output, contains(linked.id));
      expect(output, isNot(contains('Private deleted label')));
    },
  );
  test('CSV rejects invalid typed values without writes', () async {
    final db = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(db.close);
    final _ = await db
        .into(db.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('csv'),
            name: 'CSV',
            type: .local,
          ),
        );
    final tables = LocalWorkspaceTableRepository(db, 'csv');
    var table = await tables.create(name: 'Items', labelName: 'Title');
    table = await tables.saveColumn(
      table: table,
      column: .new(id: table.labelColumnId, name: 'Title', isUnique: true),
    );
    table = await tables.saveColumn(
      table: table,
      column: const WorkspaceColumn(
        id: 'amount',
        name: 'Amount',
        type: .money,
        isRequired: true,
      ),
    );
    final csv = WorkspaceCsvUsecase(LocalWorkspaceCsvRepository(db, 'csv'));
    final preview = await csv.preview(
      table: table,
      input: csv.read('Title,Amount\r\nFirst,invalid\r\n'),
      mapping: {0: table.labelColumnId, 1: 'amount'},
    );
    expect(preview.errors, isNotEmpty);
    await expectLater(
      Future.sync(() => csv.commit(preview)),
      throwsA(isA<WorkspaceTableException>()),
    );
    expect(await tables.records(table.id), isEmpty);
  });

  test('exact values and relationship identities round-trip', () async {
    final db = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(db.close);
    final _ = await db
        .into(db.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('csv'),
            name: 'CSV',
            type: .local,
          ),
        );
    final tables = LocalWorkspaceTableRepository(db, 'csv');
    final target = await tables.create(name: 'Targets', labelName: 'Name');
    final linked = await tables.createRecord(
      table: target,
      values: {target.labelColumnId: 'Linked'},
    );
    var table = await tables.create(name: 'Items', labelName: 'Title');
    for (final column in [
      const WorkspaceColumn(id: 'money', name: 'Money', type: .money),
      const WorkspaceColumn(id: 'date', name: 'Date', type: .dateOnly),
      const WorkspaceColumn(id: 'instant', name: 'Instant', type: .timestamp),
      WorkspaceColumn(
        id: 'link',
        name: 'Link',
        type: .reference,
        targetTableId: target.id,
      ),
      WorkspaceColumn(
        id: 'links',
        name: 'Links',
        type: .reference,
        targetTableId: target.id,
        referenceMultiple: true,
      ),
    ]) {
      table = await tables.saveColumn(table: table, column: column);
    }
    final repository = LocalWorkspaceCsvRepository(db, 'csv');
    final csv = WorkspaceCsvUsecase(repository);
    final money = {'amount': '900719925474099312345.00100', 'currency': 'USD'};
    final input = const ListToCsvConverter().convert([
      ['Name', 'Money', 'Date', 'Instant', 'Link', 'Links'],
      [
        '=SUM(1,2)',
        jsonEncode(money),
        '2024-02-29',
        '2026-10-24T06:00:00.000001Z',
        'Linked',
        jsonEncode([linked.id]),
      ],
    ]);
    final preview = await csv.preview(
      table: table,
      input: csv.read(input),
      mapping: {
        0: table.labelColumnId,
        1: 'money',
        2: 'date',
        3: 'instant',
        4: 'link',
        5: 'links',
      },
    );
    expect(preview.errors, isEmpty);
    await csv.commit(preview);
    final records = await tables.records(table.id);
    expect(records.single.values['money'], money);
    expect(records.single.values['date'], '2024-02-29');
    expect(records.single.values['instant'], '2026-10-24T06:00:00.000001Z');
    expect(records.single.values['link'], linked.id);
    final exported = await ExportWorkspaceCsvUsecase(repository)(table.id);
    final decoded = const CsvToListConverter(shouldParseNumbers: false)
        .convert(exported);
    expect(decoded.last, contains(linked.id));
    expect(decoded.last, contains('Linked'));
    expect(decoded.last, contains(jsonEncode('=SUM(1,2)')));
    final ambiguous = await tables.createRecord(
      table: target,
      values: {target.labelColumnId: 'Linked'},
    );
    expect(ambiguous.id, isNot(linked.id));
    final rejected = await csv.preview(
      table: table,
      input: csv.read(input),
      mapping: {
        0: table.labelColumnId,
        1: 'money',
        2: 'date',
        3: 'instant',
        4: 'link',
        5: 'links',
      },
    );
    expect(rejected.errors, isNotEmpty);
    expect((await tables.records(table.id)).length, 1);
  });

  test(
    'current constraints revalidate after preview and reject the whole import',
    () async {
      final db = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(db.close);
      final _ = await db
          .into(db.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('csv'),
              name: 'CSV',
              type: .local,
            ),
          );
      final tables = LocalWorkspaceTableRepository(db, 'csv');
      var table = await tables.create(name: 'Items', labelName: 'Title');
      table = await tables.saveColumn(
        table: table,
        column: .new(id: table.labelColumnId, name: 'Title', isUnique: true),
      );
      final csv = WorkspaceCsvUsecase(LocalWorkspaceCsvRepository(db, 'csv'));
      final preview = await csv.preview(
        table: table,
        input: csv.read('Name\nFirst\nSecond\n'),
        mapping: {0: table.labelColumnId},
      );
      expect(preview.errors, isEmpty);
      final _ = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Second'},
      );
      await expectLater(
        csv.commit(preview),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await tables.records(table.id))
            .map((row) => row.values[table.labelColumnId]),
        ['Second'],
      );
    },
  );
  test(
    'export omits restricted relation IDs and labels without target reads',
    () async {
      final output = await const ExportWorkspaceCsvUsecase(_RestrictedExport())(
        'source',
      );
      expect(output, contains('Owned title'));
      expect(output, isNot(contains('secret-record')));
      expect(output, isNot(contains('Secret label')));
    },
  );
  test('CSV detects row endings without changing quoted newlines', () {
    const csv = WorkspaceCsvUsecase(_RestrictedExport());
    final input = csv.read(
      '"First\nheader",Other\r\nValue,"line\r\nbreak"\r\n',
    );
    expect(input.headers, ['First\nheader', 'Other']);
    expect(input.rows, [
      ['Value', 'line\r\nbreak'],
    ]);
  });
  test('malformed CSV reports an actionable file error before writes', () {
    const csv = WorkspaceCsvUsecase(_RestrictedExport());
    expect(
      () => csv.read('Name\r\n"unfinished'),
      throwsA(
        isA<WorkspaceCsvException>().having(
          (error) => error.localizationKey,
          'reason',
          'workspace_csv.invalid_file',
        ),
      ),
    );
  });
  test('deleted-reference proof keeps authorized IDs without labels', () async {
    final output = await const ExportWorkspaceCsvUsecase(
      _RestrictedExport(restricted: false, deletedProof: true),
    )('source');
    expect(output, contains('secret-record'));
    expect(output, isNot(contains('Secret label')));
  });
  test('denied target lookup fails closed for a stale projection', () async {
    await expectLater(
      const ExportWorkspaceCsvUsecase(_RestrictedExport(restricted: false))(
        'source',
      ),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.denied,
          'denied',
          isTrue,
        ),
      ),
    );
  });
}

class const _RestrictedExport({
  final bool restricted = true,
  final bool deletedProof = false,
}) implements WorkspaceCsvRepository {
  @override
  Future<bool> readableDeletedReference(
    String tableId,
    String recordId,
  ) async => deletedProof;

  @override
  Future<WorkspaceTable> table(String id) async {
    if (id != 'source') throw const WorkspaceTableException(denied: true);

    return const WorkspaceTable(
      id: 'source',
      name: 'Source',
      labelColumnId: 'label',
      columns: [
        WorkspaceColumn(id: 'label', name: 'Title'),
        WorkspaceColumn(
          id: 'link',
          name: 'Link',
          type: .reference,
          targetTableId: 'secret',
        ),
      ],
      revision: 1,
      schemaRevision: 1,
    );
  }

  @override
  Future<WorkspaceRecordPage> query(
    String tableId,
    WorkspaceRecordQuery query,
  ) async {
    if (tableId != 'source') throw const WorkspaceTableException(denied: true);

    return WorkspaceRecordPage(
      records: [
        WorkspaceRecord(
          id: 'owned',
          tableId: 'source',
          values: {'label': 'Owned title', 'link': 'secret-record'},
          revision: 1,
          restrictedReferenceColumns: restricted ? const ['link'] : const [],
        ),
      ],
      hasMore: false,
    );
  }

  @override
  Future<void> write(
    WorkspaceCsvPreview preview, {
    required bool previewOnly,
  }) => throw UnsupportedError('Read only fixture');
}
