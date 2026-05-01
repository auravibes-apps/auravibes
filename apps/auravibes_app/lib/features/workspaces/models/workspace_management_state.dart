import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_management_state.freezed.dart';

/// UI mode for the workspace-management screen.
enum ManagementMode { list, create, edit }

/// Immutable state for workspace-management UI mode.
///
/// Does not contain workspace data (owned by the workspace list provider).
@freezed
abstract class WorkspaceManagementState with _$WorkspaceManagementState {
  const factory WorkspaceManagementState({
    @Default(ManagementMode.list) ManagementMode mode,
    WorkspaceEntity? editingWorkspace,
  }) = _WorkspaceManagementState;

  const WorkspaceManagementState._();
}
