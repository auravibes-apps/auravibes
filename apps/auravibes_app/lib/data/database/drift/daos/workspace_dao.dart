import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces_table.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart';

part 'workspace_dao.g.dart';

/// Data Access Object for workspace operations.
@DriftAccessor(tables: [Workspaces])
class WorkspaceDao extends DatabaseAccessor<AppDatabase>
    with _$WorkspaceDaoMixin {
  /// Creates a new [WorkspaceDao] instance.
  WorkspaceDao(super.attachedDatabase);

  /// Retrieves all workspaces from the database.
  ///
  /// Returns a list of all workspaces ordered by their creation date.
  Future<List<WorkspacesTable>> getAllWorkspaces() {
    return (select(
      workspaces,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
  }

  /// Retrieves a workspace by its ID.
  ///
  /// Returns the workspace with the given [id], or null if not found.
  Future<WorkspacesTable?> getWorkspaceById(String id) {
    return (select(
      workspaces,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Retrieves workspaces by their type.
  ///
  /// Returns a list of workspaces with the specified [type].
  Future<List<WorkspacesTable>> getWorkspacesByType(WorkspaceType type) {
    return (select(workspaces)
          ..where((t) => t.type.equals(type.value))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  /// Inserts a new workspace into the database.
  ///
  /// Returns the ID of the inserted workspace.
  Future<WorkspacesTable> insertWorkspace(WorkspacesCompanion workspace) {
    return into(workspaces).insertReturning(workspace);
  }

  /// Patches an existing workspace in the database.
  ///
  /// Updates the workspace with the given [id]
  /// using the provided [workspace] data.
  /// Returns true if a workspace was patched, false otherwise.
  Future<bool> patchWorkspace(String id, WorkspacesCompanion workspace) async {
    final updateCount = await (update(
      workspaces,
    )..where((t) => t.id.equals(id))).write(workspace);
    return updateCount > 0;
  }

  /// Deletes a workspace from the database.
  ///
  /// Deletes the workspace with the given [id].
  /// Returns true if a workspace was deleted, false otherwise.
  Future<bool> deleteWorkspace(String id) async {
    final deleteCount = await (delete(
      workspaces,
    )..where((t) => t.id.equals(id))).go();
    return deleteCount > 0;
  }

  /// Checks if a workspace with the given [id] exists.
  ///
  /// Returns true if the workspace exists, false otherwise.
  Future<bool> workspaceExists(String id) async {
    final count =
        await (selectOnly(workspaces)
              ..addColumns([workspaces.id])
              ..where(workspaces.id.equals(id)))
            .get()
            .then((rows) => rows.length);
    return count > 0;
  }

  /// Searches for workspaces by name.
  ///
  /// Returns a list of workspaces whose names contain the [query] string.
  /// The search is case-insensitive.
  Future<List<WorkspacesTable>> searchWorkspacesByName(String query) {
    return (select(workspaces)
          ..where((t) => t.name.contains(query))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  /// Gets the count of all workspaces.
  ///
  /// Returns the total number of workspaces in the database.
  Future<int> getWorkspaceCount() {
    return (selectOnly(
      workspaces,
    )..addColumns([workspaces.id])).get().then((rows) => rows.length);
  }

  /// Gets the count of workspaces by type.
  ///
  /// Returns the number of workspaces with the specified [type].
  Future<int> getWorkspaceCountByType(WorkspaceType type) {
    return (selectOnly(workspaces)
          ..addColumns([workspaces.id])
          ..where(workspaces.type.equals(type.value)))
        .get()
        .then((rows) => rows.length);
  }

  Future<bool> patchWorkspaceTimestamp(String id) async {
    final rowsAffected =
        await (update(workspaces)..where((t) => t.id.equals(id))).write(
          WorkspacesCompanion(updatedAt: Value(DateTime.now())),
        );
    return rowsAffected > 0;
  }
}
