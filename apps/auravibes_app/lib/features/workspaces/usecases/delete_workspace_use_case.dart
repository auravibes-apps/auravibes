import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_workspace_use_case.g.dart';

/// Deletes a workspace after enforcing business-rule guards.
///
/// Guards:
/// - Cannot delete the currently active workspace while others remain.
class DeleteWorkspaceUseCase {
  const DeleteWorkspaceUseCase({
    required this._repository,
  });

  final WorkspaceRepository _repository;

  // Null active workspace ID means there is no active workspace to protect.
  // ignore: unnecessary-nullable
  /// Deletes the workspace with [id].
  ///
  /// [activeWorkspaceId] is the ID of the currently active workspace.
  ///
  /// Throws [WorkspaceDeleteActiveException] if the workspace is active.
  Future<void> call({
    required String id,
    required String? activeWorkspaceId,
  }) async {
    final workspaceCount = await _repository.getWorkspaceCount();

    if (workspaceCount > 1 && id == activeWorkspaceId) {
      throw const WorkspaceDeleteActiveException();
    }

    final _ = await _repository.deleteWorkspace(id);
  }
}

/// Provides a [DeleteWorkspaceUseCase] instance.
@riverpod
DeleteWorkspaceUseCase deleteWorkspaceUseCase(Ref ref) {
  return DeleteWorkspaceUseCase(
    repository: ref.watch(workspaceRepositoryProvider),
  );
}
