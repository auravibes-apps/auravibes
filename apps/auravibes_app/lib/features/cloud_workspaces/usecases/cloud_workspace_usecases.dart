// ignore_for_file: avoid-ignoring-return-values, newline-before-return

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_workspaces/data/cloud_workspace_repository.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudWorkspaceUseCases {
  const CloudWorkspaceUseCases({
    required this._cloudRepository,
    required this._workspaceRepository,
    required this._cloudAccountId,
    required this._serverUrl,
  });

  final CloudWorkspaceRepository _cloudRepository;
  final WorkspaceRepository _workspaceRepository;
  final String _cloudAccountId;
  final String _serverUrl;

  Future<CloudWorkspaceViewState> load() async {
    final workspacesFuture = _cloudRepository.listWorkspaces();
    final pendingInvitesFuture = _cloudRepository.listPendingInvites();

    return CloudWorkspaceViewState(
      workspaces: await workspacesFuture,
      pendingInvites: await pendingInvitesFuture,
    );
  }

  Future<WorkspaceEntity> attach(CloudWorkspaceSummary workspace) {
    return _workspaceRepository.upsertCloudWorkspaceMirror(
      cloudWorkspaceId: workspace.id.toString(),
      cloudAccountId: _cloudAccountId,
      name: workspace.name,
      serverUrl: _serverUrl,
    );
  }

  Future<void> detach(CloudWorkspaceSummary workspace) {
    return _workspaceRepository.deleteCloudWorkspaceMirror(
      cloudWorkspaceId: workspace.id.toString(),
      cloudAccountId: _cloudAccountId,
    );
  }

  Future<void> detachMirror(WorkspaceEntity workspace) {
    final cloudWorkspaceId = workspace.cloudWorkspaceId;
    final cloudAccountId = workspace.cloudAccountId;
    if (cloudWorkspaceId == null || cloudAccountId == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_unexpected_error,
      );
    }

    return _workspaceRepository.deleteCloudWorkspaceMirror(
      cloudWorkspaceId: cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
    );
  }

  Future<WorkspaceEntity> create(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_name_required_error,
      );
    }

    final workspace = await _cloudRepository.createWorkspace(trimmed);
    final _ = await attach(workspace);
    final mirror = await _workspaceRepository.getCloudWorkspaceMirrorByCloudId(
      workspace.id.toString(),
    );
    if (mirror == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_unexpected_error,
      );
    }

    return mirror;
  }

  Future<List<CloudWorkspaceMemberSummary>> listMembers(int workspaceId) {
    return _cloudRepository.listMembers(workspaceId);
  }

  Future<CloudWorkspaceDetailState> loadDetail(int workspaceId) async {
    final detailFuture = _cloudRepository.getWorkspaceDetail(workspaceId);
    final detail = await detailFuture;
    final membersFuture = detail.capabilities.canViewMembers
        ? _cloudRepository.listMembers(workspaceId)
        : Future.value(const <CloudWorkspaceMemberSummary>[]);
    final invitesFuture = detail.capabilities.canInviteMembers
        ? _cloudRepository.listWorkspaceInvites(workspaceId)
        : Future.value(const <CloudWorkspaceInviteSummary>[]);

    return CloudWorkspaceDetailState(
      detail: detail,
      members: await membersFuture,
      invites: await invitesFuture,
    );
  }

  Future<void> updateMemberRole({
    required int workspaceId,
    required String userId,
    required String role,
  }) {
    return _cloudRepository.updateMemberRole(
      workspaceId: workspaceId,
      userId: userId,
      role: role,
    );
  }

  Future<void> removeMember({
    required int workspaceId,
    required String userId,
  }) {
    return _cloudRepository.removeMember(
      workspaceId: workspaceId,
      userId: userId,
    );
  }

  Future<PendingWorkspaceInviteSummary> invite({
    required int workspaceId,
    required String email,
    required String role,
  }) {
    return _cloudRepository.inviteMember(
      workspaceId: workspaceId,
      email: email.trim(),
      role: role,
    );
  }

  Future<WorkspaceEntity> acceptInvite(int inviteId) async {
    final workspace = await _cloudRepository.acceptInvite(inviteId);

    return attach(workspace);
  }

  Future<void> declineInvite(int inviteId) {
    return _cloudRepository.declineInvite(inviteId);
  }

  Future<void> renewInvite({required int workspaceId, required int inviteId}) {
    return _cloudRepository.renewInvite(
      workspaceId: workspaceId,
      inviteId: inviteId,
    );
  }

  Future<void> revokeInvite({required int workspaceId, required int inviteId}) {
    return _cloudRepository.revokeInvite(
      workspaceId: workspaceId,
      inviteId: inviteId,
    );
  }

  Future<void> rename({required int workspaceId, required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_name_required_error,
      );
    }
    final workspace = await _cloudRepository.renameWorkspace(
      workspaceId: workspaceId,
      name: trimmed,
    );
    final mirror = await _workspaceRepository.getCloudWorkspaceMirrorByCloudId(
      workspaceId.toString(),
    );
    if (mirror != null) {
      final _ = await _workspaceRepository.upsertCloudWorkspaceMirror(
        cloudWorkspaceId: workspaceId.toString(),
        cloudAccountId: _cloudAccountId,
        name: workspace.name,
        serverUrl: _serverUrl,
      );
    }
  }

  Future<void> leave(int workspaceId) async {
    await _cloudRepository.leaveWorkspace(workspaceId);
    final _ = await _workspaceRepository.deleteCloudWorkspaceMirror(
      cloudWorkspaceId: workspaceId.toString(),
      cloudAccountId: _cloudAccountId,
    );
  }

  Future<void> transferOwnership({
    required int workspaceId,
    required String newOwnerUserId,
  }) {
    return _cloudRepository.transferOwnership(
      workspaceId: workspaceId,
      newOwnerUserId: newOwnerUserId,
    );
  }

  Future<void> delete(CloudWorkspaceSummary workspace) async {
    await _cloudRepository.deleteWorkspace(
      workspaceId: workspace.id,
      confirmationName: workspace.name,
    );
    final _ = await detach(workspace);
  }
}

class CloudWorkspaceDetailState {
  const CloudWorkspaceDetailState({
    required this.detail,
    required this.members,
    required this.invites,
  });

  final CloudWorkspaceDetail detail;
  final List<CloudWorkspaceMemberSummary> members;
  final List<CloudWorkspaceInviteSummary> invites;
}

class CloudWorkspaceViewState {
  const CloudWorkspaceViewState({
    required this.workspaces,
    required this.pendingInvites,
  });

  final List<CloudWorkspaceSummary> workspaces;
  final List<PendingWorkspaceInviteSummary> pendingInvites;
}

class AppCloudWorkspaceException implements Exception {
  const AppCloudWorkspaceException(this.localizationKey);

  final String localizationKey;
}
