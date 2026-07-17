import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../domain/workspace_roles.dart';

class CloudWorkspaceRepository {
  static const maxReadRows = 200;

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
        revision: 1,
        sequence: 0,
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
        revision: 1,
        createdAt: now,
        updatedAt: now,
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
      orderBy: (t) => t.id,
      limit: maxReadRows,
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
      orderBy: (t) => t.id,
      limit: maxReadRows,
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
            revision: invite.revision,
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
    bool lock = false,
  }) async {
    final workspace = lock
        ? await CloudWorkspace.db.findFirstRow(
            session,
            where: (t) => t.id.equals(id),
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          )
        : await CloudWorkspace.db.findById(
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
    bool lock = false,
  }) => WorkspaceMember.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.userId.equals(userId) &
        t.removedAt.equals(null),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
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
    orderBy: (t) => t.id,
    limit: maxReadRows,
  );

  Future<WorkspaceInvite?> findInviteById(
    Session session,
    int id, {
    Transaction? transaction,
    bool lock = false,
  }) => lock
      ? WorkspaceInvite.db.findFirstRow(
          session,
          where: (t) => t.id.equals(id),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        )
      : WorkspaceInvite.db.findById(session, id, transaction: transaction);

  Future<WorkspaceInvite?> findActiveInviteByEmail(
    Session session, {
    required int workspaceId,
    required String email,
    required DateTime now,
    Transaction? transaction,
    bool lock = false,
  }) => WorkspaceInvite.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.email.equals(email) &
        (t.expiresAt.equals(null) | (t.expiresAt > now)) &
        t.acceptedAt.equals(null) &
        t.declinedAt.equals(null) &
        t.revokedAt.equals(null),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
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
    orderBy: (t) => t.id,
    limit: maxReadRows,
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
    required DateTime now,
    required Transaction transaction,
  }) => WorkspaceInvite.db.updateRow(
    session,
    invite.copyWith(
      expiresAt: expiresAt,
      revision: invite.revision + 1,
      updatedAt: now,
      revokedAt: null,
      pendingKey: '${invite.workspaceId}:${invite.email}',
    ),
    transaction: transaction,
  );

  Future<void> revokeInvite(
    Session session, {
    required WorkspaceInvite invite,
    required DateTime now,
    required Transaction transaction,
  }) => WorkspaceInvite.db.updateRow(
    session,
    invite.copyWith(
      revision: invite.revision + 1,
      updatedAt: now,
      revokedAt: now,
      pendingKey: null,
    ),
    transaction: transaction,
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
      revision: invite.revision + 1,
      updatedAt: now,
      pendingKey: null,
    ),
    transaction: transaction,
  );

  Future<void> declineInvite(
    Session session, {
    required WorkspaceInvite invite,
    required DateTime now,
    required Transaction transaction,
  }) => WorkspaceInvite.db.updateRow(
    session,
    invite.copyWith(
      revision: invite.revision + 1,
      updatedAt: now,
      declinedAt: now,
      pendingKey: null,
    ),
    transaction: transaction,
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
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      return;
    }
    await WorkspaceMember.db.updateRow(
      session,
      member.copyWith(
        role: role,
        revision: member.revision + 1,
        updatedAt: now,
        removedAt: null,
      ),
      transaction: transaction,
    );
  }

  Future<void> updateMemberRole(
    Session session, {
    required WorkspaceMember member,
    required String role,
    required DateTime now,
    Transaction? transaction,
  }) => WorkspaceMember.db.updateRow(
    session,
    member.copyWith(
      role: role,
      revision: member.revision + 1,
      updatedAt: now,
    ),
    transaction: transaction,
  );

  Future<void> removeMember(
    Session session, {
    required WorkspaceMember member,
    required DateTime now,
    required Transaction transaction,
  }) => WorkspaceMember.db.updateRow(
    session,
    member.copyWith(
      revision: member.revision + 1,
      updatedAt: now,
      removedAt: now,
    ),
    transaction: transaction,
  );

  Future<CloudWorkspace> renameWorkspace(
    Session session, {
    required CloudWorkspace workspace,
    required String name,
    required DateTime now,
    required Transaction transaction,
  }) => CloudWorkspace.db.updateRow(
    session,
    workspace.copyWith(
      name: name,
      revision: workspace.revision + 1,
      updatedAt: now,
    ),
    transaction: transaction,
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
      now: now,
      transaction: transaction,
    );
    await updateMemberRole(
      session,
      member: newOwner,
      role: WorkspaceRoles.owner,
      now: now,
      transaction: transaction,
    );
    await CloudWorkspace.db.updateRow(
      session,
      workspace.copyWith(
        ownerUserId: newOwner.userId,
        revision: workspace.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<void> softDeleteWorkspace(
    Session session, {
    required CloudWorkspace workspace,
    required DateTime now,
    required Transaction transaction,
  }) async {
    await CloudWorkspace.db.updateRow(
      session,
      workspace.copyWith(
        revision: workspace.revision + 1,
        updatedAt: now,
        deletedAt: now,
      ),
      transaction: transaction,
    );
    final members = await WorkspaceMember.db.find(
      session,
      where: (t) =>
          t.workspaceId.equals(workspace.id!) & t.removedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final member in members) {
      await removeMember(
        session,
        member: member,
        now: now,
        transaction: transaction,
      );
    }
    final invites = await WorkspaceInvite.db.find(
      session,
      where: (t) =>
          t.workspaceId.equals(workspace.id!) &
          t.acceptedAt.equals(null) &
          t.declinedAt.equals(null) &
          t.revokedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final invite in invites) {
      await revokeInvite(
        session,
        invite: invite,
        now: now,
        transaction: transaction,
      );
    }
  }

  Future<WorkspaceMutationReceipt?> findReceipt(
    Session session, {
    required String actorUserId,
    required String scopeKey,
    required String endpoint,
    required String requestId,
    required Transaction transaction,
  }) => WorkspaceMutationReceipt.db.findFirstRow(
    session,
    where: (t) =>
        t.actorUserId.equals(actorUserId) &
        t.scopeKey.equals(scopeKey) &
        t.endpoint.equals(endpoint) &
        t.requestId.equals(requestId),
    transaction: transaction,
  );

  Future<CloudWorkspace> recordMutation(
    Session session, {
    required CloudWorkspace workspace,
    required String actorUserId,
    required String scopeKey,
    required String endpoint,
    required String requestId,
    required String requestHash,
    required String operation,
    required String resourceKind,
    String? resourceId,
    required String responseJson,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final committed = await CloudWorkspace.db.updateRow(
      session,
      workspace.copyWith(sequence: workspace.sequence + 1, updatedAt: now),
      transaction: transaction,
    );
    await WorkspaceEvent.db.insertRow(
      session,
      WorkspaceEvent(
        eventId: requestId,
        workspaceId: workspace.id!,
        sequence: committed.sequence,
        actorUserId: actorUserId,
        kind: operation,
        resourceKind: resourceKind,
        resourceId: resourceId,
        createdAt: now,
      ),
      transaction: transaction,
    );
    await WorkspaceAuditRecord.db.insertRow(
      session,
      WorkspaceAuditRecord(
        workspaceId: workspace.id!,
        sequence: committed.sequence,
        actorUserId: actorUserId,
        operation: operation,
        targetKind: resourceKind,
        targetId: resourceId,
        createdAt: now,
      ),
      transaction: transaction,
    );
    await WorkspaceMutationReceipt.db.insertRow(
      session,
      WorkspaceMutationReceipt(
        workspaceId: workspace.id,
        actorUserId: actorUserId,
        scopeKey: scopeKey,
        endpoint: endpoint,
        requestId: requestId,
        requestHash: requestHash,
        responseJson: responseJson,
        createdAt: now,
      ),
      transaction: transaction,
    );
    return committed;
  }

  CloudWorkspaceSummary toSummary(CloudWorkspace workspace, String role) =>
      CloudWorkspaceSummary(
        id: workspace.id!,
        name: workspace.name,
        role: role,
        revision: workspace.revision,
        sequence: workspace.sequence,
        createdAt: workspace.createdAt,
        updatedAt: workspace.updatedAt,
      );
}
