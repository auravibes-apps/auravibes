import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_workspaces/data/cloud_workspace_repository.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';

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
    final results = await Future.wait([workspacesFuture, pendingInvitesFuture]);
    final workspaces = results.firstOrNull;
    if (workspaces == null) {
      return const CloudWorkspaceViewState(
        workspaces: [],
        pendingInvites: [],
      );
    }

    return CloudWorkspaceViewState(
      workspaces: workspaces as List<CloudWorkspaceSummary>,
      pendingInvites: results[1] as List<PendingWorkspaceInviteSummary>,
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

  Future<void> detach(CloudWorkspaceSummary workspace) async {
    final deleted = await _workspaceRepository.deleteCloudWorkspaceMirror(
      cloudWorkspaceId: workspace.id.toString(),
      cloudAccountId: _cloudAccountId,
      serverUrl: _serverUrl,
    );
    assert(deleted, 'Cloud workspace mirror must be deleted.');
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
      serverUrl: workspace.url ?? _serverUrl,
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
    final attachedMirror = await attach(workspace);
    final mirror = await _workspaceRepository.getCloudWorkspaceMirrorByCloudId(
      workspace.id.toString(),
      cloudAccountId: _cloudAccountId,
      serverUrl: _serverUrl,
    );
    if (mirror == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_unexpected_error,
      );
    }
    assert(attachedMirror.id.isNotEmpty, 'Attached mirror must have an ID.');

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
    required int expectedMemberRevision,
  }) {
    return _cloudRepository.updateMemberRole(
      workspaceId: workspaceId,
      userId: userId,
      role: role,
      expectedMemberRevision: expectedMemberRevision,
    );
  }

  Future<void> removeMember({
    required int workspaceId,
    required String userId,
    required int expectedMemberRevision,
  }) {
    return _cloudRepository.removeMember(
      workspaceId: workspaceId,
      userId: userId,
      expectedMemberRevision: expectedMemberRevision,
    );
  }

  Future<PendingWorkspaceInviteSummary> invite({
    required int workspaceId,
    required String email,
    required String role,
    required int expectedWorkspaceRevision,
  }) {
    return _cloudRepository.inviteMember(
      workspaceId: workspaceId,
      email: email.trim(),
      role: role,
      expectedWorkspaceRevision: expectedWorkspaceRevision,
    );
  }

  Future<WorkspaceEntity> acceptInvite(
    PendingWorkspaceInviteSummary invite,
  ) async {
    final workspace = await _cloudRepository.acceptInvite(
      inviteId: invite.id,
      expectedInviteRevision: invite.revision,
    );

    return attach(workspace);
  }

  Future<void> declineInvite(PendingWorkspaceInviteSummary invite) {
    return _cloudRepository.declineInvite(
      inviteId: invite.id,
      expectedInviteRevision: invite.revision,
    );
  }

  Future<void> renewInvite({
    required int workspaceId,
    required int inviteId,
    required int expectedInviteRevision,
  }) {
    return _cloudRepository.renewInvite(
      workspaceId: workspaceId,
      inviteId: inviteId,
      expectedInviteRevision: expectedInviteRevision,
    );
  }

  Future<void> revokeInvite({
    required int workspaceId,
    required int inviteId,
    required int expectedInviteRevision,
  }) {
    return _cloudRepository.revokeInvite(
      workspaceId: workspaceId,
      inviteId: inviteId,
      expectedInviteRevision: expectedInviteRevision,
    );
  }

  Future<void> rename({
    required int workspaceId,
    required String name,
    required int expectedWorkspaceRevision,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_name_required_error,
      );
    }
    final workspace = await _cloudRepository.renameWorkspace(
      workspaceId: workspaceId,
      name: trimmed,
      expectedWorkspaceRevision: expectedWorkspaceRevision,
    );
    final mirror = await _workspaceRepository.getCloudWorkspaceMirrorByCloudId(
      workspaceId.toString(),
      cloudAccountId: _cloudAccountId,
      serverUrl: _serverUrl,
    );
    if (mirror != null) {
      final updatedMirror = await _workspaceRepository
          .upsertCloudWorkspaceMirror(
            cloudWorkspaceId: workspaceId.toString(),
            cloudAccountId: _cloudAccountId,
            name: workspace.name,
            serverUrl: _serverUrl,
          );
      assert(updatedMirror.id.isNotEmpty, 'Updated mirror must have an ID.');
    }
  }

  Future<void> leave({
    required int workspaceId,
    required int expectedWorkspaceRevision,
  }) async {
    await _cloudRepository.leaveWorkspace(
      workspaceId: workspaceId,
      expectedWorkspaceRevision: expectedWorkspaceRevision,
    );
    final deletedMirror = await _workspaceRepository.deleteCloudWorkspaceMirror(
      cloudWorkspaceId: workspaceId.toString(),
      cloudAccountId: _cloudAccountId,
      serverUrl: _serverUrl,
    );
    assert(deletedMirror, 'Cloud workspace mirror must be deleted.');
  }

  Future<void> transferOwnership({
    required int workspaceId,
    required String newOwnerUserId,
    required int expectedWorkspaceRevision,
  }) {
    return _cloudRepository.transferOwnership(
      workspaceId: workspaceId,
      newOwnerUserId: newOwnerUserId,
      expectedWorkspaceRevision: expectedWorkspaceRevision,
    );
  }

  Future<void> delete(CloudWorkspaceSummary workspace) async {
    await _cloudRepository.deleteWorkspace(
      workspaceId: workspace.id,
      confirmationName: workspace.name,
      expectedWorkspaceRevision: workspace.revision,
    );
    await detach(workspace);
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
    this.authenticationRequired = false,
  });

  const CloudWorkspaceViewState.authenticationRequired()
    : workspaces = const [],
      pendingInvites = const [],
      authenticationRequired = true;

  final List<CloudWorkspaceSummary> workspaces;
  final List<PendingWorkspaceInviteSummary> pendingInvites;
  final bool authenticationRequired;
}

class AppCloudWorkspaceException implements Exception {
  const AppCloudWorkspaceException(this.localizationKey);

  final String localizationKey;
}
