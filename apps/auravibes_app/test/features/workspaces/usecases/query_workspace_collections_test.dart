import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/query_workspace_records_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'selected collection members filter before bounded pagination',
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
      final target = await tables.create(name: 'Targets', labelName: 'Title');
      final selected = await tables.createRecord(
        table: target,
        values: {target.labelColumnId: 'Selected'},
      );
      var source = await tables.create(name: 'Source', labelName: 'Title');
      for (final column in [
        WorkspaceColumn(
          id: '',
          name: 'Link',
          type: .reference,
          targetTableId: target.id,
        ),
        WorkspaceColumn(
          id: '',
          name: 'Links',
          type: .reference,
          targetTableId: target.id,
          referenceMultiple: true,
        ),
        const WorkspaceColumn(
          id: '',
          name: 'Tags',
          type: .multiSelect,
          options: ['One', 'Two'],
        ),
      ]) {
        source = await tables.saveColumn(table: source, column: column);
      }
      final link = source.columns[1].id;
      final links = source.columns[2].id;
      final tags = source.columns[3].id;
      for (var index = 0; index < 55; index++) {
        final _ = await tables.createRecord(
          table: source,
          values: {
            source.labelColumnId: 'A $index',
            tags: ['One'],
          },
        );
      }
      final matching = await tables.createRecord(
        table: source,
        values: {
          source.labelColumnId: 'Zulu',
          link: selected.id,
          links: [selected.id],
          tags: ['One', 'Two'],
        },
      );
      final query = QueryWorkspaceRecordsUsecase(
        LocalWorkspaceRecordQueryRepository(database, 'one'),
      );
      for (final column in [link, links]) {
        final page = await query(
          source.id,
          .new(filterColumnId: column, filterValue: selected.id, limit: 1),
        );
        expect(page.records.single.id, matching.id);
        expect(page.hasMore, isFalse);
        await expectLater(
          query(
            source.id,
            .new(filterColumnId: column, filterValue: matching.id, limit: 1),
          ),
          throwsA(isA<WorkspaceTableException>()),
        );
      }
      final page = await query(
        source.id,
        .new(
          filterColumnId: tags,
          filterValue: 'Two',
          filterOperator: .contains,
          limit: 1,
        ),
      );
      expect(page.records.single.id, matching.id);
      expect(page.hasMore, isFalse);
      await expectLater(
        query(
          source.id,
          .new(
            filterColumnId: tags,
            filterValue: 'Unknown',
            filterOperator: .contains,
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );
}
