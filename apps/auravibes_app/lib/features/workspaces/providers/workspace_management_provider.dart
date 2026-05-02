import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_management_state.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_management_provider.g.dart';

// ─── Mutation providers ───

final createWorkspaceMutation = Mutation<WorkspaceEntity>();
final editWorkspaceMutation = Mutation<WorkspaceEntity>();
final deleteWorkspaceMutation = Mutation<void>();

// ─── UI mode notifier ───

/// Notifier that tracks the workspace-management UI mode and
/// which workspace is currently being edited.
///
/// Does not own workspace data (that lives in the workspace list provider).
@riverpod
class WorkspaceManagementMode extends _$WorkspaceManagementMode {
  @override
  WorkspaceManagementState build() {
    return const WorkspaceManagementState();
  }

  void setMode(ManagementMode mode, {WorkspaceEntity? editingWorkspace}) {
    state = state.copyWith(mode: mode, editingWorkspace: editingWorkspace);
  }

  void clearEditing() {
    state = state.copyWith(mode: ManagementMode.list, editingWorkspace: null);
  }
}
