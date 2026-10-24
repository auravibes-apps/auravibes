import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'folder recovery restores its batch, preserving earlier trash and links',
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
      final folders = OrganizeWorkspaceFoldersUsecase(
        LocalWorkspaceFolderRepository(database, 'local'),
      );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'local'),
      );
      final trash = ManageWorkspaceTrashUsecase(
        LocalWorkspaceTrashRepository(database, 'local'),
      );
      final folder = await folders.create(name: 'Folder');
      final child = await folders.create(name: 'Child', parentId: folder.id);
      final table = await tables.create(
        name: 'Inside',
        labelName: 'Name',
        parentId: child.id,
      );
      final earlier = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Earlier'},
      );
      final retained = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Retained'},
      );
      var outside = await tables.create(name: 'Outside', labelName: 'Name');
      outside = await tables.saveColumn(
        table: outside,
        column: .new(
          id: '',
          name: 'Link',
          type: .reference,
          targetTableId: table.id,
        ),
      );
      final link = await tables.createRecord(
        table: outside,
        values: {outside.columns.last.id: retained.id},
      );
      final _ = await _trash(
        trash,
        .new(
          kind: .record,
          id: earlier.id,
          revision: earlier.revision,
          tableId: table.id,
        ),
      );
      final batch = await _trash(
        trash,
        .new(kind: .folder, id: folder.id, revision: folder.revision),
      );
      expect(await folders.list(), isEmpty);
      final deleted = await trash.deletedReference(table.id, retained.id);
      expect(deleted?.batchId, batch.id);
      expect(deleted?.canRestore, isTrue);
      expect(
        (await tables.record(
          outside.id,
          link.id,
        )).values[outside.columns.last.id],
        retained.id,
      );
      final _ = await tables.updateRecord(
        table: outside,
        record: link,
        values: {
          outside.columns.last.id: retained.id,
          outside.labelColumnId: 'Renamed while target trashed',
        },
      );
      await expectLater(
        tables.createRecord(
          table: outside,
          values: {outside.columns.last.id: retained.id},
        ),
        throwsA(isA<WorkspaceTableException>()),
      );
      final _ = await trash.restore(batch.id);
      expect((await folders.list()).single.id, folder.id);
      expect((await folders.list(parentId: folder.id)).single.id, child.id);
      expect((await tables.records(table.id)).map((row) => row.id), [
        retained.id,
      ]);
      expect(
        (await tables.record(
          outside.id,
          link.id,
        )).values[outside.columns.last.id],
        retained.id,
      );
      expect((await trash.list()).single.target.id, earlier.id);
    },
  );
  test(
    'restoring a child falls back to root while its parent stays trashed',
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
      final folders = OrganizeWorkspaceFoldersUsecase(
        LocalWorkspaceFolderRepository(database, 'local'),
      );
      final trash = ManageWorkspaceTrashUsecase(
        LocalWorkspaceTrashRepository(database, 'local'),
      );
      final parent = await folders.create(name: 'Parent');
      final child = await folders.create(name: 'Child', parentId: parent.id);
      final childBatch = await _trash(
        trash,
        .new(kind: .folder, id: child.id, revision: child.revision),
      );
      final parentBatch = await _trash(
        trash,
        .new(kind: .folder, id: parent.id, revision: parent.revision),
      );
      final restored = await trash.restore(childBatch.id);
      expect(restored.movedToRoot, isTrue);
      expect((await folders.list()).single.id, child.id);
      final _ = await trash.restore(parentBatch.id);
      expect((await folders.list()).map((row) => row.id).toSet(), {
        parent.id,
        child.id,
      });
      expect(await folders.list(parentId: parent.id), isEmpty);
    },
  );

  test(
    'stale trash and invalid recovery leave the entire batch unchanged',
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
      final trash = ManageWorkspaceTrashUsecase(
        LocalWorkspaceTrashRepository(database, 'local'),
      );
      var table = await tables.create(name: 'Table', labelName: 'Name');
      final original = table;
      table = await tables.saveColumn(
        table: table,
        column: .new(id: table.labelColumnId, name: 'Name', isUnique: true),
      );
      await expectLater(
        _trash(
          trash,
          .new(kind: .table, id: original.id, revision: original.revision),
        ),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.conflict,
            'conflict',
            true,
          ),
        ),
      );
      expect(await trash.list(), isEmpty);
      final record = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Name'},
      );
      final batch = await _trash(
        trash,
        .new(
          kind: .record,
          id: record.id,
          tableId: table.id,
          revision: record.revision,
        ),
      );
      final replacement = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Name'},
      );
      await expectLater(
        trash.restore(batch.id),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect((await tables.records(table.id)).single.id, replacement.id);
      expect((await trash.list()).single.id, batch.id);
    },
  );
  test('approval binds descendants and allow all skips asking', () async {
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
    final folders = OrganizeWorkspaceFoldersUsecase(
      LocalWorkspaceFolderRepository(database, 'local'),
    );
    final trash = ManageWorkspaceTrashUsecase(
      LocalWorkspaceTrashRepository(database, 'local'),
    );
    final folder = await folders.create(name: 'Folder');
    final cancelled = await trash.apply(
      .new(kind: .folder, id: folder.id, revision: folder.revision),
      approve: (_) async => false,
    );
    expect(cancelled, isNull);
    expect((await folders.list()).single.id, folder.id);
    await expectLater(
      trash.apply(
        .new(kind: .folder, id: folder.id, revision: folder.revision),
        approve: (plan) async {
          expect(plan.affectedCount, 1);
          final _ = await folders.create(
            name: 'Added after preview',
            parentId: folder.id,
          );

          return true;
        },
      ),
      throwsA(
        isA<WorkspaceTableException>().having(
          (error) => error.conflict,
          'conflict',
          true,
        ),
      ),
    );
    expect(await trash.list(), isEmpty);
    var asked = false;
    final result = await trash.apply(
      .new(kind: .folder, id: folder.id, revision: folder.revision),
      mode: .allowAll,
      approve: (_) async {
        asked = true;

        return true;
      },
    );
    expect(asked, isFalse);
    expect(result?.affectedCount, 2);
  });
}

Future<WorkspaceTrashBatch> _trash(
  ManageWorkspaceTrashUsecase usecase,
  WorkspaceTrashTarget target,
) async =>
    await usecase.apply(target, approve: (_) async => true) ??
    (throw StateError('Expected approved trash'));
