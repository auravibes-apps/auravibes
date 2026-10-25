import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_assets.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_folders.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_updates.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

/// Existing item writers share one outer SQLite transaction.
class const LocalWorkspaceDirectoryMoveRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceDirectoryMoveRepository {
  @override
  Future<void> move(List<WorkspaceDirectoryMoveItem> items, String? parentId) =>
      database.transaction(() async {
        for (final item in items) {
          await _item(item, parentId);
        }
      });

  Future<void> _item(WorkspaceDirectoryMoveItem item, String? parentId) async {
    switch (item.key.kind) {
      case .folder:
        await _folder(item, parentId);
      case .table:
        await _table(item, parentId);
      case .file:
        await _FileMove(this).call(item, parentId);
      case .view:
        await _view(item, parentId);
    }
  }

  Future<void> _view(WorkspaceDirectoryMoveItem item, String? parentId) async {
    final _ = await LocalWorkspaceViewRepository(database, workspaceId).move(
      item.key.id,
      expectedRevision: item.revision,
      parentId: parentId,
      name: item.metadataName,
    );
  }

  Future<void> _folder(
    WorkspaceDirectoryMoveItem item,
    String? parentId,
  ) async {
    final current = await _currentFolder(item.key.id);
    final _ = await LocalWorkspaceFolderUpdates(
      database,
      workspaceId,
    ).update(_snapshot(current, item.revision), current.name, parentId);
  }

  Future<WorkspaceFolderRow> _currentFolder(String id) async {
    final query = database.select(database.workspaceFolders)
      ..where((row) => _folderScope(row, id));
    final row = await query.getSingleOrNull();
    if (row == null) throw const WorkspaceFolderException();

    return row;
  }

  Expression<bool> _folderScope(WorkspaceFolders row, String id) =>
      row.workspaceId.equals(workspaceId) &
      row.id.equals(id) &
      row.deletedAt.isNull();
  WorkspaceFolder _snapshot(WorkspaceFolderRow current, int revision) =>
      WorkspaceFolder(
        id: current.id,
        name: current.name,
        revision: revision,
        parentId: current.parentId,
      );
  Future<void> _table(WorkspaceDirectoryMoveItem item, String? parentId) async {
    final tables = LocalWorkspaceTableRepository(database, workspaceId);
    final current = await tables.table(item.key.id);
    if (current.revision != item.revision) {
      throw const WorkspaceTableException(conflict: true);
    }
    final _ = await tables.updateMetadata(
      table: current,
      name: current.name,
      parentId: parentId,
    );
  }
}

class const _FileMove(final LocalWorkspaceDirectoryMoveRepository owner) {
  AppDatabase get _database => owner.database;

  Future<void> call(WorkspaceDirectoryMoveItem item, String? parentId) async {
    final row = await _current(item);
    if (parentId != null) {
      final _ = await owner._currentFolder(parentId);
    }
    await _write(row, parentId);
  }

  Future<void> _write(WorkspaceFileRow row, String? parentId) async {
    final query = _database.update(_database.workspaceFiles)
      ..where((value) => _scope(value, row.id));
    final _ = await query.write(_changes(row, parentId));
  }

  Future<WorkspaceFileRow> _current(WorkspaceDirectoryMoveItem item) async {
    final query = _database.select(_database.workspaceFiles)
      ..where((row) => _live(row, item.key.id));
    final row = await query.getSingleOrNull();

    return _checkedFile(row, item.revision);
  }

  Expression<bool> _live(WorkspaceFiles row, String id) =>
      _scope(row, id) & row.deletedAt.isNull();

  Expression<bool> _scope(WorkspaceFiles row, String id) =>
      row.id.equals(id) & row.workspaceId.equals(owner.workspaceId);

  WorkspaceFilesCompanion _changes(WorkspaceFileRow row, String? parentId) =>
      WorkspaceFilesCompanion(
        updatedAt: .new(DateTime.now()),
        parentId: .new(parentId),
        revision: .new(row.revision + 1),
      );
}

WorkspaceFileRow _checkedFile(WorkspaceFileRow? row, int revision) {
  if (row == null) throw const WorkspaceTableException(denied: true);
  if (row.revision != revision) {
    throw const WorkspaceTableException(conflict: true);
  }

  return row;
}
