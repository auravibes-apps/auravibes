import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_workspaces/data/cloud_workspace_repository.dart';
import 'package:auravibes_app/features/cloud_workspaces/models/cloud_workspace_state.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

export '../models/cloud_workspace_state.dart';

typedef _CloudWorkspaceMemberRoleUpdate = Future<void> Function({
  required int workspaceId,
  required String userId,
  required String role,
  required int expectedMemberRevision,
});
typedef _CloudWorkspaceInvite = Future<PendingWorkspaceInviteSummary> Function({
  required int workspaceId,
  required String email,
  required String role,
  required int expectedWorkspaceRevision,
});

class const CloudWorkspaceUseCases({
  required final CloudWorkspaceRepository _cloudRepository,
  required final WorkspaceRepository _workspaceRepository,
  required final String _cloudAccountId,
  required final String _serverUrl,
});

extension CloudWorkspaceUseCasesCore on CloudWorkspaceUseCases {
  Future<CloudWorkspaceViewState> load() async {
    final workspacesFuture = _cloudRepository.listWorkspaces();
    final pendingInvitesFuture = _cloudRepository.listPendingInvites();
    final results = await Future.wait<Object?>([
      workspacesFuture,
      pendingInvitesFuture,
    ]);

    return _viewState(results);
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

    return _deleteMirror(
      workspace,
      cloudWorkspaceId: cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
    );
  }

  Future<WorkspaceEntity> create(String name) async {
    final trimmed = _requiredWorkspaceName(name);
    final workspace = await _cloudRepository.createWorkspace(trimmed);

    return await _attachCreatedMirror(workspace);
  }
}

extension CloudWorkspaceUseCasesMembers on CloudWorkspaceUseCases {
  Future<List<CloudWorkspaceMemberSummary>> listMembers(int workspaceId) {
    return _cloudRepository.listMembers(workspaceId);
  }

  Future<CloudWorkspaceDetailState> loadDetail(int workspaceId) async {
    final detail = await _cloudRepository.getWorkspaceDetail(workspaceId);
    final membersFuture = _loadMembers(detail, workspaceId);
    final invitesFuture = _loadInvites(detail, workspaceId);

    return CloudWorkspaceDetailState(
      detail: detail,
      members: await membersFuture,
      invites: await invitesFuture,
    );
  }

  _CloudWorkspaceMemberRoleUpdate get updateMemberRole =>
      ({
        required workspaceId,
        required userId,
        required role,
        required expectedMemberRevision,
      }) => _cloudRepository.updateMemberRole(
        workspaceId: workspaceId,
        userId: userId,
        role: role,
        expectedMemberRevision: expectedMemberRevision,
      );

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

  _CloudWorkspaceInvite get invite =>
      ({
        required workspaceId,
        required email,
        required role,
        required expectedWorkspaceRevision,
      }) => _cloudRepository.inviteMember(
        workspaceId: workspaceId,
        email: email.trim(),
        role: role,
        expectedWorkspaceRevision: expectedWorkspaceRevision,
      );

  Future<WorkspaceEntity> acceptInvite(
    PendingWorkspaceInviteSummary invite,
  ) async {
    final workspace = await _cloudRepository.acceptInvite(
      inviteId: invite.id,
      expectedInviteRevision: invite.revision,
    );

    return await attach(workspace);
  }

  Future<void> declineInvite(PendingWorkspaceInviteSummary invite) {
    return _cloudRepository.declineInvite(
      inviteId: invite.id,
      expectedInviteRevision: invite.revision,
    );
  }
}

extension CloudWorkspaceUseCasesInvites on CloudWorkspaceUseCases {
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
    final trimmed = _requiredWorkspaceName(name);
    final workspace = await _cloudRepository.renameWorkspace(
      workspaceId: workspaceId,
      name: trimmed,
      expectedWorkspaceRevision: expectedWorkspaceRevision,
    );
    await _syncRenamedMirror(workspaceId, workspace);
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

extension on CloudWorkspaceUseCases {
  CloudWorkspaceViewState _viewState(List<Object?> results) =>
      switch (results) {
        [
          final List<CloudWorkspaceSummary> workspaces,
          final List<PendingWorkspaceInviteSummary> pendingInvites,
        ] =>
          CloudWorkspaceViewState(
            workspaces: workspaces,
            pendingInvites: pendingInvites,
          ),
        _ => const CloudWorkspaceViewState(workspaces: [], pendingInvites: []),
      };

  String _requiredWorkspaceName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_name_required_error,
      );
    }

    return trimmed;
  }

  Future<WorkspaceEntity> _attachCreatedMirror(
    CloudWorkspaceSummary workspace,
  ) async {
    final attachedMirror = await attach(workspace);
    final mirror = await _findMirror(workspace.id);
    if (mirror == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_unexpected_error,
      );
    }
    assert(attachedMirror.id.isNotEmpty, 'Attached mirror must have an ID.');

    return mirror;
  }

  Future<List<CloudWorkspaceMemberSummary>> _loadMembers(
    CloudWorkspaceDetail detail,
    int workspaceId,
  ) => detail.capabilities.canViewMembers
      ? _cloudRepository.listMembers(workspaceId)
      : Future.value(const <CloudWorkspaceMemberSummary>[]);

  Future<List<CloudWorkspaceInviteSummary>> _loadInvites(
    CloudWorkspaceDetail detail,
    int workspaceId,
  ) => detail.capabilities.canInviteMembers
      ? _cloudRepository.listWorkspaceInvites(workspaceId)
      : Future.value(const <CloudWorkspaceInviteSummary>[]);

  Future<void> _syncRenamedMirror(
    int workspaceId,
    CloudWorkspaceSummary workspace,
  ) async {
    final mirror = await _findMirror(workspaceId);
    if (mirror == null) return;

    final updatedMirror = await _upsertMirror(workspaceId, workspace.name);
    assert(updatedMirror.id.isNotEmpty, 'Updated mirror must have an ID.');
  }

  Future<WorkspaceEntity?> _findMirror(int workspaceId) =>
      _workspaceRepository.getCloudWorkspaceMirrorByCloudId(
        workspaceId.toString(),
        cloudAccountId: _cloudAccountId,
        serverUrl: _serverUrl,
      );

  Future<WorkspaceEntity> _upsertMirror(int workspaceId, String name) =>
      _workspaceRepository.upsertCloudWorkspaceMirror(
        cloudWorkspaceId: workspaceId.toString(),
        cloudAccountId: _cloudAccountId,
        name: name,
        serverUrl: _serverUrl,
      );
}

extension on CloudWorkspaceUseCases {
  Future<void> _deleteMirror(
    WorkspaceEntity workspace, {
    required String cloudWorkspaceId,
    required String cloudAccountId,
  }) => _workspaceRepository.deleteCloudWorkspaceMirror(
    cloudWorkspaceId: cloudWorkspaceId,
    cloudAccountId: cloudAccountId,
    serverUrl: workspace.url ?? _serverUrl,
  );
}

class const AppCloudWorkspaceException(final String localizationKey)
    implements Exception;
