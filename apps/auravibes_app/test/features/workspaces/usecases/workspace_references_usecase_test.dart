import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reference IDs survive target renames and reject foreign targets',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace-references-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/references.sqlite');
      var database = AppDatabase(connection: NativeDatabase(file));
      addTearDown(() => database.close());
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
      final foreign = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'two'),
      );
      var target = await tables.create(name: 'People', labelName: 'Name');
      final person = await tables.createRecord(
        table: target,
        values: {target.labelColumnId: 'Ada'},
      );
      var source = await tables.create(name: 'Tasks', labelName: 'Title');
      source = await tables.saveColumn(
        table: source,
        column: .new(
          id: '',
          name: 'Owner',
          type: .reference,
          targetTableId: target.id,
        ),
      );
      final references = BrowseWorkspaceReferencesUsecase(
        LocalWorkspaceReferenceRepository(database, 'one'),
      );
      final link = source.columns.last.id;
      final task = await tables.createRecord(
        table: source,
        values: {link: person.id},
      );
      final options = await references.targets(
        source: (tableId: source.id, columnId: link),
        search: 'ada',
      );
      expect(options.records.map((row) => row.id), [person.id]);
      expect(options.nextId, isNull);
      final reverse = await references.reverse(
        tableId: target.id,
        recordId: person.id,
      );
      expect(reverse.records.map((row) => row.id), [task.id]);
      target = await tables.updateMetadata(
        table: target,
        name: 'Contacts',
        parentId: (await OrganizeWorkspaceFoldersUsecase(
          LocalWorkspaceFolderRepository(database, 'one'),
        ).create(name: 'Archive')).id,
      );
      expect((await tables.record(source.id, task.id)).values[link], person.id);
      final other = await foreign.create(name: 'Other', labelName: 'Name');
      final outsider = await foreign.createRecord(table: other, values: {});
      await expectLater(
        tables.updateRecord(
          table: source,
          record: task,
          values: {link: outsider.id},
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      await expectLater(
        tables.saveColumn(
          table: source,
          column: .new(
            id: '',
            name: 'Invalid',
            type: .reference,
            targetTableId: other.id,
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      source = await tables.saveColumn(
        table: source,
        column: .new(
          id: '',
          name: 'Participants',
          type: .reference,
          targetTableId: target.id,
          referenceMultiple: true,
        ),
      );
      final multi = source.columns.last.id;
      final secondPerson = await tables.createRecord(
        table: target,
        values: {target.labelColumnId: 'Grace'},
      );
      final updated = await tables.updateRecord(
        table: source,
        record: task,
        values: {
          link: person.id,
          multi: [person.id, secondPerson.id],
        },
      );
      expect(updated.values[multi], [person.id, secondPerson.id]);
      await expectLater(
        Future.sync(
          () => tables.updateRecord(
            table: source,
            record: updated,
            values: {
              multi: [person.id, person.id],
            },
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(
        (await references.reverse(
          tableId: target.id,
          recordId: person.id,
        )).records.map((row) => row.id),
        [task.id],
      );
      for (var index = 0; index < 52; index++) {
        final _ = await tables.createRecord(
          table: target,
          values: {target.labelColumnId: 'Batch $index'},
        );
      }
      final firstPage = await references.targets(
        source: (tableId: source.id, columnId: link),
        search: 'Batch',
      );
      expect(firstPage.records.length, 50);
      final defaultOptions = await references.tableTargets(
        tableId: target.id,
        search: 'Batch',
      );
      expect(
        defaultOptions.records.map((record) => record.id),
        firstPage.records.map((record) => record.id),
      );
      final lastPage = await references.targets(
        source: (tableId: source.id, columnId: link),
        search: 'Batch',
        afterId: firstPage.nextId,
      );
      expect(lastPage.records.length, 2);
      expect(lastPage.nextId, isNull);
      await database.close();
      database = AppDatabase(connection: NativeDatabase(file));
      final reopened = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'one'),
      );
      expect(
        (await reopened.record(source.id, task.id)).values[link],
        person.id,
      );
      expect(
        (await reopened.table(source.id)).columns.last.targetTableId,
        target.id,
      );
    },
  );
}
