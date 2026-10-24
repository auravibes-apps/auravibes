import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceFolderUpdates(
  final AppDatabase _database,
  final String _workspaceId,
) {
  Future<WorkspaceFolder> update(
    WorkspaceFolder folder,
    String name,
    String? parentId,
  ) => _database.transaction(() async {
    await _workspace();
    final current = await _current(folder);
    await _parent(folder.id, parentId);

    return await _write(current, name, parentId);
  });

  Future<void> _workspace() async {
    final query = _database.select(_database.workspaces)
      ..where((row) => row.id.equals(_workspaceId));
    final workspace = await query.getSingleOrNull();
    if (workspace == null || workspace.type != .local) {
      throw const WorkspaceFolderException();
    }
  }

  Future<WorkspaceFolderRow> _current(WorkspaceFolder expected) async {
    final current = await _row(expected.id);
    if (current.revision != expected.revision) {
      throw const WorkspaceFolderException(conflict: true);
    }

    return current;
  }

  Future<void> _parent(String folderId, String? parentId) async {
    final visited = {folderId};
    var id = parentId;
    while (id != null) {
      if (!visited.add(id)) throw const WorkspaceFolderException();
      id = (await _row(id)).parentId;
    }
  }

  Future<WorkspaceFolderRow> _row(String id) async {
    final query = _database.select(_database.workspaceFolders)
      ..where((row) => row.id.equals(id) & _retained(row));
    final row = await query.getSingleOrNull();
    if (row == null) throw const WorkspaceFolderException();

    return row;
  }

  Expression<bool> _retained($WorkspaceFoldersTable row) =>
      row.workspaceId.equals(_workspaceId) & row.deletedAt.isNull();

  Expression<bool> _target($WorkspaceFoldersTable row, String id) =>
      row.id.equals(id) & _retained(row);

  Future<WorkspaceFolder> _write(
    WorkspaceFolderRow current,
    String name,
    String? parentId,
  ) async {
    final query = _database.update(_database.workspaceFolders)
      ..where((row) => _target(row, current.id));
    final _ = await query.write(_changes(current, name, parentId));

    return _result(current, name, parentId);
  }
}

WorkspaceFoldersCompanion _changes(
  WorkspaceFolderRow current,
  String name,
  String? parentId,
) => WorkspaceFoldersCompanion(
  name: .new(name),
  parentId: .new(parentId),
  revision: .new(current.revision + 1),
);
WorkspaceFolder _result(
  WorkspaceFolderRow current,
  String name,
  String? parentId,
) => WorkspaceFolder(
  id: current.id,
  name: name,
  revision: current.revision + 1,
  parentId: parentId,
);
