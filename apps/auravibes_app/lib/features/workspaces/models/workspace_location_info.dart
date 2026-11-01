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
  factory fromWorkspace(
    WorkspaceEntity workspace, {
    CloudWorkspaceDetailState? cloudDetail,
  }) {
    if (workspace.type.isLocal) {
      return const WorkspaceLocationInfo(kind: .onDevice);
    }
    if (cloudDetail == null) {
      return const WorkspaceLocationInfo(kind: .cloud);
    }

    return WorkspaceLocationInfo._fromCloudWorkspace(cloudDetail: cloudDetail);
  }

  /// Returns the localization key for this workspace's location label.
  String labelKey() => switch (kind) {
    .onDevice => 'workspace_location.on_device',
    .personalCloud => 'workspace_location.personal_cloud',
    .teamWorkspace => 'workspace_location.team_workspace',
    .cloud => 'workspace_location.cloud_workspace',
  };

  /// Classifies sharing from the server's current role, roster, and
  /// invitations.
  factory _fromCloudWorkspace({
    required CloudWorkspaceDetailState cloudDetail,
  }) {
    final detail = cloudDetail.detail;

    return WorkspaceLocationInfo(
      kind:
          detail.workspace.role != 'owner' ||
              cloudDetail.members.length > 1 ||
              cloudDetail.invites.isNotEmpty
          ? .teamWorkspace
          : .personalCloud,
      canViewMembers: detail.capabilities.canViewMembers,
    );
  }
}
