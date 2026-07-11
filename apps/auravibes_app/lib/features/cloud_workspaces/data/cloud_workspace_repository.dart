import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudWorkspaceRepository {
  const CloudWorkspaceRepository(this._client);

  final Client _client;

  Future<List<CloudWorkspaceSummary>> listWorkspaces() {
    return _client.cloudWorkspace.listAuthorizedWorkspaces();
  }

  Future<List<PendingWorkspaceInviteSummary>> listPendingInvites() {
    return _client.cloudWorkspace.listPendingInvites();
  }

  Future<CloudWorkspaceDetail> getWorkspaceDetail(int workspaceId) {
    return _client.cloudWorkspace.getWorkspaceDetail(
      GetCloudWorkspaceDetailRequest(workspaceId: workspaceId),
    );
  }

  Future<List<CloudWorkspaceInviteSummary>> listWorkspaceInvites(
    int workspaceId,
  ) {
    return _client.cloudWorkspace.listWorkspaceInvites(
      ListCloudWorkspaceInvitesRequest(workspaceId: workspaceId),
    );
  }

  Future<CloudWorkspaceSummary> createWorkspace(String name) {
    return _client.cloudWorkspace.createWorkspace(
      CreateCloudWorkspaceRequest(name: name),
    );
  }

  Future<PendingWorkspaceInviteSummary> inviteMember({
    required int workspaceId,
    required String email,
    required String role,
  }) {
    return _client.cloudWorkspace.inviteMember(
      InviteWorkspaceMemberRequest(
        workspaceId: workspaceId,
        email: email,
        role: role,
      ),
    );
  }

  Future<List<CloudWorkspaceMemberSummary>> listMembers(int workspaceId) {
    return _client.cloudWorkspace.listMembers(
      ListWorkspaceMembersRequest(workspaceId: workspaceId),
    );
  }

  Future<void> updateMemberRole({
    required int workspaceId,
    required String userId,
    required String role,
  }) {
    return _client.cloudWorkspace.updateMemberRole(
      UpdateWorkspaceMemberRoleRequest(
        workspaceId: workspaceId,
        userId: userId,
        role: role,
      ),
    );
  }

  Future<void> removeMember({
    required int workspaceId,
    required String userId,
  }) {
    return _client.cloudWorkspace.removeMember(
      RemoveWorkspaceMemberRequest(workspaceId: workspaceId, userId: userId),
    );
  }

  Future<CloudWorkspaceInviteSummary> renewInvite({
    required int workspaceId,
    required int inviteId,
  }) {
    return _client.cloudWorkspace.renewInvite(
      RenewWorkspaceInviteRequest(
        workspaceId: workspaceId,
        inviteId: inviteId,
      ),
    );
  }

  Future<void> revokeInvite({
    required int workspaceId,
    required int inviteId,
  }) {
    return _client.cloudWorkspace.revokeInvite(
      RevokeWorkspaceInviteRequest(
        workspaceId: workspaceId,
        inviteId: inviteId,
      ),
    );
  }

  Future<CloudWorkspaceSummary> acceptInvite(int inviteId) {
    return _client.cloudWorkspace.acceptInvite(
      AcceptWorkspaceInviteRequest(inviteId: inviteId),
    );
  }

  Future<void> declineInvite(int inviteId) {
    return _client.cloudWorkspace.declineInvite(
      DeclineWorkspaceInviteRequest(inviteId: inviteId),
    );
  }

  Future<CloudWorkspaceSummary> renameWorkspace({
    required int workspaceId,
    required String name,
  }) {
    return _client.cloudWorkspace.renameWorkspace(
      RenameCloudWorkspaceRequest(workspaceId: workspaceId, name: name),
    );
  }

  Future<void> leaveWorkspace(int workspaceId) {
    return _client.cloudWorkspace.leaveWorkspace(
      LeaveCloudWorkspaceRequest(workspaceId: workspaceId),
    );
  }

  Future<void> transferOwnership({
    required int workspaceId,
    required String newOwnerUserId,
  }) {
    return _client.cloudWorkspace.transferOwnership(
      TransferCloudWorkspaceOwnershipRequest(
        workspaceId: workspaceId,
        newOwnerUserId: newOwnerUserId,
      ),
    );
  }

  Future<void> deleteWorkspace({
    required int workspaceId,
    required String confirmationName,
  }) {
    return _client.cloudWorkspace.deleteWorkspace(
      DeleteCloudWorkspaceRequest(
        workspaceId: workspaceId,
        confirmationName: confirmationName,
      ),
    );
  }
}
