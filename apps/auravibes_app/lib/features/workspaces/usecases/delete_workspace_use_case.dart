import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/chats/providers/background_work_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_draft_cleanup_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_workspace_use_case.g.dart';

class DeleteWorkspaceUseCase {
  const new({
    required this._repository,
    required this._prepareBackgroundWorkDeletion,
    required this._restoreBackgroundWorkAfterFailedDeletion,
    required this._clearWorkspaceDrafts,
    required this._cleanupDeletedAssets,
  });

  final WorkspaceRepository _repository;
  final Future<void> Function(String workspaceId)
  _prepareBackgroundWorkDeletion;
  final void Function(String workspaceId)
  _restoreBackgroundWorkAfterFailedDeletion;
  final Future<void> Function(String workspaceId) _clearWorkspaceDrafts;
  final Future<void> Function() _cleanupDeletedAssets;

  // Null active workspace ID means there is no active workspace to protect.
  // ignore: unnecessary-nullable
  /// Deletes the workspace with [id].
  ///
  /// [activeWorkspaceId] is the ID of the currently active workspace.
  ///
  Future<void> call({
    required String id,
    required String? activeWorkspaceId,
  }) async {
    assert(
      activeWorkspaceId == null || activeWorkspaceId.isNotEmpty,
      'Active workspace ID must be null or non-empty.',
    );
    final bool deletedWorkspace;
    try {
      await _prepareBackgroundWorkDeletion(id);
      deletedWorkspace = await _repository.deleteWorkspace(id);
    } on Object {
      _restoreBackgroundWorkAfterFailedDeletion(id);
      rethrow;
    }
    if (!deletedWorkspace) {
      _restoreBackgroundWorkAfterFailedDeletion(id);
    }
    if (deletedWorkspace) {
      await _clearWorkspaceDrafts(id);
      await _cleanupDeletedAssets();
    }
    assert(deletedWorkspace, 'Workspace must be deleted.');
  }
}

/// Provides a [DeleteWorkspaceUseCase] instance.
@riverpod
DeleteWorkspaceUseCase deleteWorkspaceUseCase(Ref ref) {
  final backgroundWorkCoordinator = ref.watch(
    backgroundWorkCoordinatorProvider,
  );

  return DeleteWorkspaceUseCase(
    repository: ref.watch(workspaceRepositoryProvider),
    prepareBackgroundWorkDeletion:
        backgroundWorkCoordinator.prepareWorkspaceDeletion,
    restoreBackgroundWorkAfterFailedDeletion:
        backgroundWorkCoordinator.restoreWorkspaceAfterFailedDeletion,
    clearWorkspaceDrafts: ref
        .watch(conversationDraftCleanupUsecaseProvider)
        .clearWorkspace,
    cleanupDeletedAssets: ref.watch(workspaceAssetErasureProvider).flush,
  );
}
