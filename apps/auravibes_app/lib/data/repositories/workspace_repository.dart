// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:drift/drift.dart';

/// Implementation of the [WorkspaceRepository] interface.
///
/// This class provides a concrete implementation of workspace data operations
/// using the Drift database. It handles the mapping between domain entities
/// and database records, and provides proper error handling using exceptions.
class WorkspaceRepository {
  WorkspaceRepository(this._database);

  /// The database instance for workspace operations.
  final AppDatabase _database;

  Future<List<WorkspaceEntity>> getAllWorkspaces() async {
    final workspaceTables = await _database.workspaceDao.getAllWorkspaces();

    return workspaceTables.map(_mapToWorkspace).toList();
  }

  Stream<List<WorkspaceEntity>> watchAllWorkspaces() {
    return _database.workspaceDao.watchAllWorkspaces().map(
      (tables) => tables.map(_mapToWorkspace).toList(),
    );
  }

  Future<WorkspaceEntity?> getWorkspaceById(String id) async {
    final workspacesTable = await _database.workspaceDao.getWorkspaceById(id);

    return workspacesTable != null ? _mapToWorkspace(workspacesTable) : null;
  }

  Future<List<WorkspaceEntity>> getWorkspacesByType(WorkspaceType type) async {
    final workspaceTables = await _database.workspaceDao.getWorkspacesByType(
      type,
    );

    return workspaceTables.map(_mapToWorkspace).toList();
  }

  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace) async {
    // Validate workspace before creating.
    if (!await validateWorkspace(workspace)) {
      throw const WorkspaceValidationException('Invalid workspace data');
    }

    final workspaceCompanion = _mapToWorkspacesCompanion(workspace);
    final createdWorkspace = await _database.workspaceDao.insertWorkspace(
      workspaceCompanion,
    );

    return _mapToWorkspace(createdWorkspace);
  }

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

  Future<bool> deleteWorkspace(String id) async {
    // Check if workspace exists.
    if (!await workspaceExists(id)) {
      return false; // Return false instead of throwing for delete operations.
    }

    // ON DELETE CASCADE at the schema level handles all related data.
    return _database.workspaceDao.deleteWorkspace(id);
  }

  Future<bool> workspaceExists(String id) async {
    return _database.workspaceDao.workspaceExists(id);
  }

  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query) async {
    final workspaceTables = await _database.workspaceDao.searchWorkspacesByName(
      query,
    );

    return workspaceTables.map(_mapToWorkspace).toList();
  }

  Future<int> getWorkspaceCount() async {
    return _database.workspaceDao.getWorkspaceCount();
  }

  Future<int> getWorkspaceCountByType(WorkspaceType type) async {
    return _database.workspaceDao.getWorkspaceCountByType(type);
  }

  Future<bool> validateWorkspace(WorkspaceToCreate workspace) async {
    if (!workspace.isValid) {
      throw WorkspaceValidationException(
        _getValidationErrorToCreate(workspace),
      );
    }

    return true;
  }

  Future<bool> patchWorkspaceTimestamp(String id) async {
    // Check if workspace exists.
    if (!await workspaceExists(id)) {
      return false; // Return false instead of throwing for patch operations.
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
      createdAt: workspacesTable.createdAt,
      updatedAt: workspacesTable.updatedAt,
      url: workspacesTable.url,
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
    final url = workspace.url;
    if (workspace.type == WorkspaceType.remote &&
        (url == null || url.isEmpty)) {
      return 'Remote workspace must have a URL';
    }

    return 'Unknown validation error';
  }
}

/// Base exception for workspace-related operations.
class WorkspaceException implements Exception {
  /// Creates a new WorkspaceException.
  const WorkspaceException(this.message, {this.localizationKey, this.cause});

  /// Error message describing the exception.
  /// Used as fallback when localization is unavailable.
  final String message;

  /// Localization key for user-facing error messages.
  final String? localizationKey;

  /// Optional original exception that caused this exception.
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';

    return 'WorkspaceException: $message$causedBy';
  }
}

/// Exception thrown when workspace validation fails.
class WorkspaceValidationException extends WorkspaceException {
  /// Creates a new WorkspaceValidationException.
  const WorkspaceValidationException(
    super.message, {
    super.localizationKey,
    super.cause,
  });
}

/// Exception thrown when a workspace is not found.
class WorkspaceNotFoundException extends WorkspaceException {
  /// Creates a new WorkspaceNotFoundException.
  const WorkspaceNotFoundException(this.workspaceId, {super.cause})
    : super(
        'Workspace with ID "$workspaceId" not found',
        localizationKey: LocaleKeys.workspace_management_error_not_found,
      );

  /// ID of the workspace that was not found.
  final String workspaceId;
}

/// Exception thrown when attempting to create a duplicate workspace.
class WorkspaceDuplicateException extends WorkspaceException {
  /// Creates a new WorkspaceDuplicateException.
  const WorkspaceDuplicateException(this.workspaceId, {super.cause})
    : super(
        'Workspace with ID "$workspaceId" already exists',
        localizationKey: LocaleKeys.workspace_management_error_duplicate,
      );

  /// ID of the duplicate workspace.
  final String workspaceId;
}

/// Exception thrown when attempting to delete the last remaining workspace.
class WorkspaceDeleteLastException extends WorkspaceException {
  /// Creates a new WorkspaceDeleteLastException.
  const WorkspaceDeleteLastException()
    : super(
        'Cannot delete the last remaining workspace.',
        localizationKey: LocaleKeys.workspace_management_delete_last_error,
      );
}

/// Exception thrown when attempting to delete the currently active workspace.
class WorkspaceDeleteActiveException extends WorkspaceException {
  /// Creates a new WorkspaceDeleteActiveException.
  const WorkspaceDeleteActiveException()
    : super(
        'Cannot delete the currently active workspace. '
        'Switch to another workspace first.',
        localizationKey: LocaleKeys.workspace_management_delete_active_error,
      );
}
