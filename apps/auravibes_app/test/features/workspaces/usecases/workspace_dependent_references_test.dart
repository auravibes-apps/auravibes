import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/preview_workspace_column_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'dependent links reject parent-only changes and accept combined updates',
    () async {
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
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'local'),
      );
      final parents = await tables.create(name: 'Groups', labelName: 'Name');
      final first = await tables.createRecord(table: parents, values: {});
      final second = await tables.createRecord(table: parents, values: {});
      var targets = await tables.create(name: 'People', labelName: 'Name');
      targets = await tables.saveColumn(
        table: targets,
        column: .new(
          id: '',
          name: 'Group',
          type: .reference,
          targetTableId: parents.id,
        ),
      );
      final targetParent = targets.columns.last.id;
      final one = await tables.createRecord(
        table: targets,
        values: {targetParent: first.id},
      );
      final two = await tables.createRecord(
        table: targets,
        values: {targetParent: second.id},
      );
      var source = await tables.create(name: 'Tasks', labelName: 'Name');
      source = await tables.saveColumn(
        table: source,
        column: .new(
          id: '',
          name: 'Group',
          type: .reference,
          targetTableId: parents.id,
        ),
      );
      final parent = source.columns.last.id;
      source = await tables.saveColumn(
        table: source,
        column: .fromJson({
          'id': '',
          'name': 'Person',
          'type': 'reference',
          'targetTableId': targets.id,
          'dependsOnColumnId': parent,
          'targetMatchColumnId': targetParent,
        }),
      );
      final dependent = source.columns.last.id;
      for (var index = 0; index < 52; index++) {
        final _ = await tables.createRecord(
          table: targets,
          values: {targetParent: second.id},
        );
      }
      final late = await tables.createRecord(
        table: targets,
        values: {targetParent: first.id, targets.labelColumnId: 'Late'},
      );

      final references = BrowseWorkspaceReferencesUsecase(
        LocalWorkspaceReferenceRepository(database, 'local'),
      );
      final page = await references.targets(
        source: (tableId: source.id, columnId: dependent),
        parentId: first.id,
      );
      expect(page.records.map((record) => record.id), [one.id, late.id]);
      final after = await references.targets(
        source: (tableId: source.id, columnId: dependent),
        parentId: first.id,
        afterId: one.id,
        search: 'Late',
      );
      expect(after.records.map((record) => record.id), [late.id]);
      expect(
        (await references.targets(
          source: (tableId: source.id, columnId: dependent),
        )).records,
        isEmpty,
      );
      final record = await tables.createRecord(
        table: source,
        values: {parent: first.id, dependent: one.id},
      );
      await expectLater(
        Future.sync(
          () => tables.updateRecord(
            table: source,
            record: record,
            values: {parent: second.id, dependent: one.id},
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await tables.record(source.id, record.id)).values[dependent],
        one.id,
      );
      final updated = await tables.updateRecord(
        table: source,
        record: record,
        values: {parent: second.id, dependent: two.id},
      );
      expect(updated.values[dependent], two.id);
      await expectLater(
        Future.sync(
          () => tables.updateRecord(
            table: source,
            record: updated,
            values: {dependent: two.id},
          ),
        ),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.incompatibleRelationship,
            'relationship',
            isTrue,
          ),
        ),
      );

      await expectLater(
        Future.sync(
          () => tables.updateRecord(
            table: targets,
            record: two,
            values: {targetParent: first.id},
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await tables.record(targets.id, two.id)).values[targetParent],
        second.id,
      );
      final cleared = await tables.updateRecord(
        table: source,
        record: updated,
        values: {},
      );
      expect(cleared.values, isEmpty);
      final parentColumn = source.columns.firstWhere(
        (column) => column.id == parent,
      );
      source = await tables.saveColumn(
        table: source,
        column: .fromJson({...parentColumn.toJson(), 'defaultValue': first.id}),
      );
      final dependentColumn = source.columns.firstWhere(
        (column) => column.id == dependent,
      );
      source = await tables.saveColumn(
        table: source,
        column: .fromJson({
          ...dependentColumn.toJson(),
          'defaultValue': one.id,
        }),
      );
      final withDefaults = await tables.createRecord(table: source, values: {});
      expect(withDefaults.values[parent], first.id);
      expect(withDefaults.values[dependent], one.id);
      await expectLater(
        Future.sync(
          () => tables.createRecord(table: source, values: {parent: second.id}),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      final explicit = await tables.createRecord(
        table: source,
        values: {parent: second.id, dependent: two.id},
      );
      expect(explicit.values[dependent], two.id);
      source = await tables.saveColumn(
        table: source,
        column: .new(
          id: '',
          name: 'Loose',
          type: .reference,
          targetTableId: targets.id,
        ),
      );
      final loose = source.columns.last;
      final incompatible = await tables.createRecord(
        table: source,
        values: {parent: first.id, loose.id: two.id},
      );
      final rule = WorkspaceColumn.fromJson({
        ...loose.toJson(),
        'dependsOnColumnId': parent,
        'targetMatchColumnId': targetParent,
      });
      final preview = await PreviewWorkspaceColumnUsecase(tables)
          .call(table: source, column: rule);
      expect(preview.map((record) => record.id), [incompatible.id]);
      await expectLater(
        Future.sync(() => tables.saveColumn(table: source, column: rule)),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await tables.record(source.id, incompatible.id)).values[loose.id],
        two.id,
      );

      await expectLater(
        Future.sync(
          () => tables.saveColumn(
            table: source,
            column: .fromJson({
              ...dependentColumn.toJson(),
              'dependsOnColumnId': dependent,
            }),
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      await expectLater(
        Future.sync(
          () => tables.updateRecord(table: source, record: record, values: {}),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
    },
  );
}
