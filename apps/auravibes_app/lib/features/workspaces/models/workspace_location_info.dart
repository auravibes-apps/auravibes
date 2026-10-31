import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/cloud_workspaces/models/cloud_workspace_detail_state.dart';

/// Describes where an active workspace is stored and whether it is shared.
enum WorkspaceLocationKind {
  /// Stored on this device.
  onDevice,

  /// Cloud workspace with only its owner and no pending invitations.
  personalCloud,

  /// Cloud workspace with collaborators or pending invitations.
  teamWorkspace,

  /// Cloud destination while sharing details are unavailable.
  cloud,
}

/// Workspace location and roster visibility for the active workspace.
class const WorkspaceLocationInfo({
  /// The workspace's storage or sharing state.
  required final WorkspaceLocationKind kind,

  /// Whether the current account may view the workspace's member list.
  final bool canViewMembers = false,
});

/// Determines the active workspace's location and current sharing scope.
WorkspaceLocationInfo workspaceLocationInfo(
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
  return cloudWorkspaceLocationInfo(
    role: detail.workspace.role,
    memberCount: cloudDetail.members.length,
    hasPendingInvites: cloudDetail.invites.isNotEmpty,
    canViewMembers: detail.capabilities.canViewMembers,
  );
}

/// Classifies sharing from the server's current role, roster, and invitations.
WorkspaceLocationInfo cloudWorkspaceLocationInfo({
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
