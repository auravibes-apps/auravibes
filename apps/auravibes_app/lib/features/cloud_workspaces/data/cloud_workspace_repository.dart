import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

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
      CreateCloudWorkspaceRequest(
        name: name,
        requestId: const UuidV7().generate(),
      ),
    );
  }

  Future<PendingWorkspaceInviteSummary> inviteMember({
    required int workspaceId,
    required String email,
    required String role,
    required int expectedWorkspaceRevision,
  }) {
    return _client.cloudWorkspace.inviteMember(
      InviteWorkspaceMemberRequest(
        workspaceId: workspaceId,
        email: email,
        role: role,
        requestId: const UuidV7().generate(),
        expectedWorkspaceRevision: expectedWorkspaceRevision,
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
    required int expectedMemberRevision,
  }) {
    return _client.cloudWorkspace.updateMemberRole(
      UpdateWorkspaceMemberRoleRequest(
        workspaceId: workspaceId,
        userId: userId,
        role: role,
        requestId: const UuidV7().generate(),
        expectedMemberRevision: expectedMemberRevision,
      ),
    );
  }

  Future<void> removeMember({
    required int workspaceId,
    required String userId,
    required int expectedMemberRevision,
  }) {
    return _client.cloudWorkspace.removeMember(
      RemoveWorkspaceMemberRequest(
        workspaceId: workspaceId,
        userId: userId,
        requestId: const UuidV7().generate(),
        expectedMemberRevision: expectedMemberRevision,
      ),
    );
  }

  Future<CloudWorkspaceInviteSummary> renewInvite({
    required int workspaceId,
    required int inviteId,
    required int expectedInviteRevision,
  }) {
    return _client.cloudWorkspace.renewInvite(
      RenewWorkspaceInviteRequest(
        workspaceId: workspaceId,
        inviteId: inviteId,
        requestId: const UuidV7().generate(),
        expectedInviteRevision: expectedInviteRevision,
      ),
    );
  }

  Future<void> revokeInvite({
    required int workspaceId,
    required int inviteId,
    required int expectedInviteRevision,
  }) {
    return _client.cloudWorkspace.revokeInvite(
      RevokeWorkspaceInviteRequest(
        workspaceId: workspaceId,
        inviteId: inviteId,
        requestId: const UuidV7().generate(),
        expectedInviteRevision: expectedInviteRevision,
      ),
    );
  }

  Future<CloudWorkspaceSummary> acceptInvite({
    required int inviteId,
    required int expectedInviteRevision,
  }) {
    return _client.cloudWorkspace.acceptInvite(
      AcceptWorkspaceInviteRequest(
        inviteId: inviteId,
        requestId: const UuidV7().generate(),
        expectedInviteRevision: expectedInviteRevision,
      ),
    );
  }

  Future<void> declineInvite({
    required int inviteId,
    required int expectedInviteRevision,
  }) {
    return _client.cloudWorkspace.declineInvite(
      DeclineWorkspaceInviteRequest(
        inviteId: inviteId,
        requestId: const UuidV7().generate(),
        expectedInviteRevision: expectedInviteRevision,
      ),
    );
  }

  Future<CloudWorkspaceSummary> renameWorkspace({
    required int workspaceId,
    required String name,
    required int expectedWorkspaceRevision,
  }) {
    return _client.cloudWorkspace.renameWorkspace(
      RenameCloudWorkspaceRequest(
        workspaceId: workspaceId,
        name: name,
        requestId: const UuidV7().generate(),
        expectedWorkspaceRevision: expectedWorkspaceRevision,
      ),
    );
  }

  Future<void> leaveWorkspace({
    required int workspaceId,
    required int expectedWorkspaceRevision,
  }) {
    return _client.cloudWorkspace.leaveWorkspace(
      LeaveCloudWorkspaceRequest(
        workspaceId: workspaceId,
        requestId: const UuidV7().generate(),
        expectedWorkspaceRevision: expectedWorkspaceRevision,
      ),
    );
  }

  Future<void> transferOwnership({
    required int workspaceId,
    required String newOwnerUserId,
    required int expectedWorkspaceRevision,
  }) {
    return _client.cloudWorkspace.transferOwnership(
      TransferCloudWorkspaceOwnershipRequest(
        workspaceId: workspaceId,
        newOwnerUserId: newOwnerUserId,
        requestId: const UuidV7().generate(),
        expectedWorkspaceRevision: expectedWorkspaceRevision,
      ),
    );
  }

  Future<void> deleteWorkspace({
    required int workspaceId,
    required String confirmationName,
    required int expectedWorkspaceRevision,
  }) {
    return _client.cloudWorkspace.deleteWorkspace(
      DeleteCloudWorkspaceRequest(
        workspaceId: workspaceId,
        confirmationName: confirmationName,
        requestId: const UuidV7().generate(),
        expectedWorkspaceRevision: expectedWorkspaceRevision,
      ),
    );
  }
}
