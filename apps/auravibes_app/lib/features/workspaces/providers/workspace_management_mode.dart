// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/models/management_mode.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_management_mode.g.dart';

// ─── Mutation providers ───.

final editWorkspaceMutation = Mutation<WorkspaceEntity>();
final deleteWorkspaceMutation = Mutation<void>();
final cloudAccountMutation = Mutation<void>();

// ─── UI mode notifier ───.

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

  void editWorkspace(WorkspaceEntity workspace) {
    state = state.copyWith(
      mode: ManagementMode.edit,
      editingWorkspace: workspace,
    );
  }

  void clearEditing() {
    state = state.copyWith(mode: ManagementMode.list, editingWorkspace: null);
  }
}
