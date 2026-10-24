import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_directory_move_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/usecases/move_workspace_directory_items_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mixed local moves preserve content and roll back every stale item',
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
      final folders = LocalWorkspaceFolderRepository(database, 'one');
      final tables = LocalWorkspaceTableRepository(database, 'one');
      final views = LocalWorkspaceViewRepository(database, 'one');
      final destination = await folders.create(name: 'Destination');
      final folder = await folders.create(name: 'Folder');
      final table = await tables.create(name: 'Items', labelName: 'Title');
      final record = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Saved'},
      );
      final view = await views.save(
        .create(
          name: 'Overview',
          table: table,
          columnIds: [table.labelColumnId],
        ),
        requestId: 'create',
      );
      WorkspaceDirectoryMoveItem viewItem(int revision) => .new(
        key: (kind: .view, id: view.id),
        name: view.name,
        revision: revision,
        canManage: true,
      );
      final move = MoveWorkspaceDirectoryItemsUsecase(
        LocalWorkspaceDirectoryMoveRepository(database, 'one'),
      );
      final items = [
        WorkspaceDirectoryMoveItem.folder(folder),
        WorkspaceDirectoryMoveItem.table(table),
        viewItem(1),
      ];
      await expectLater(
        move([...items.take(2), viewItem(999)], destination.id),
        throwsException,
      );
      expect((await tables.table(table.id)).parentId, isNull);
      expect(
        (await folders.list()).map((item) => item.id),
        contains(folder.id),
      );
      expect((await views.read(view.id)).revision, 1);
      await move(items, destination.id);
      expect(
        (await folders.list(parentId: destination.id)).single.id,
        folder.id,
      );
      expect((await tables.table(table.id)).parentId, destination.id);
      expect(
        (await tables.record(table.id, record.id)).values[table.labelColumnId],
        'Saved',
      );
      expect((await views.read(view.id)).parentId, destination.id);
      expect((await views.read(view.id)).bindings, view.bindings);
      final original = await views.read(view.id);
      final broken = await views.save(
        original.edited(
          name: original.name,
          definition: original.definition,
          bindings: {
            for (final entry in original.bindings.entries)
              entry.key: 'missing-column',
          },
          columnTypes: original.columnTypes,
        ),
        requestId: 'break-binding',
      );
      final renameItem = WorkspaceDirectoryMoveItem(
        key: (kind: .view, id: view.id),
        name: broken.name,
        revision: broken.revision,
        canManage: true,
        metadataName: 'Renamed broken',
      );
      await move([renameItem], destination.id);
      final renamed = await views.read(view.id);
      expect(renamed.name, 'Renamed broken');
      expect(renamed.bindings, broken.bindings);
      expect(renamed.definition.toJson(), broken.definition.toJson());
      expect(renamed.columnTypes, broken.columnTypes);
      final history = (await views.history(view.id))
          .map((snapshot) => snapshot.revision)
          .toList();
      final cycle = [
        viewItem(4),
        WorkspaceDirectoryMoveItem.folder(destination),
      ];
      await expectLater(move(cycle, folder.id), throwsException);
      expect((await views.read(view.id)).revision, 4);
      expect((await views.read(view.id)).parentId, destination.id);
      expect(
        (await views.history(view.id)).map((snapshot) => snapshot.revision),
        history,
      );
    },
  );
}
