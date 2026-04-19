import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';

/// Repository interface for workspace data operations.
///
/// This abstract class defines the contract for workspace data access,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, retrieval, and
/// business logic validation for workspace operations.
abstract class WorkspaceRepository {
  /// Retrieves all workspaces from the data source.
  ///
  /// Returns a list of all workspaces ordered by their creation date.
  /// Throws [WorkspaceException] if there's an error retrieving workspaces.
  Future<List<WorkspaceEntity>> getAllWorkspaces();

  /// Retrieves a workspace by its unique identifier.
  ///
  /// [id] The unique identifier of the workspace to retrieve.
  /// Returns the workspace with the given [id], or null if not found.
  /// Throws [WorkspaceException] if there's an error retrieving the workspace.
  Future<WorkspaceEntity?> getWorkspaceById(String id);

  /// Retrieves workspaces filtered by their type.
  ///
  /// [type] The type of workspaces to retrieve.
  /// Returns a list of workspaces with the specified [type] ordered by name.
  /// Throws [WorkspaceException] if there's an error retrieving workspaces.
  Future<List<WorkspaceEntity>> getWorkspacesByType(WorkspaceType type);

  /// Creates a new workspace in the data source.
  ///
  /// [workspace] The workspace to create. The workspace should have
  /// a unique ID.
  /// Returns the created workspace with any system-generated values populated.
  /// Throws [WorkspaceValidationException] if the workspace data is invalid.
  /// Throws [WorkspaceDuplicateException] if a workspace with the same ID
  /// already exists.
  /// Throws [WorkspaceException] if there's an error creating the workspace.
  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace);

  /// Updates an existing workspace in the data source.
  ///
  /// [id] id of workspace to update
  /// [workspace] The workspace with updated values. Must have a valid ID.
  /// Returns the updated workspace.
  /// Throws [WorkspaceValidationException] if the workspace data is invalid.
  /// Throws [WorkspaceNotFoundException] if no workspace with the
  /// given ID exists.
  /// Throws [WorkspaceException] if there's an error updating the workspace.
  Future<WorkspaceEntity> patchWorkspace(
    String id,
    WorkspacePatch workspace,
  );

  /// Deletes a workspace from the data source.
  ///
  /// [id] The unique identifier of the workspace to delete.
  /// Returns true if the workspace was successfully deleted, false
  /// if not found.
  /// Throws [WorkspaceException] if there's an error deleting the workspace.
  Future<bool> deleteWorkspace(String id);

  /// Checks if a workspace with the given ID exists.
  ///
  /// [id] The unique identifier to check.
  /// Returns true if the workspace exists, false otherwise.
  /// Throws [WorkspaceException] if there's an error checking existence.
  Future<bool> workspaceExists(String id);

  /// Searches for workspaces by name.
  ///
  /// [query] The search query string. The search is case-insensitive and
  /// matches workspaces whose names contain the query.
  /// Returns a list of matching workspaces ordered by name.
  /// Throws [WorkspaceException] if there's an error searching workspaces.
  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query);

  /// Gets the total count of all workspaces.
  ///
  /// Returns the total number of workspaces in the data source.
  /// Throws [WorkspaceException] if there's an error counting workspaces.
  Future<int> getWorkspaceCount();

  /// Gets the count of workspaces filtered by type.
  ///
  /// [type] The type of workspaces to count.
  /// Returns the number of workspaces with the specified [type].
  /// Throws [WorkspaceException] if there's an error counting workspaces.
  Future<int> getWorkspaceCountByType(WorkspaceType type);

  /// Validates workspace data before creation or update.
  ///
  /// [workspace] The workspace to validate.
  /// Returns true if the workspace data is valid.
  /// Throws [WorkspaceValidationException] if the workspace data is invalid.
  Future<bool> validateWorkspace(WorkspaceToCreate workspace);

  /// Updates the last updated timestamp for a workspace.
  ///
  /// [id] The unique identifier of the workspace to update.
  /// Returns true if the workspace was successfully updated,
  /// false if not found.
  /// Throws [WorkspaceException] if there's an error updating the timestamp.
  Future<bool> patchWorkspaceTimestamp(String id);
}

/// Base exception for workspace-related operations.
class WorkspaceException implements Exception {
  /// Creates a new WorkspaceException
  const WorkspaceException(this.message, [this.cause]);

  /// Error message describing the exception
  final String message;

  /// Optional original exception that caused this exception
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return 'WorkspaceException: $message$causedBy';
  }
}

/// Exception thrown when workspace validation fails.
class WorkspaceValidationException extends WorkspaceException {
  /// Creates a new WorkspaceValidationException
  const WorkspaceValidationException(super.message, [super.cause]);
}

/// Exception thrown when a workspace is not found.
class WorkspaceNotFoundException extends WorkspaceException {
  /// Creates a new WorkspaceNotFoundException
  const WorkspaceNotFoundException(this.workspaceId, [Exception? cause])
    : super('Workspace with ID "$workspaceId" not found', cause);

  /// ID of the workspace that was not found
  final String workspaceId;
}

/// Exception thrown when attempting to create a duplicate workspace.
class WorkspaceDuplicateException extends WorkspaceException {
  /// Creates a new WorkspaceDuplicateException
  const WorkspaceDuplicateException(this.workspaceId, [Exception? cause])
    : super('Workspace with ID "$workspaceId" already exists', cause);

  /// ID of the duplicate workspace
  final String workspaceId;
}
