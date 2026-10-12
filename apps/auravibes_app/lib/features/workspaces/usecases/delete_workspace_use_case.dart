import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_draft_cleanup_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_workspace_use_case.g.dart';

class const DeleteWorkspaceUseCase({
  required final WorkspaceRepository repository,
  required final Future<void> Function(String workspaceId) clearWorkspaceDrafts,
}) {
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
    final deletedWorkspace = await repository.deleteWorkspace(id);
    if (deletedWorkspace) await clearWorkspaceDrafts(id);
    assert(deletedWorkspace, 'Workspace must be deleted.');
  }
}

/// Provides a [DeleteWorkspaceUseCase] instance.
@riverpod
DeleteWorkspaceUseCase deleteWorkspaceUseCase(Ref ref) {
  return DeleteWorkspaceUseCase(
    repository: ref.watch(workspaceRepositoryProvider),
    clearWorkspaceDrafts: ref
        .watch(conversationDraftCleanupUsecaseProvider)
        .clearWorkspace,
  );
}
