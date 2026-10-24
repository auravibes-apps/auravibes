import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
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
    for (final value in [
      'Zulu',
      'Alpha',
      'Other',
      '${String.fromCharCode(0xc9)}cho',
      '${String.fromCharCode(0xe9)}cho',
    ]) {
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
    final accented = await query(table.id, .new(search: .fromCharCode(0xc9)));
    expect(
      accented.records.single.values[table.labelColumnId],
      '${String.fromCharCode(0xc9)}cho',
    );
    final numeric = await tables.create(name: 'Numbers', labelName: 'Title');
    final schema = await tables.saveColumn(
      table: numeric,
      column: const WorkspaceColumn(id: '', name: 'Quantity', type: .number),
    );
    final quantity = schema.columns.last.id;
    for (final amount in [
      10,
      2,
      -9007199254740992,
      int.parse('-9007199254740993'),
    ]) {
      final _ = await tables.createRecord(
        table: schema,
        values: {schema.labelColumnId: 'Value $amount', quantity: amount},
      );
    }
    final sorted = await query(schema.id, .new(sortColumnId: quantity));
    expect(sorted.records.map((record) => record.values[quantity]), [
      int.parse('-9007199254740993'),
      -9007199254740992,
      2,
      10,
    ]);
    final filtered = await query(
      schema.id,
      .new(filterColumnId: quantity, filterValue: '10'),
    );
    expect(filtered.records.single.values[quantity], 10);
  });
  test(
    'typed queries compare exact timestamps, money and numeric equality',
    () async {
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
      var table = await tables.create(name: 'Values', labelName: 'Title');
      for (final column in const [
        WorkspaceColumn(id: '', name: 'Instant', type: .timestamp),
        WorkspaceColumn(id: '', name: 'Cost', type: .money),
        WorkspaceColumn(id: '', name: 'Quantity', type: .number),
      ]) {
        table = await tables.saveColumn(table: table, column: column);
      }
      final instant = table.columns
          .firstWhere((column) => column.name == 'Instant')
          .id;
      final cost = table.columns
          .firstWhere((column) => column.name == 'Cost')
          .id;
      final quantity = table.columns.last.id;
      for (final value in [
        (
          label: 'A',
          instant: '2026-10-23T10:00:00.000001Z',
          amount: '-9007199254740993.00001',
        ),
        (
          label: 'B',
          instant: '2026-10-23T10:00:00Z',
          amount: '-9007199254740993.00002',
        ),
        (label: 'C', instant: '2026-10-23T10:00:00.1Z', amount: '0.00'),
        (label: 'D', instant: '2026-10-23T10:00:00.000000Z', amount: '-0'),
        (
          label: 'E',
          instant: '2026-10-23T10:00:00.000002Z',
          amount: '9007199254740993.00001',
        ),
      ]) {
        final _ = await tables.createRecord(
          table: table,
          values: {
            table.labelColumnId: value.label,
            instant: value.instant,
            cost: {'currency': 'USD', 'amount': value.amount},
            quantity: 2,
          },
        );
      }
      final _ = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Missing'},
      );
      final query = QueryWorkspaceRecordsUsecase(
        LocalWorkspaceRecordQueryRepository(database, 'one'),
      );
      final temporal = await query(table.id, .new(sortColumnId: instant));
      expect(
        temporal.records
            .where((record) => record.values.containsKey(instant))
            .take(2)
            .map((record) => record.values[instant]),
        unorderedEquals([
          '2026-10-23T10:00:00Z',
          '2026-10-23T10:00:00.000000Z',
        ]),
      );
      expect(temporal.records.last.values[table.labelColumnId], 'C');
      final monetary = await query(table.id, .new(sortColumnId: cost));
      expect(monetary.records.first.values[table.labelColumnId], 'Missing');
      expect(monetary.records[1].values[table.labelColumnId], 'B');
      expect(monetary.records.last.values[table.labelColumnId], 'E');
      final descending = await query(
        table.id,
        .new(sortColumnId: cost, descending: true),
      );
      expect(descending.records.first.values[table.labelColumnId], 'E');
      expect(descending.records.last.values[table.labelColumnId], 'Missing');
      expect(
        descending.records[descending.records.length - 2].values[table
            .labelColumnId],
        'B',
      );
      final numeric = await query(
        table.id,
        .new(filterColumnId: quantity, filterValue: '2.0'),
      );
      expect(numeric.records, hasLength(5));
      final equivalentInstant = await query(
        table.id,
        .new(filterColumnId: instant, filterValue: '2026-10-23T10:00:00.0Z'),
      );
      expect(equivalentInstant.records, hasLength(2));
      final signedZero = await query(
        table.id,
        .new(
          filterColumnId: cost,
          filterValue: '{"currency":"USD","amount":"0"}',
        ),
      );
      expect(signedZero.records, hasLength(2));
      for (final invalid in [
        (column: quantity, value: 'invalid'),
        (column: instant, value: 'invalid'),
        (column: cost, value: '{'),
      ]) {
        await expectLater(
          query(
            table.id,
            .new(filterColumnId: invalid.column, filterValue: invalid.value),
          ),
          throwsA(isA<WorkspaceTableException>()),
        );
      }
      final contains = await query(
        table.id,
        .new(
          filterColumnId: table.labelColumnId,
          filterValue: 'a',
          filterOperator: .contains,
        ),
      );
      expect(contains.records.single.values[table.labelColumnId], 'A');
      await expectLater(
        query(
          table.id,
          .new(
            filterColumnId: cost,
            filterValue: '{"currency":"USD","amount":"0"}',
            filterOperator: .contains,
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      final largeAmount = '0.${'0' * 16381}1';
      final largeValue = {'currency': 'USD', 'amount': largeAmount};
      final _ = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Large', cost: largeValue},
      );
      final large = await query(
        table.id,
        .new(filterColumnId: cost, filterValue: jsonEncode(largeValue)),
      );
      expect(large.records.single.values[table.labelColumnId], 'Large');
    },
  );
}
