import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'repositories/cloud_workspace_repository.dart' as workspace_repo;
import 'usecases/cloud_workspace_usecases.dart';

class CloudWorkspaceEndpoint extends Endpoint {
  CloudWorkspaceUseCases get _useCases =>
      CloudWorkspaceUseCases(workspace_repo.CloudWorkspaceRepository());

  Future<List<CloudWorkspaceSummary>> listAuthorizedWorkspaces(
    Session session,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.listAuthorizedWorkspaces(session, userId: account.userId);
  }

  Future<List<PendingWorkspaceInviteSummary>> listPendingInvites(
    Session session,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.listPendingInvites(session, email: account.email);
  }

  Future<CloudWorkspaceDetail> getWorkspaceDetail(
    Session session,
    GetCloudWorkspaceDetailRequest request,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.getWorkspaceDetail(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<List<CloudWorkspaceMemberSummary>> listMembers(
    Session session,
    ListWorkspaceMembersRequest request,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.listMembers(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<List<CloudWorkspaceInviteSummary>> listWorkspaceInvites(
    Session session,
    ListCloudWorkspaceInvitesRequest request,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.listWorkspaceInvites(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<CloudWorkspaceSummary> createWorkspace(
    Session session,
    CreateCloudWorkspaceRequest request,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.createWorkspace(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<PendingWorkspaceInviteSummary> inviteMember(
    Session session,
    InviteWorkspaceMemberRequest request,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.inviteMember(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<CloudWorkspaceInviteSummary> renewInvite(
    Session session,
    RenewWorkspaceInviteRequest request,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.renewInvite(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<void> revokeInvite(
    Session session,
    RevokeWorkspaceInviteRequest request,
  ) async {
    final account = await _requireAccount(session);
    await _useCases.revokeInvite(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<CloudWorkspaceSummary> acceptInvite(
    Session session,
    AcceptWorkspaceInviteRequest request,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.acceptInvite(
      session,
      userId: account.userId,
      email: account.email,
      request: request,
    );
  }

  Future<void> declineInvite(
    Session session,
    DeclineWorkspaceInviteRequest request,
  ) async {
    final account = await _requireAccount(session);
    await _useCases.declineInvite(
      session,
      userId: account.userId,
      email: account.email,
      request: request,
    );
  }

  Future<CloudWorkspaceSummary> renameWorkspace(
    Session session,
    RenameCloudWorkspaceRequest request,
  ) async {
    final account = await _requireAccount(session);
    return _useCases.renameWorkspace(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<void> leaveWorkspace(
    Session session,
    LeaveCloudWorkspaceRequest request,
  ) async {
    final account = await _requireAccount(session);
    await _useCases.leaveWorkspace(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<void> transferOwnership(
    Session session,
    TransferCloudWorkspaceOwnershipRequest request,
  ) async {
    final account = await _requireAccount(session);
    await _useCases.transferOwnership(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<void> updateMemberRole(
    Session session,
    UpdateWorkspaceMemberRoleRequest request,
  ) async {
    final account = await _requireAccount(session);
    await _useCases.updateMemberRole(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<void> removeMember(
    Session session,
    RemoveWorkspaceMemberRequest request,
  ) async {
    final account = await _requireAccount(session);
    await _useCases.removeMember(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<void> deleteWorkspace(
    Session session,
    DeleteCloudWorkspaceRequest request,
  ) async {
    final account = await _requireAccount(session);
    await _useCases.deleteWorkspace(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<AccountSummary> _requireAccount(Session session) async {
    return const AuthenticatedAccountResolver()(session);
  }
}
