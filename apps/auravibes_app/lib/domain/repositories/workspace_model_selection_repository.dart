import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';

/// Repository interface for workspaceModelSelection data operations.
///
/// This abstract class defines the contract for workspaceModelSelection data access,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, retrieval, and
/// business logic validation for workspaceModelSelection operations.
abstract class WorkspaceModelSelectionRepository {
  Future<void> createWorkspaceModelSelections(
    List<WorkspaceModelSelectionToCreate> workspaceModelSelections,
  );

  Future<List<WorkspaceModelSelectionWithConnectionEntity>>
  getWorkspaceModelSelections(
    WorkspaceModelSelectionFilter filter,
  );

  Future<WorkspaceModelSelectionWithConnectionEntity?>
  getWorkspaceModelSelectionById(
    String id,
  );
}

/// Base exception for workspaceModelSelection-related operations.
class WorkspaceModelSelectionException implements Exception {
  /// Creates a new WorkspaceModelSelectionException
  const WorkspaceModelSelectionException(this.message, [this.cause]);

  /// Error message describing the exception
  final String message;

  /// Optional original exception that caused this exception
  final Exception? cause;

  @override
  String toString() {
    final causedBy = ' (Caused by: $cause)';
    return 'WorkspaceModelSelectionException: $message'
        '${cause != null ? causedBy : ''}';
  }
}

/// Exception thrown when workspaceModelSelection validation fails.
class WorkspaceModelSelectionValidationException
    extends WorkspaceModelSelectionException {
  /// Creates a new WorkspaceModelSelectionValidationException
  const WorkspaceModelSelectionValidationException(
    super.message, [
    super.cause,
  ]);
}

/// Exception thrown when a workspaceModelSelection is not found.
class WorkspaceModelSelectionNotFoundException
    extends WorkspaceModelSelectionException {
  /// Creates a new WorkspaceModelSelectionNotFoundException
  const WorkspaceModelSelectionNotFoundException(
    this.workspaceModelSelectionId, [
    Exception? cause,
  ]) : super(
         'WorkspaceModelSelection with ID "$workspaceModelSelectionId" not found',
         cause,
       );

  /// ID of the workspaceModelSelection that was not found
  final String workspaceModelSelectionId;
}
