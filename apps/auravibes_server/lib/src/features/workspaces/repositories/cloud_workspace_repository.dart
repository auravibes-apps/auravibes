import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../domain/workspace_roles.dart';

class CloudWorkspaceRepository {
  Future<CloudWorkspace> createWorkspace(
    Session session, {
    required String name,
    required String ownerUserId,
    required DateTime now,
    Transaction? transaction,
  }) async {
    final workspace = await CloudWorkspace.db.insertRow(
      session,
      CloudWorkspace(
        name: name,
        ownerUserId: ownerUserId,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await WorkspaceMember.db.insertRow(
      session,
      WorkspaceMember(
        workspaceId: workspace.id!,
        userId: ownerUserId,
        role: WorkspaceRoles.owner,
        createdAt: now,
      ),
      transaction: transaction,
    );
    return workspace;
  }

  Future<List<CloudWorkspaceSummary>> listAuthorizedWorkspaces(
    Session session, {
    required String userId,
  }) async {
    final members = await WorkspaceMember.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.removedAt.equals(null),
    );
    final summaries = <CloudWorkspaceSummary>[];
    for (final member in members) {
      final workspace = await findActiveWorkspace(session, member.workspaceId);
      if (workspace != null) {
        summaries.add(toSummary(workspace, member.role));
      }
    }
    return summaries;
  }

  Future<List<PendingWorkspaceInviteSummary>> listPendingInvites(
    Session session, {
    required String email,
    required DateTime now,
  }) async {
    final invites = await WorkspaceInvite.db.find(
      session,
      where: (t) =>
          t.email.equals(email) &
          (t.expiresAt.equals(null) | (t.expiresAt > now)) &
          t.acceptedAt.equals(null) &
          t.declinedAt.equals(null) &
          t.revokedAt.equals(null),
    );
    final summaries = <PendingWorkspaceInviteSummary>[];
    for (final invite in invites) {
      final workspace = await findActiveWorkspace(session, invite.workspaceId);
      if (workspace != null) {
        summaries.add(
          PendingWorkspaceInviteSummary(
            id: invite.id!,
            workspaceId: invite.workspaceId,
            workspaceName: workspace.name,
            email: invite.email,
            role: invite.role,
            createdAt: invite.createdAt,
          ),
        );
      }
    }
    return summaries;
  }

  Future<CloudWorkspace?> findActiveWorkspace(
    Session session,
    int id, {
    Transaction? transaction,
  }) async {
    final workspace = await CloudWorkspace.db.findById(
      session,
      id,
      transaction: transaction,
    );
    return workspace?.deletedAt == null ? workspace : null;
  }

  Future<WorkspaceMember?> findActiveMember(
    Session session, {
    required int workspaceId,
    required String userId,
    Transaction? transaction,
  }) => WorkspaceMember.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.userId.equals(userId) &
        t.removedAt.equals(null),
    transaction: transaction,
  );

  Future<WorkspaceMember?> findMember(
    Session session, {
    required int workspaceId,
    required String userId,
    Transaction? transaction,
  }) => WorkspaceMember.db.findFirstRow(
    session,
    where: (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
    transaction: transaction,
  );

  Future<List<WorkspaceMember>> listActiveMembers(
    Session session, {
    required int workspaceId,
  }) => WorkspaceMember.db.find(
    session,
    where: (t) => t.workspaceId.equals(workspaceId) & t.removedAt.equals(null),
    orderBy: (t) => t.createdAt,
  );

  Future<WorkspaceInvite?> findInviteById(
    Session session,
    int id, {
    Transaction? transaction,
  }) => WorkspaceInvite.db.findById(session, id, transaction: transaction);

  Future<WorkspaceInvite?> findActiveInviteByEmail(
    Session session, {
    required int workspaceId,
    required String email,
    required DateTime now,
  }) => WorkspaceInvite.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.email.equals(email) &
        (t.expiresAt.equals(null) | (t.expiresAt > now)) &
        t.acceptedAt.equals(null) &
        t.declinedAt.equals(null) &
        t.revokedAt.equals(null),
  );

  Future<WorkspaceInvite?> findInviteByPendingKey(
    Session session, {
    required String pendingKey,
    required Transaction transaction,
  }) => WorkspaceInvite.db.findFirstRow(
    session,
    where: (t) => t.pendingKey.equals(pendingKey),
    transaction: transaction,
  );

  Future<List<WorkspaceInvite>> listActiveInvites(
    Session session, {
    required int workspaceId,
    required DateTime now,
  }) => WorkspaceInvite.db.find(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        (t.expiresAt.equals(null) | (t.expiresAt > now)) &
        t.acceptedAt.equals(null) &
        t.declinedAt.equals(null) &
        t.revokedAt.equals(null),
    orderBy: (t) => t.createdAt,
  );

  Future<WorkspaceInvite> createInvite(
    Session session, {
    required WorkspaceInvite invite,
    Transaction? transaction,
  }) => WorkspaceInvite.db.insertRow(
    session,
    invite,
    transaction: transaction,
  );

  Future<void> clearPendingKey(
    Session session, {
    required WorkspaceInvite invite,
    required Transaction transaction,
  }) => WorkspaceInvite.db.updateRow(
    session,
    invite.copyWith(pendingKey: null),
    transaction: transaction,
  );

  Future<WorkspaceInvite> renewInvite(
    Session session, {
    required WorkspaceInvite invite,
    required DateTime expiresAt,
  }) => WorkspaceInvite.db.updateRow(
    session,
    invite.copyWith(
      expiresAt: expiresAt,
      revokedAt: null,
      pendingKey: '${invite.workspaceId}:${invite.email}',
    ),
  );

  Future<void> revokeInvite(
    Session session, {
    required WorkspaceInvite invite,
    required DateTime now,
  }) => WorkspaceInvite.db.updateRow(
    session,
    invite.copyWith(revokedAt: now, pendingKey: null),
  );

  Future<void> acceptInvite(
    Session session, {
    required WorkspaceInvite invite,
    required String userId,
    required DateTime now,
    required Transaction transaction,
  }) => WorkspaceInvite.db.updateRow(
    session,
    invite.copyWith(
      acceptedByUserId: userId,
      acceptedAt: now,
      pendingKey: null,
    ),
    transaction: transaction,
  );

  Future<void> declineInvite(
    Session session, {
    required WorkspaceInvite invite,
    required DateTime now,
  }) => WorkspaceInvite.db.updateRow(
    session,
    invite.copyWith(declinedAt: now, pendingKey: null),
  );

  Future<void> upsertMember(
    Session session, {
    required int workspaceId,
    required String userId,
    required String role,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final member = await findMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
    );
    if (member == null) {
      await WorkspaceMember.db.insertRow(
        session,
        WorkspaceMember(
          workspaceId: workspaceId,
          userId: userId,
          role: role,
          createdAt: now,
        ),
        transaction: transaction,
      );
      return;
    }
    await WorkspaceMember.db.updateRow(
      session,
      member.copyWith(role: role, removedAt: null),
      transaction: transaction,
    );
  }

  Future<void> updateMemberRole(
    Session session, {
    required WorkspaceMember member,
    required String role,
    Transaction? transaction,
  }) => WorkspaceMember.db.updateRow(
    session,
    member.copyWith(role: role),
    transaction: transaction,
  );

  Future<void> removeMember(
    Session session, {
    required WorkspaceMember member,
    required DateTime now,
  }) => WorkspaceMember.db.updateRow(
    session,
    member.copyWith(removedAt: now),
  );

  Future<CloudWorkspace> renameWorkspace(
    Session session, {
    required CloudWorkspace workspace,
    required String name,
    required DateTime now,
  }) => CloudWorkspace.db.updateRow(
    session,
    workspace.copyWith(name: name, updatedAt: now),
  );

  Future<void> transferOwnership(
    Session session, {
    required CloudWorkspace workspace,
    required WorkspaceMember owner,
    required WorkspaceMember newOwner,
    required DateTime now,
    required Transaction transaction,
  }) async {
    await updateMemberRole(
      session,
      member: owner,
      role: WorkspaceRoles.admin,
      transaction: transaction,
    );
    await updateMemberRole(
      session,
      member: newOwner,
      role: WorkspaceRoles.owner,
      transaction: transaction,
    );
    await CloudWorkspace.db.updateRow(
      session,
      workspace.copyWith(ownerUserId: newOwner.userId, updatedAt: now),
      transaction: transaction,
    );
  }

  Future<void> softDeleteWorkspace(
    Session session, {
    required CloudWorkspace workspace,
    required DateTime now,
  }) => CloudWorkspace.db.updateRow(
    session,
    workspace.copyWith(updatedAt: now, deletedAt: now),
  );

  CloudWorkspaceSummary toSummary(CloudWorkspace workspace, String role) =>
      CloudWorkspaceSummary(
        id: workspace.id!,
        name: workspace.name,
        role: role,
        createdAt: workspace.createdAt,
        updatedAt: workspace.updatedAt,
      );
}
