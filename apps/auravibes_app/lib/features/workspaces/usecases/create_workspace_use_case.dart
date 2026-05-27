// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_workspace_use_case.g.dart';

/// Creates a new workspace with validated name.
///
/// Orchestrates name validation and repository creation.
class CreateWorkspaceUseCase {
  const CreateWorkspaceUseCase({
    required this._repository,
    required this._validateName,
  });

  final WorkspaceRepository _repository;
  final ValidateWorkspaceNameUseCase _validateName;

  /// Creates a workspace with the given [name].
  ///
  /// Validates the name length (3–20 chars) before persisting.
  /// Returns the created [WorkspaceEntity].
  Future<WorkspaceEntity> call({required String name}) {
    final trimmed = name.trim();
    _validateName.call(name: trimmed);

    final workspace = WorkspaceToCreate(
      name: trimmed,
      type: WorkspaceType.local,
    );
    return _repository.createWorkspace(workspace);
  }
}

/// Provides a [CreateWorkspaceUseCase] instance.
@riverpod
CreateWorkspaceUseCase createWorkspaceUseCase(Ref ref) {
  return CreateWorkspaceUseCase(
    repository: ref.watch(workspaceRepositoryProvider),
    validateName: ref.watch(validateWorkspaceNameUseCaseProvider),
  );
}
