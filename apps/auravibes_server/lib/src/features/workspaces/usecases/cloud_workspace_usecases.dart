import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../../generated/protocol.dart';
import '../domain/workspace_roles.dart';
import '../repositories/cloud_workspace_repository.dart' as workspace_repo;

class CloudWorkspaceUseCases {
  CloudWorkspaceUseCases(this._repository);

  static const _inviteLifetime = Duration(days: 7);
  static const _maxWorkspaceNameLength = 20;
  static const _maxEmailLength = 254;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final workspace_repo.CloudWorkspaceRepository _repository;

  Future<List<CloudWorkspaceSummary>> listAuthorizedWorkspaces(
    Session session, {
    required String userId,
  }) => _repository.listAuthorizedWorkspaces(session, userId: userId);

  Future<List<PendingWorkspaceInviteSummary>> listPendingInvites(
    Session session, {
    required String email,
  }) => _repository.listPendingInvites(
    session,
    email: _normalizeEmail(email),
    now: DateTime.now().toUtc(),
  );

  Future<CloudWorkspaceDetail> getWorkspaceDetail(
    Session session, {
    required String userId,
    required GetCloudWorkspaceDetailRequest request,
  }) async {
    final workspace = await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, workspace.id!, userId);
    return CloudWorkspaceDetail(
      workspace: _repository.toSummary(workspace, actor.role),
      ownerUserId: workspace.ownerUserId,
      ownerEmail: await _findEmail(session, workspace.ownerUserId),
      capabilities: capabilitiesForRole(actor.role),
    );
  }

  Future<List<CloudWorkspaceMemberSummary>> listMembers(
    Session session, {
    required String userId,
    required ListWorkspaceMembersRequest request,
  }) async {
    await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, request.workspaceId, userId);
    if (!WorkspaceRoles.canViewRoster(actor.role)) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    final members = await _repository.listActiveMembers(
      session,
      workspaceId: request.workspaceId,
    );
    return Future.wait(
      members.map(
        (member) async => CloudWorkspaceMemberSummary(
          userId: member.userId,
          email: await _findEmail(session, member.userId),
          role: member.role,
          createdAt: member.createdAt,
        ),
      ),
    );
  }

  Future<List<CloudWorkspaceInviteSummary>> listWorkspaceInvites(
    Session session, {
    required String userId,
    required ListCloudWorkspaceInvitesRequest request,
  }) async {
    await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, request.workspaceId, userId);
    if (!WorkspaceRoles.canViewRoster(actor.role)) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    final invites = await _repository.listActiveInvites(
      session,
      workspaceId: request.workspaceId,
      now: DateTime.now().toUtc(),
    );
    return invites.map(_inviteSummary).toList();
  }

  Future<CloudWorkspaceSummary> createWorkspace(
    Session session, {
    required String userId,
    required CreateCloudWorkspaceRequest request,
  }) async {
    final name = _requireName(request.name);
    final now = DateTime.now().toUtc();
    final workspace = await session.db.transaction(
      (transaction) => _repository.createWorkspace(
        session,
        name: name,
        ownerUserId: userId,
        now: now,
        transaction: transaction,
      ),
    );
    return _repository.toSummary(workspace, WorkspaceRoles.owner);
  }

  Future<PendingWorkspaceInviteSummary> inviteMember(
    Session session, {
    required String userId,
    required InviteWorkspaceMemberRequest request,
  }) async {
    final role = _requireRole(request.role);
    final workspace = await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, workspace.id!, userId);
    if (!WorkspaceRoles.canInvite(actor.role, role)) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    final email = _normalizeEmail(request.email);
    if (email.length > _maxEmailLength || !_emailPattern.hasMatch(email)) {
      _fail(CloudWorkspaceErrorCode.validationFailed);
    }
    final now = DateTime.now().toUtc();
    if (await _repository.findActiveInviteByEmail(
          session,
          workspaceId: workspace.id!,
          email: email,
          now: now,
        ) !=
        null) {
      _fail(CloudWorkspaceErrorCode.duplicateInvite);
    }
    final invite = await session.db.transaction(
      (transaction) async {
        final staleInvite = await _repository.findInviteByPendingKey(
          session,
          pendingKey: '${workspace.id}:$email',
          transaction: transaction,
        );
        if (staleInvite != null) {
          await _repository.clearPendingKey(
            session,
            invite: staleInvite,
            transaction: transaction,
          );
        }
        return _repository.createInvite(
          session,
          workspaceId: workspace.id!,
          email: email,
          role: role,
          invitedByUserId: userId,
          now: now,
          expiresAt: now.add(_inviteLifetime),
          transaction: transaction,
        );
      },
    );
    return PendingWorkspaceInviteSummary(
      id: invite.id!,
      workspaceId: workspace.id!,
      workspaceName: workspace.name,
      email: invite.email,
      role: invite.role,
      createdAt: invite.createdAt,
    );
  }

  Future<CloudWorkspaceInviteSummary> renewInvite(
    Session session, {
    required String userId,
    required RenewWorkspaceInviteRequest request,
  }) async {
    await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, request.workspaceId, userId);
    final invite = await _requireInvite(session, request.inviteId);
    _requireInviteWorkspace(invite, request.workspaceId);
    if (!WorkspaceRoles.canInvite(actor.role, invite.role)) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    if (invite.revokedAt != null) {
      _fail(CloudWorkspaceErrorCode.inviteRevoked);
    }
    if (invite.acceptedAt != null || invite.declinedAt != null) {
      _fail(CloudWorkspaceErrorCode.inviteNotFound);
    }
    final now = DateTime.now().toUtc();
    final activeInvite = await _repository.findActiveInviteByEmail(
      session,
      workspaceId: invite.workspaceId,
      email: invite.email,
      now: now,
    );
    if (activeInvite != null && activeInvite.id != invite.id) {
      _fail(CloudWorkspaceErrorCode.duplicateInvite);
    }
    final renewed = await _repository.renewInvite(
      session,
      invite: invite,
      expiresAt: now.add(_inviteLifetime),
    );
    return _inviteSummary(renewed);
  }

  Future<void> revokeInvite(
    Session session, {
    required String userId,
    required RevokeWorkspaceInviteRequest request,
  }) async {
    await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, request.workspaceId, userId);
    final invite = await _requireInvite(session, request.inviteId);
    _requireInviteWorkspace(invite, request.workspaceId);
    if (!WorkspaceRoles.canInvite(actor.role, invite.role)) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    _requireActiveInvite(invite, DateTime.now().toUtc());
    await _repository.revokeInvite(
      session,
      invite: invite,
      now: DateTime.now().toUtc(),
    );
  }

  Future<CloudWorkspaceSummary> acceptInvite(
    Session session, {
    required String userId,
    required String email,
    required AcceptWorkspaceInviteRequest request,
  }) => session.db.transaction((transaction) async {
    final invite = await _requireInvite(
      session,
      request.inviteId,
      transaction: transaction,
    );
    final now = DateTime.now().toUtc();
    _requireActiveInvite(invite, now);
    if (invite.email != _normalizeEmail(email)) {
      _fail(CloudWorkspaceErrorCode.inviteEmailMismatch);
    }
    final workspace = await _requireWorkspace(
      session,
      invite.workspaceId,
      transaction: transaction,
    );
    if (await _repository.findActiveMember(
          session,
          workspaceId: workspace.id!,
          userId: userId,
          transaction: transaction,
        ) !=
        null) {
      _fail(CloudWorkspaceErrorCode.duplicateMembership);
    }
    await _repository.upsertMember(
      session,
      workspaceId: workspace.id!,
      userId: userId,
      role: invite.role,
      now: now,
      transaction: transaction,
    );
    await _repository.acceptInvite(
      session,
      invite: invite,
      userId: userId,
      now: now,
      transaction: transaction,
    );
    return _repository.toSummary(workspace, invite.role);
  });

  Future<void> declineInvite(
    Session session, {
    required String email,
    required DeclineWorkspaceInviteRequest request,
  }) async {
    final invite = await _requireInvite(session, request.inviteId);
    _requireActiveInvite(invite, DateTime.now().toUtc());
    if (invite.email != _normalizeEmail(email)) {
      _fail(CloudWorkspaceErrorCode.inviteEmailMismatch);
    }
    await _repository.declineInvite(
      session,
      invite: invite,
      now: DateTime.now().toUtc(),
    );
  }

  Future<CloudWorkspaceSummary> renameWorkspace(
    Session session, {
    required String userId,
    required RenameCloudWorkspaceRequest request,
  }) async {
    final workspace = await _requireWorkspace(session, request.workspaceId);
    _requireOwner(workspace, userId);
    final renamed = await _repository.renameWorkspace(
      session,
      workspace: workspace,
      name: _requireName(request.name),
      now: DateTime.now().toUtc(),
    );
    return _repository.toSummary(renamed, WorkspaceRoles.owner);
  }

  Future<void> leaveWorkspace(
    Session session, {
    required String userId,
    required LeaveCloudWorkspaceRequest request,
  }) async {
    final workspace = await _requireWorkspace(session, request.workspaceId);
    if (workspace.ownerUserId == userId) {
      _fail(CloudWorkspaceErrorCode.ownerCannotLeave);
    }
    final member = await _requireMember(session, request.workspaceId, userId);
    await _repository.removeMember(
      session,
      member: member,
      now: DateTime.now().toUtc(),
    );
  }

  Future<void> transferOwnership(
    Session session, {
    required String userId,
    required TransferCloudWorkspaceOwnershipRequest request,
  }) => session.db.transaction((transaction) async {
    final workspace = await _requireWorkspace(
      session,
      request.workspaceId,
      transaction: transaction,
    );
    _requireOwner(workspace, userId);
    final owner = await _requireMember(
      session,
      request.workspaceId,
      userId,
      transaction: transaction,
    );
    final newOwner = await _requireMember(
      session,
      request.workspaceId,
      request.newOwnerUserId,
      transaction: transaction,
    );
    if (newOwner.role == WorkspaceRoles.owner) {
      _fail(CloudWorkspaceErrorCode.validationFailed);
    }
    await _repository.transferOwnership(
      session,
      workspace: workspace,
      owner: owner,
      newOwner: newOwner,
      now: DateTime.now().toUtc(),
      transaction: transaction,
    );
  });

  Future<void> updateMemberRole(
    Session session, {
    required String userId,
    required UpdateWorkspaceMemberRoleRequest request,
  }) async {
    final role = _requireRole(request.role);
    await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, request.workspaceId, userId);
    final target = await _requireMember(
      session,
      request.workspaceId,
      request.userId,
    );
    if (!WorkspaceRoles.canAssignRole(actor.role, target.role, role)) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    await _repository.updateMemberRole(session, member: target, role: role);
  }

  Future<void> removeMember(
    Session session, {
    required String userId,
    required RemoveWorkspaceMemberRequest request,
  }) async {
    if (request.userId == userId) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, request.workspaceId, userId);
    final target = await _requireMember(
      session,
      request.workspaceId,
      request.userId,
    );
    if (target.role == WorkspaceRoles.owner) {
      _fail(CloudWorkspaceErrorCode.ownerCannotBeRemoved);
    }
    if (!WorkspaceRoles.canManageTarget(actor.role, target.role)) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    await _repository.removeMember(
      session,
      member: target,
      now: DateTime.now().toUtc(),
    );
  }

  Future<void> deleteWorkspace(
    Session session, {
    required String userId,
    required DeleteCloudWorkspaceRequest request,
  }) async {
    final workspace = await _requireWorkspace(session, request.workspaceId);
    _requireOwner(workspace, userId);
    if (request.confirmationName != workspace.name) {
      _fail(CloudWorkspaceErrorCode.confirmationNameMismatch);
    }
    await _repository.softDeleteWorkspace(
      session,
      workspace: workspace,
      now: DateTime.now().toUtc(),
    );
  }

  Future<CloudWorkspace> _requireWorkspace(
    Session session,
    int id, {
    Transaction? transaction,
  }) async {
    final workspace = await _repository.findActiveWorkspace(
      session,
      id,
      transaction: transaction,
    );
    if (workspace == null) _fail(CloudWorkspaceErrorCode.workspaceNotFound);
    return workspace;
  }

  Future<WorkspaceMember> _requireMember(
    Session session,
    int workspaceId,
    String userId, {
    Transaction? transaction,
  }) async {
    final member = await _repository.findActiveMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
    );
    if (member == null) _fail(CloudWorkspaceErrorCode.membershipRequired);
    return member;
  }

  Future<WorkspaceInvite> _requireInvite(
    Session session,
    int id, {
    Transaction? transaction,
  }) async {
    final invite = await _repository.findInviteById(
      session,
      id,
      transaction: transaction,
    );
    if (invite == null) _fail(CloudWorkspaceErrorCode.inviteNotFound);
    return invite;
  }

  void _requireActiveInvite(WorkspaceInvite invite, DateTime now) {
    if (invite.revokedAt != null) _fail(CloudWorkspaceErrorCode.inviteRevoked);
    final expiresAt = invite.expiresAt ?? invite.createdAt.add(_inviteLifetime);
    if (!expiresAt.isAfter(now)) {
      _fail(CloudWorkspaceErrorCode.inviteExpired);
    }
    if (invite.acceptedAt != null || invite.declinedAt != null) {
      _fail(CloudWorkspaceErrorCode.inviteNotFound);
    }
  }

  void _requireInviteWorkspace(WorkspaceInvite invite, int workspaceId) {
    if (invite.workspaceId != workspaceId) {
      _fail(CloudWorkspaceErrorCode.inviteNotFound);
    }
  }

  void _requireOwner(CloudWorkspace workspace, String userId) {
    if (workspace.ownerUserId != userId) {
      _fail(CloudWorkspaceErrorCode.ownerRequired);
    }
  }

  String _requireName(String value) {
    final name = value.trim();
    if (name.isEmpty || name.length > _maxWorkspaceNameLength) {
      _fail(CloudWorkspaceErrorCode.validationFailed);
    }
    return name;
  }

  String _requireRole(String value) {
    final role = value.trim().toLowerCase();
    if (!WorkspaceRoles.isValid(role) || role == WorkspaceRoles.owner) {
      _fail(CloudWorkspaceErrorCode.invalidRole);
    }
    return role;
  }

  Future<String?> _findEmail(Session session, String userId) async {
    try {
      final account = await EmailAccount.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(UuidValue.fromString(userId)),
      );
      return account?.email;
    } on FormatException {
      return null;
    }
  }

  CloudWorkspaceInviteSummary _inviteSummary(WorkspaceInvite invite) =>
      CloudWorkspaceInviteSummary(
        id: invite.id!,
        email: invite.email,
        role: invite.role,
        invitedByUserId: invite.invitedByUserId,
        createdAt: invite.createdAt,
        expiresAt: invite.expiresAt ?? invite.createdAt.add(_inviteLifetime),
      );

  static CloudWorkspaceCapabilities capabilitiesForRole(String role) =>
      CloudWorkspaceCapabilities(
        canViewMembers: WorkspaceRoles.canViewRoster(role),
        canInviteMembers: WorkspaceRoles.canInvite(role, WorkspaceRoles.member),
        canInviteAdmins: WorkspaceRoles.canInvite(role, WorkspaceRoles.admin),
        canManageMembers: WorkspaceRoles.canManageTarget(
          role,
          WorkspaceRoles.member,
        ),
        canManageAdmins: WorkspaceRoles.canManageTarget(
          role,
          WorkspaceRoles.admin,
        ),
        canRename: role == WorkspaceRoles.owner,
        canTransferOwnership: role == WorkspaceRoles.owner,
        canLeave: role != WorkspaceRoles.owner,
        canDelete: role == WorkspaceRoles.owner,
      );

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Never _fail(CloudWorkspaceErrorCode code) =>
      throw CloudWorkspaceException(code: code);
}
