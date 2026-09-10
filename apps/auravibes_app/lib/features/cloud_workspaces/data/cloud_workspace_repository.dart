import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

typedef _CloudWorkspaceInviteMember =
    Future<PendingWorkspaceInviteSummary> Function({
      required int workspaceId,
      required String email,
      required String role,
      required int expectedWorkspaceRevision,
    });
typedef _CloudWorkspaceMemberRoleUpdate = Future<void> Function({
  required int workspaceId,
  required String userId,
  required String role,
  required int expectedMemberRevision,
});
typedef _CloudWorkspaceInviteInput = ({
  Client client,
  int workspaceId,
  String email,
  String role,
  int expectedWorkspaceRevision,
});
typedef _CloudWorkspaceMemberRoleInput = ({
  Client client,
  int workspaceId,
  String userId,
  String role,
  int expectedMemberRevision,
});

class const CloudWorkspaceRepository(final Client _client);

extension CloudWorkspaceRepositoryReadOperations on CloudWorkspaceRepository {
  Future<List<CloudWorkspaceSummary>> listWorkspaces() {
    return _client.cloudWorkspace.listAuthorizedWorkspaces();
  }

  Future<List<PendingWorkspaceInviteSummary>> listPendingInvites() {
    return _client.cloudWorkspace.listPendingInvites();
  }

  Future<CloudWorkspaceDetail> getWorkspaceDetail(int workspaceId) {
    return _client.cloudWorkspace.getWorkspaceDetail(
      .new(workspaceId: workspaceId),
    );
  }

  Future<List<CloudWorkspaceInviteSummary>> listWorkspaceInvites(
    int workspaceId,
  ) {
    return _client.cloudWorkspace.listWorkspaceInvites(
      .new(workspaceId: workspaceId),
    );
  }

  Future<CloudWorkspaceSummary> createWorkspace(String name) {
    return _client.cloudWorkspace.createWorkspace(
      .new(name: name, requestId: const UuidV7().generate()),
    );
  }
}

extension CloudWorkspaceRepositoryMemberOperations on CloudWorkspaceRepository {
  _CloudWorkspaceInviteMember get inviteMember => _inviteMemberHandler(_client);

  Future<List<CloudWorkspaceMemberSummary>> listMembers(int workspaceId) {
    return _client.cloudWorkspace.listMembers(.new(workspaceId: workspaceId));
  }

  _CloudWorkspaceMemberRoleUpdate get updateMemberRole =>
      _updateMemberRoleHandler(_client);

  Future<void> removeMember({
    required int workspaceId,
    required String userId,
    required int expectedMemberRevision,
  }) {
    return _client.cloudWorkspace.removeMember(
      .new(
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
      .new(
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
      .new(
        workspaceId: workspaceId,
        inviteId: inviteId,
        requestId: const UuidV7().generate(),
        expectedInviteRevision: expectedInviteRevision,
      ),
    );
  }
}

_CloudWorkspaceInviteMember _inviteMemberHandler(Client client) =>
    ({
      required workspaceId,
      required email,
      required role,
      required expectedWorkspaceRevision,
    }) => _inviteMember((
      client: client,
      workspaceId: workspaceId,
      email: email,
      role: role,
      expectedWorkspaceRevision: expectedWorkspaceRevision,
    ));

_CloudWorkspaceMemberRoleUpdate _updateMemberRoleHandler(Client client) =>
    ({
      required workspaceId,
      required userId,
      required role,
      required expectedMemberRevision,
    }) => _updateMemberRole((
      client: client,
      workspaceId: workspaceId,
      userId: userId,
      role: role,
      expectedMemberRevision: expectedMemberRevision,
    ));

Future<PendingWorkspaceInviteSummary> _inviteMember(
  _CloudWorkspaceInviteInput input,
) => input.client.cloudWorkspace.inviteMember(
  .new(
    workspaceId: input.workspaceId,
    email: input.email,
    role: input.role,
    requestId: const UuidV7().generate(),
    expectedWorkspaceRevision: input.expectedWorkspaceRevision,
  ),
);

Future<void> _updateMemberRole(_CloudWorkspaceMemberRoleInput input) =>
    input.client.cloudWorkspace.updateMemberRole(
      .new(
        workspaceId: input.workspaceId,
        userId: input.userId,
        role: input.role,
        requestId: const UuidV7().generate(),
        expectedMemberRevision: input.expectedMemberRevision,
      ),
    );

extension CloudWorkspaceRepositoryWorkspaceOps on CloudWorkspaceRepository {
  Future<CloudWorkspaceSummary> acceptInvite({
    required int inviteId,
    required int expectedInviteRevision,
  }) {
    return _client.cloudWorkspace.acceptInvite(
      .new(
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
      .new(
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
      .new(
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
      .new(
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
      .new(
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
      .new(
        workspaceId: workspaceId,
        confirmationName: confirmationName,
        requestId: const UuidV7().generate(),
        expectedWorkspaceRevision: expectedWorkspaceRevision,
      ),
    );
  }
}
