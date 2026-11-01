import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/cloud_workspaces/models/cloud_workspace_detail_state.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_location_kind.dart';

/// Workspace location and roster visibility for the active workspace.
class const WorkspaceLocationInfo({
  /// The workspace's storage or sharing state.
  required final WorkspaceLocationKind kind,

  /// Whether the current account may view the workspace's member list.
  final bool canViewMembers = false,
}) {
  /// Determines the active workspace's location and current sharing scope.
  factory WorkspaceLocationInfo.fromWorkspace(
    WorkspaceEntity workspace, {
    CloudWorkspaceDetailState? cloudDetail,
  }) {
    if (workspace.type == WorkspaceType.local) {
      return const WorkspaceLocationInfo(kind: .onDevice);
    }
    if (cloudDetail == null) {
      return const WorkspaceLocationInfo(kind: .cloud);
    }

    final detail = cloudDetail.detail;

    return WorkspaceLocationInfo._fromCloudWorkspace(
      role: detail.workspace.role,
      memberCount: cloudDetail.members.length,
      hasPendingInvites: cloudDetail.invites.isNotEmpty,
      canViewMembers: detail.capabilities.canViewMembers,
    );
  }

  /// Classifies sharing from the server's current role, roster, and
  /// invitations.
  factory WorkspaceLocationInfo._fromCloudWorkspace({
    required String role,
    required int memberCount,
    required bool hasPendingInvites,
    required bool canViewMembers,
  }) => WorkspaceLocationInfo(
    kind: role != 'owner' || memberCount > 1 || hasPendingInvites
        ? .teamWorkspace
        : .personalCloud,
    canViewMembers: canViewMembers,
  );
}
