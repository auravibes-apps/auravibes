import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_dao.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';

/// Data source for local workspace data operations.
///
/// This class provides a clean interface for local database operations
/// using the Drift database. It handles the low-level database interactions
/// and provides methods for CRUD operations on workspaces.
class WorkspaceLocalDataSource {
  WorkspaceLocalDataSource(this._database) {
    _workspaceDao = _database.workspaceDao;
  }

  /// The database instance for performing operations.
  final AppDatabase _database;

  /// The workspace DAO for database operations.
  late final WorkspaceDao _workspaceDao;

  /// Retrieves all workspaces from the local database.
  ///
  /// Returns a list of all workspace records.
  /// Throws [Exception] if the database operation fails.
  Future<List<WorkspacesTable>> getAllWorkspaces() async {
    try {
      return await _workspaceDao.getAllWorkspaces();
    } catch (e) {
      throw Exception('Failed to retrieve all workspaces: $e');
    }
  }

  /// Retrieves a workspace by its ID from the local database.
  ///
  /// [id] The unique identifier of the workspace.
  /// Returns the workspace record if found, null otherwise.
  /// Throws [Exception] if the database operation fails.
  Future<WorkspacesTable?> getWorkspaceById(String id) async {
    try {
      return await _workspaceDao.getWorkspaceById(id);
    } catch (e) {
      throw Exception('Failed to retrieve workspace with ID $id: $e');
    }
  }

  /// Retrieves workspaces by their type from the local database.
  ///
  /// [type] The type of workspaces to retrieve.
  /// Returns a list of workspace records of the specified type.
  /// Throws [Exception] if the database operation fails.
  Future<List<WorkspacesTable>> getWorkspacesByType(WorkspaceType type) async {
    try {
      return await _workspaceDao.getWorkspacesByType(type);
    } catch (e) {
      throw Exception('Failed to retrieve workspaces of type $type: $e');
    }
  }

  /// Inserts a new workspace into the local database.
  ///
  /// [workspace] The workspace data to insert.
  /// Returns the ID of the inserted workspace.
  /// Throws [Exception] if the database operation fails.
  Future<WorkspacesTable> insertWorkspace(WorkspacesCompanion workspace) async {
    try {
      return await _workspaceDao.insertWorkspace(workspace);
    } catch (e) {
      throw Exception('Failed to insert workspace: $e');
    }
  }

  /// Updates an existing workspace in the local database.
  ///
  /// [id] The ID of the workspace to update.
  /// [workspace] The updated workspace data.
  /// Returns true if the workspace was updated, false otherwise.
  /// Throws [Exception] if the database operation fails.
  Future<bool> patchWorkspace(String id, WorkspacesCompanion workspace) async {
    try {
      return await _workspaceDao.patchWorkspace(id, workspace);
    } catch (e) {
      throw Exception('Failed to update workspace with ID $id: $e');
    }
  }

  /// Deletes a workspace from the local database.
  ///
  /// [id] The ID of the workspace to delete.
  /// Returns true if the workspace was deleted, false otherwise.
  /// Throws [Exception] if the database operation fails.
  Future<bool> deleteWorkspace(String id) async {
    try {
      return await _workspaceDao.deleteWorkspace(id);
    } catch (e) {
      throw Exception('Failed to delete workspace with ID $id: $e');
    }
  }

  /// Checks if a workspace exists in the local database.
  ///
  /// [id] The ID of the workspace to check.
  /// Returns true if the workspace exists, false otherwise.
  /// Throws [Exception] if the database operation fails.
  Future<bool> workspaceExists(String id) async {
    try {
      return await _workspaceDao.workspaceExists(id);
    } catch (e) {
      throw Exception('Failed to check if workspace exists with ID $id: $e');
    }
  }

  /// Searches for workspaces by name in the local database.
  ///
  /// [query] The search query string.
  /// Returns a list of workspace records whose names contain the query.
  /// Throws [Exception] if the database operation fails.
  Future<List<WorkspacesTable>> searchWorkspacesByName(String query) async {
    try {
      return await _workspaceDao.searchWorkspacesByName(query);
    } catch (e) {
      throw Exception('Failed to search workspaces with query "$query": $e');
    }
  }

  /// Gets the total count of workspaces in the local database.
  ///
  /// Returns the number of workspaces.
  /// Throws [Exception] if the database operation fails.
  Future<int> getWorkspaceCount() async {
    try {
      return await _workspaceDao.getWorkspaceCount();
    } catch (e) {
      throw Exception('Failed to get workspace count: $e');
    }
  }

  /// Gets the count of workspaces by type in the local database.
  ///
  /// [type] The type of workspaces to count.
  /// Returns the number of workspaces of the specified type.
  /// Throws [Exception] if the database operation fails.
  Future<int> getWorkspaceCountByType(WorkspaceType type) async {
    try {
      return await _workspaceDao.getWorkspaceCountByType(type);
    } catch (e) {
      throw Exception('Failed to get workspace count for type $type: $e');
    }
  }

  /// Updates the last updated timestamp for a workspace.
  ///
  /// [id] The ID of the workspace to update.
  /// Returns true if the workspace was updated, false otherwise.
  /// Throws [Exception] if the database operation fails.
  Future<bool> patchWorkspaceTimestamp(String id) async {
    try {
      return await _workspaceDao.patchWorkspaceTimestamp(id);
    } catch (e) {
      throw Exception(
        'Failed to update timestamp for workspace with ID $id: $e',
      );
    }
  }

  /// Performs database maintenance operations.
  ///
  /// This method can be called periodically to optimize the database.
  /// Throws [Exception] if the maintenance operation fails.
  Future<void> performMaintenance() async {
    try {
      await _database.performMaintenance();
    } catch (e) {
      throw Exception('Failed to perform database maintenance: $e');
    }
  }

  /// Gets database statistics for monitoring.
  ///
  /// Returns information about the database size, row counts, etc.
  /// Throws [Exception] if the operation fails.
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      return await _database.getDatabaseStats();
    } catch (e) {
      throw Exception('Failed to get database statistics: $e');
    }
  }

  /// Closes the database connection.
  ///
  /// This should be called when the data source is no longer needed.
  /// Throws [Exception] if the close operation fails.
  Future<void> close() async {
    try {
      await _database.close();
    } catch (e) {
      throw Exception('Failed to close database connection: $e');
    }
  }
}
