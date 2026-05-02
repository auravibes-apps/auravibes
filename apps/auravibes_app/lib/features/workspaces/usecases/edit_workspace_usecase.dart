import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_workspace_usecase.g.dart';

/// Edits an existing workspace name.
///
/// Orchestrates name validation and repository patch.
class EditWorkspaceUseCase {
  const EditWorkspaceUseCase({
    required WorkspaceRepository repository,
    required ValidateWorkspaceNameUseCase validateName,
  }) : _repository = repository,
       _validateName = validateName;

  final WorkspaceRepository _repository;
  final ValidateWorkspaceNameUseCase _validateName;

  /// Patches the workspace with [id] to have the new [name].
  ///
  /// Validates the name length (3–20 chars) before persisting.
  /// Returns the updated [WorkspaceEntity].
  Future<WorkspaceEntity> call({
    required String id,
    required String name,
  }) async {
    final trimmed = name.trim();
    _validateName.call(name: trimmed);

    final patch = WorkspacePatch(name: trimmed);
    return _repository.patchWorkspace(id, patch);
  }
}

/// Provides an [EditWorkspaceUseCase] instance.
@riverpod
EditWorkspaceUseCase editWorkspaceUseCase(Ref ref) {
  return EditWorkspaceUseCase(
    repository: ref.watch(workspaceRepositoryProvider),
    validateName: ref.watch(validateWorkspaceNameUseCaseProvider),
  );
}
