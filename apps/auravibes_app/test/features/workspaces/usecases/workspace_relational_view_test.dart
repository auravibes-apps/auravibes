import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'saved query pages results while summaries cover all filtered rows',
    () async {
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
      final table = await tables.create(name: 'Items', labelName: 'Title');
      for (final name in ['A', 'B', 'C']) {
        final _ = await tables.createRecord(
          table: table,
          values: {table.labelColumnId: name},
        );
      }
      final views = ManageWorkspaceViewsUsecase(
        LocalWorkspaceViewRepository(database, 'workspace'),
        tables,
        .new(LocalWorkspaceRecordQueryRepository(database, 'workspace')),
        .new(LocalWorkspaceReferenceRepository(database, 'workspace')),
      );
      final view = await views.create(
        name: 'Paged',
        table: table,
        columnIds: [table.labelColumnId],
      );
      final _ = await views.save(
        view.withQuery(const WorkspaceRecordQuery(limit: 1)),
      );
      final first = await views.open(view.id);
      expect(first.records.single.values[table.labelColumnId], 'A');
      expect(first.hasMore, isTrue);
      expect(first.summary['count'], 3);
      final second = await views.open(view.id, offset: 1);
      expect(second.records.single.values[table.labelColumnId], 'B');
      expect(second.summary['count'], 3);
    },
  );
  test('summaries preserve currency and time beyond a page', () async {
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
    for (final column in [
      const WorkspaceColumn(id: '', name: 'Cost', type: .money),
      const WorkspaceColumn(id: '', name: 'Day', type: .dateOnly),
      const WorkspaceColumn(id: '', name: 'Instant', type: .timestamp),
    ]) {
      table = await tables.saveColumn(table: table, column: column);
    }
    final cost = table.columns[1].id;
    final day = table.columns[2].id;
    final instant = table.columns[3].id;
    for (var index = 0; index < 103; index++) {
      final _ = await tables.createRecord(
        table: table,
        values: {
          table.labelColumnId: 'Record $index',
          if (index == 0)
            cost: {
              'amount': '9007199254740993.000000000000000000001',
              'currency': 'USD',
            },
          if (index == 100)
            cost: {'amount': '-9007199254740993', 'currency': 'USD'},
          if (index == 101) cost: {'amount': '5.20', 'currency': 'EUR'},
          if (index == 0) day: '2026-10-23',
          if (index == 100) day: '2026-01-01',
          if (index == 0) instant: '2026-10-23T10:00:00Z',
          if (index == 100) instant: '2026-10-23T10:00:00.000001Z',
        },
      );
    }
    final views = ManageWorkspaceViewsUsecase(
      LocalWorkspaceViewRepository(database, 'workspace'),
      tables,
      .new(LocalWorkspaceRecordQueryRepository(database, 'workspace')),
      .new(LocalWorkspaceReferenceRepository(database, 'workspace')),
    );
    final initial = await views.create(
      name: 'Summary',
      table: table,
      columnIds: [table.labelColumnId],
    );
    final view = initial
        .edited(
          name: initial.name,
          definition: initial.definition,
          bindings: initial.bindings,
          columnTypes: {
            for (final column in table.columns) column.id: column.type.name,
          },
        )
        .withSummaryColumns([cost, day, instant])
        .withQuery(const WorkspaceRecordQuery(limit: 1));
    final _ = await views.save(view);
    final data = await views.open(view.id);
    expect(data.records, hasLength(1));
    expect(data.summary['count'], 103);
    final columns = data.summary['columns']! as Map;
    expect((columns[cost] as Map)['present'], 3);
    expect(
      (((columns[cost] as Map)['currencies'] as Map)['USD'] as Map)['sum'],
      '0.000000000000000000001',
    );
    expect(
      (((columns[cost] as Map)['currencies'] as Map)['EUR'] as Map)['sum'],
      '5.2',
    );
    expect((columns[day] as Map)['minimum'], '2026-01-01');
    expect((columns[instant] as Map)['maximum'], '2026-10-23T10:00:00.000001Z');
    final current = data.view;
    final _ = await views.save(
      current.withQuery(current.query.change(search: 'Record 100')),
    );
    expect((await views.open(view.id)).summary['count'], 1);
  });
}
