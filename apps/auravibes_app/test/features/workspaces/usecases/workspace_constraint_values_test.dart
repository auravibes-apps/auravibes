import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/preview_workspace_column_usecase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'legacy required columns allow empty and multiple null unique values',
    () {
      const column = WorkspaceColumn(
        id: 'name',
        name: 'Name',
        isRequired: true,
        isUnique: true,
      );
      expect(WorkspaceColumnValidation.accepts([column], const {}), isTrue);
      expect(
        WorkspaceColumnValidation.accepts([column], const {'name': null}),
        isTrue,
      );
      expect(column.toJson()['required'], isFalse);
      expect(
        WorkspaceColumn.fromJson({...column.toJson(), 'required': true})
            .isRequired,
        isFalse,
      );
      expect(
        () => WorkspaceTableConstraints.records(
          [column],
          const [
            WorkspaceRecord(
              id: 'a',
              tableId: 't',
              values: {'name': null},
              revision: 1,
            ),
            WorkspaceRecord(
              id: 'b',
              tableId: 't',
              values: {'name': null},
              revision: 1,
            ),
          ],
        ),
        returnsNormally,
      );
    },
  );
  test('explicit nulls override defaults for repeated empty rows', () async {
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
    final target = await tables.create(name: 'Target', labelName: 'Title');
    var table = await tables.create(name: 'Source', labelName: 'Title');
    table = await tables.saveColumn(
      table: table,
      column: .new(
        id: table.labelColumnId,
        name: 'Title',
        isRequired: true,
        defaultValue: 'default',
      ),
    );
    table = await tables.saveColumn(
      table: table,
      column: const WorkspaceColumn(
        id: '',
        name: 'Count',
        type: .number,
        isUnique: true,
        defaultValue: 5,
      ),
    );
    table = await tables.saveColumn(
      table: table,
      column: const WorkspaceColumn(
        id: '',
        name: 'Checked',
        type: .checkbox,
        defaultValue: true,
      ),
    );
    table = await tables.saveColumn(
      table: table,
      column: .new(
        id: '',
        name: 'Link',
        type: .reference,
        targetTableId: target.id,
      ),
    );
    final values = {for (final column in table.columns) column.id: null};
    final first = await tables.createRecord(table: table, values: values);
    final second = await tables.createRecord(table: table, values: values);
    expect(first.values, values);
    expect(second.values, values);
    expect(table.columns.every((column) => !column.isRequired), isTrue);
  });
  test(
    'instant and exact money constraints preserve stored representations',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('exact'),
              name: 'Exact',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'exact'),
      );
      var table = await tables.create(name: 'Values', labelName: 'Title');
      table = await tables.saveColumn(
        table: table,
        column: .new(id: table.labelColumnId, name: 'Title', isUnique: true),
      );
      table = await tables.saveColumn(
        table: table,
        column: const WorkspaceColumn(
          id: '',
          name: 'Start',
          type: .timestamp,
          timeZone: 'America/New_York',
        ),
      );
      final timestampId = table.columns.last.id;
      table = await tables.saveColumn(
        table: table,
        column: const WorkspaceColumn(
          id: '',
          name: 'Amount',
          type: .money,
          isUnique: true,
        ),
      );
      final moneyId = table.columns.last.id;
      Map<String, Object?> values(
        String label,
        String timestamp,
        String amount,
        String currency,
      ) => {
        table.labelColumnId: label,
        timestampId: timestamp,
        moneyId: {'amount': amount, 'currency': currency},
      };
      final first = await tables.createRecord(
        table: table,
        values: values(
          '2026-01-01T00:00:00Z',
          '2026-01-01T00:00:00Z',
          '1.00',
          'USD',
        ),
      );
      final second = await tables.createRecord(
        table: table,
        values: values(
          '2026-01-01T00:00:00.000Z',
          '2026-01-01T00:00:00.000Z',
          '2.00',
          'USD',
        ),
      );
      final unique = WorkspaceColumn(
        id: timestampId,
        name: 'Start',
        type: .timestamp,
        isUnique: true,
        timeZone: 'America/New_York',
      );
      expect(
        (await PreviewWorkspaceColumnUsecase(
          tables,
        ).call(table: table, column: unique)).length,
        2,
      );
      await expectLater(
        tables.saveColumn(table: table, column: unique),
        throwsA(isA<WorkspaceTableException>()),
      );
      final _ = await tables.updateRecord(
        table: table,
        record: second,
        values: values(
          '2026-01-01T00:00:00.000Z',
          '2026-01-01T00:00:00.000001Z',
          '2.00',
          'USD',
        ),
      );
      table = await tables.saveColumn(table: table, column: unique);
      await expectLater(
        tables.createRecord(
          table: table,
          values: values('Third', '2026-01-01T00:00:00.000Z', '3.00', 'USD'),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      await expectLater(
        tables.createRecord(
          table: table,
          values: values('Third', '2026-01-01T00:00:00.000002Z', '1', 'USD'),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      final _ = await tables.createRecord(
        table: table,
        values: values('Third', '2026-01-01T00:00:00.000002Z', '1.000', 'EUR'),
      );
      final zero = await tables.createRecord(
        table: table,
        values: values('Fourth', '2026-01-01T00:00:00.000003Z', '-0.00', 'USD'),
      );
      await expectLater(
        tables.createRecord(
          table: table,
          values: values('Fifth', '2026-01-01T00:00:00.000004Z', '0', 'USD'),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await tables.record(table.id, first.id)).values,
        values('2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z', '1.00', 'USD'),
      );
      expect(
        (await tables.record(table.id, second.id)).values[table.labelColumnId],
        '2026-01-01T00:00:00.000Z',
      );
      expect(zero.values[moneyId], {'amount': '-0.00', 'currency': 'USD'});
      expect(
        (await tables.table(table.id)).columns
            .firstWhere((column) => column.id == timestampId)
            .timeZone,
        'America/New_York',
      );
      expect(await tables.records(table.id), hasLength(4));
    },
  );
}
