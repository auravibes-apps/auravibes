import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:drift/drift.dart';

/// Implementation of the [WorkspaceRepository] interface.
///
/// This class provides a concrete implementation of workspace data operations
/// using the Drift database. It handles the mapping between domain entities
/// and database records, and provides proper error handling using exceptions.
class WorkspaceRepositoryImpl implements WorkspaceRepository {
  WorkspaceRepositoryImpl(this._database);

  /// The database instance for workspace operations.
  final AppDatabase _database;

  @override
  Future<List<WorkspaceEntity>> getAllWorkspaces() async {
    final workspaceTables = await _database.workspaceDao.getAllWorkspaces();
    return workspaceTables.map(_mapToWorkspace).toList();
  }

  @override
  Future<WorkspaceEntity?> getWorkspaceById(String id) async {
    final workspacesTable = await _database.workspaceDao.getWorkspaceById(id);
    return workspacesTable != null ? _mapToWorkspace(workspacesTable) : null;
  }

  @override
  Future<List<WorkspaceEntity>> getWorkspacesByType(WorkspaceType type) async {
    final workspaceTables = await _database.workspaceDao.getWorkspacesByType(
      type,
    );
    return workspaceTables.map(_mapToWorkspace).toList();
  }

  @override
  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace) async {
    // Validate workspace before creating
    if (!await validateWorkspace(workspace)) {
      throw const WorkspaceValidationException('Invalid workspace data');
    }

    final workspaceCompanion = _mapToWorkspacesCompanion(workspace);
    final createdWorkspace = await _database.workspaceDao.insertWorkspace(
      workspaceCompanion,
    );

    return _mapToWorkspace(createdWorkspace);
  }

  @override
  Future<WorkspaceEntity> patchWorkspace(
    String id,
    WorkspacePatch workspace,
  ) async {
    final currentWorkspaceTable = await _database.workspaceDao.getWorkspaceById(
      id,
    );
    if (currentWorkspaceTable == null) {
      throw WorkspaceNotFoundException(id);
    }

    _validateWorkspacePatch(
      workspace,
      _mapToWorkspace(currentWorkspaceTable),
    );

    final workspaceCompanion = _mapPatchToWorkspacesCompanion(workspace);
    final updated = await _database.workspaceDao.patchWorkspace(
      id,
      workspaceCompanion,
    );

    if (!updated) {
      throw WorkspaceException('Failed to patch workspace with ID $id');
    }

    final updatedWorkspace = await _database.workspaceDao.getWorkspaceById(id);

    if (updatedWorkspace == null) {
      throw WorkspaceException(
        'Failed to retrieve updated workspace with ID $id',
      );
    }

    return _mapToWorkspace(updatedWorkspace);
  }

  @override
  Future<bool> deleteWorkspace(String id) async {
    // Check if workspace exists
    if (!await workspaceExists(id)) {
      return false; // Return false instead of throwing for delete operations
    }

    final deleted = await _database.workspaceDao.deleteWorkspace(id);
    return deleted;
  }

  @override
  Future<bool> workspaceExists(String id) async {
    return _database.workspaceDao.workspaceExists(id);
  }

  @override
  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query) async {
    final workspaceTables = await _database.workspaceDao.searchWorkspacesByName(
      query,
    );
    return workspaceTables.map(_mapToWorkspace).toList();
  }

  @override
  Future<int> getWorkspaceCount() async {
    return _database.workspaceDao.getWorkspaceCount();
  }

  @override
  Future<int> getWorkspaceCountByType(WorkspaceType type) async {
    return _database.workspaceDao.getWorkspaceCountByType(type);
  }

  @override
  Future<bool> validateWorkspace(WorkspaceToCreate workspace) async {
    if (!workspace.isValid) {
      throw WorkspaceValidationException(
        _getValidationErrorToCreate(workspace),
      );
    }
    return true;
  }

  @override
  Future<bool> patchWorkspaceTimestamp(String id) async {
    // Check if workspace exists
    if (!await workspaceExists(id)) {
      return false; // Return false instead of throwing for patch operations
    }

    return _database.workspaceDao.patchWorkspaceTimestamp(id);
  }

  /// Maps a [workspacesTable] database record to a [WorkspaceEntity]
  /// domain entity.
  ///
  /// [workspacesTable] The database record to map.
  /// Returns the corresponding [WorkspaceEntity] entity.
  WorkspaceEntity _mapToWorkspace(WorkspacesTable workspacesTable) {
    return WorkspaceEntity(
      id: workspacesTable.id,
      name: workspacesTable.name,
      type: workspacesTable.type,
      url: workspacesTable.url,
      createdAt: workspacesTable.createdAt,
      updatedAt: workspacesTable.updatedAt,
    );
  }

  /// Maps a [WorkspaceEntity] domain entity to a [WorkspacesCompanion]
  /// for database operations.
  ///
  /// [workspace] The workspace entity to map.
  /// Returns the corresponding [WorkspacesCompanion].
  WorkspacesCompanion _mapToWorkspacesCompanion(WorkspaceToCreate workspace) {
    return WorkspacesCompanion(
      name: Value(workspace.name),
      type: Value(workspace.type),
      url: Value(workspace.url),
    );
  }

  void _validateWorkspacePatch(
    WorkspacePatch workspace,
    WorkspaceEntity currentWorkspace,
  ) {
    final validationError = workspace.validationErrorFor(currentWorkspace);
    if (validationError != null) {
      throw WorkspaceValidationException(validationError);
    }
  }

  WorkspacesCompanion _mapPatchToWorkspacesCompanion(WorkspacePatch workspace) {
    return WorkspacesCompanion(
      name: Value.absentIfNull(workspace.name),
      type: Value.absentIfNull(workspace.type),
      url: Value.absentIfNull(workspace.url),
    );
  }

  /// Gets validation error message for a workspace.
  ///
  /// [workspace] The workspace to validate.
  /// Returns a string describing the validation error.
  String _getValidationErrorToCreate(WorkspaceToCreate workspace) {
    if (workspace.name.isEmpty) return 'Workspace name cannot be empty';
    if (workspace.type == WorkspaceType.local && workspace.url != null) {
      return 'Local workspace cannot have a URL';
    }
    if (workspace.type == WorkspaceType.remote &&
        (workspace.url == null || workspace.url!.isEmpty)) {
      return 'Remote workspace must have a URL';
    }
    return 'Unknown validation error';
  }
}
