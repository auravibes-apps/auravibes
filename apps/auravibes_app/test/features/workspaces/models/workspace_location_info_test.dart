import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/cloud_workspaces/models/cloud_workspace_detail_state.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_location_info.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local workspace is stored on this device', () {
    final info = workspaceLocationInfo(_workspace(WorkspaceType.local));

    expect(info.kind, WorkspaceLocationKind.onDevice);
  });

  test('owner-only cloud workspace is personal', () {
    final info = workspaceLocationInfo(
      _workspace(WorkspaceType.remote),
      cloudDetail: _cloudDetail(role: 'owner', members: [_member('owner')]),
    );

    expect(info.kind, WorkspaceLocationKind.personalCloud);
    expect(info.canViewMembers, isTrue);
  });

  test('cloud workspace with another member is a team workspace', () {
    final info = workspaceLocationInfo(
      _workspace(WorkspaceType.remote),
      cloudDetail: _cloudDetail(
        role: 'owner',
        members: [
          _member('owner'),
          _member('member', role: 'member'),
        ],
      ),
    );

    expect(info.kind, WorkspaceLocationKind.teamWorkspace);
  });

  test('pending invites make an owner cloud workspace a team workspace', () {
    final info = workspaceLocationInfo(
      _workspace(WorkspaceType.remote),
      cloudDetail: _cloudDetail(
        role: 'owner',
        members: [_member('owner')],
        invites: [_invite()],
      ),
    );

    expect(info.kind, WorkspaceLocationKind.teamWorkspace);
  });

  test('member role shows team even when roster access is unavailable', () {
    final info = workspaceLocationInfo(
      _workspace(WorkspaceType.remote),
      cloudDetail: _cloudDetail(role: 'member', canViewMembers: false),
    );

    expect(info.kind, WorkspaceLocationKind.teamWorkspace);
    expect(info.canViewMembers, isFalse);
  });
}

WorkspaceEntity _workspace(WorkspaceType type) => WorkspaceEntity(
  id: 'workspace-1',
  name: 'Workspace',
  type: type,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

CloudWorkspaceDetailState _cloudDetail({
  required String role,
  List<CloudWorkspaceMemberSummary> members = const [],
  List<CloudWorkspaceInviteSummary> invites = const [],
  bool canViewMembers = true,
}) => CloudWorkspaceDetailState(
  detail: CloudWorkspaceDetail(
    workspace: CloudWorkspaceSummary(
      id: 1,
      name: 'Workspace',
      role: role,
      revision: 1,
      sequence: 1,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    ownerUserId: 'owner',
    capabilities: CloudWorkspaceCapabilities(
      canViewMembers: canViewMembers,
      canInviteMembers: true,
      canInviteAdmins: true,
      canManageMembers: true,
      canManageAdmins: true,
      canRename: true,
      canTransferOwnership: true,
      canLeave: true,
      canDelete: true,
    ),
  ),
  members: members,
  invites: invites,
);

CloudWorkspaceMemberSummary _member(String userId, {String role = 'owner'}) =>
    CloudWorkspaceMemberSummary(
      userId: userId,
      role: role,
      revision: 1,
      createdAt: DateTime(2026),
    );

CloudWorkspaceInviteSummary _invite() => CloudWorkspaceInviteSummary(
  id: 1,
  email: 'invitee@example.test',
  role: 'member',
  invitedByUserId: 'owner',
  revision: 1,
  createdAt: DateTime(2026),
  expiresAt: DateTime(2026, 1, 8),
);
