import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_updates.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

class const LocalWorkspaceFolderRepository(
  final AppDatabase _database,
  final String _workspaceId,
) implements WorkspaceFolderRepository {
  @override
  Future<List<WorkspaceFolder>> list({String? parentId}) async {
    final query = _database.select(_database.workspaceFolders)
      ..where((row) => _inParent(row, parentId))
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);

    return (await query.get()).map(_folder).toList();
  }

  @override
  Future<WorkspaceFolder> create({required String name, String? parentId}) =>
      _database.transaction(() async {
        await _validateWorkspace();
        await _validateParent(parentId);

        return await _insert(name, parentId);
      });

  @override
  Future<WorkspaceFolder> updateMetadata({
    required WorkspaceFolder folder,
    required String name,
    required String? parentId,
  }) => LocalWorkspaceFolderUpdates(
    _database,
    _workspaceId,
  ).update(folder, name, parentId);

  Expression<bool> _retainedFolder($WorkspaceFoldersTable row) =>
      row.workspaceId.equals(_workspaceId) & row.deletedAt.isNull();

  Expression<bool> _inParent($WorkspaceFoldersTable row, String? parentId) =>
      _retainedFolder(row) &
      (parentId == null
          ? row.parentId.isNull()
          : row.parentId.equals(parentId));

  WorkspaceFolder _folder(WorkspaceFolderRow row) => WorkspaceFolder(
    id: row.id,
    name: row.name,
    revision: row.revision,
    parentId: row.parentId,
  );

  Future<void> _validateWorkspace() async {
    final query = _database.select(_database.workspaces)
      ..where((row) => row.id.equals(_workspaceId));
    final workspace = await query.getSingleOrNull();
    if (workspace == null || workspace.type != .local) {
      throw const WorkspaceFolderException();
    }
  }

  Future<void> _validateParent(String? parentId) async {
    if (parentId == null) return;
    final query = _database.select(_database.workspaceFolders)
      ..where((row) => row.id.equals(parentId) & _retainedFolder(row));
    if (await query.getSingleOrNull() == null) {
      throw const WorkspaceFolderException();
    }
  }

  Future<WorkspaceFolder> _insert(String name, String? parentId) async {
    final row = WorkspaceFoldersCompanion.insert(
      id: .new(const UuidV7().generate()),
      workspaceId: _workspaceId,
      name: name,
      parentId: .new(parentId),
    );
    final saved = await _database
        .into(_database.workspaceFolders)
        .insertReturning(row);

    return _folder(saved);
  }
}
