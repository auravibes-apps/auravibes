import 'package:auravibes_app/data/database/drift/app_database.dart';
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
      ..where(
        (row) =>
            row.workspaceId.equals(_workspaceId) &
            row.deletedAt.isNull() &
            (parentId == null
                ? row.parentId.isNull()
                : row.parentId.equals(parentId)),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);

    return (await query.get())
        .map(
          (row) => WorkspaceFolder(
            id: row.id,
            name: row.name,
            revision: row.revision,
            parentId: row.parentId,
          ),
        )
        .toList();
  }

  @override
  Future<WorkspaceFolder> create({required String name, String? parentId}) =>
      _database.transaction(() async {
        final workspace = await (_database.select(
          _database.workspaces,
        )..where((row) => row.id.equals(_workspaceId))).getSingleOrNull();
        if (workspace == null || workspace.type != .local) {
          throw const WorkspaceFolderException();
        }
        if (parentId != null) {
          final parent =
              await (_database.select(_database.workspaceFolders)..where(
                    (row) =>
                        row.id.equals(parentId) &
                        row.workspaceId.equals(_workspaceId) &
                        row.deletedAt.isNull(),
                  ))
                  .getSingleOrNull();
          if (parent == null) throw const WorkspaceFolderException();
        }
        final id = const UuidV7().generate();
        final _ = await _database
            .into(_database.workspaceFolders)
            .insert(
              WorkspaceFoldersCompanion.insert(
                id: .new(id),
                workspaceId: _workspaceId,
                name: name,
                parentId: .new(parentId),
              ),
            );

        return WorkspaceFolder(
          id: id,
          name: name,
          revision: 1,
          parentId: parentId,
        );
      });
}
