import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';

/// Repository interface for workspaceModelSelection data operations.
///
/// This abstract class defines the contract for workspaceModelSelection data
/// access,
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

  Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
  watchWorkspaceModelSelections(
    WorkspaceModelSelectionFilter filter,
  );

  Future<WorkspaceModelSelectionWithConnectionEntity?>
  getWorkspaceModelSelectionById(
    String id,
  );
}
