import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../objects/object_deletion_guard.dart';

class const WorkspaceErasureCleanup(final Session session) {
  Future<void> purgeAfterRequest(int workspaceId) => session.db.transaction(
    (transaction) async {
      final workspace = await _workspace(workspaceId, transaction);
      if (workspace == null ||
          !await _ready(
            workspace,
            transaction,
            objectCleanupConfirmed: false,
          )) {
        if (workspace != null) await _refreshStatus(workspaceId, transaction);
        return;
      }
      await _purge(workspace, transaction);
    },
  );

  Future<int> purgeReady(WorkerCoordinatorLease coordinator) =>
      session.db.transaction((transaction) async {
        if (!await ObjectDeletionGuard.ownsCoordinator(
          session,
          transaction,
          coordinator,
        )) {
          return 0;
        }
        final workspaces = await CloudWorkspace.db.find(
          session,
          where: (row) =>
              row.deletedAt.notEquals(null) &
              row.erasureRequestedAt.notEquals(null),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        var purged = 0;
        for (final workspace in workspaces) {
          if (!await _ready(
            workspace,
            transaction,
            objectCleanupConfirmed: true,
          )) {
            continue;
          }
          await _purge(workspace, transaction);
          purged++;
        }
        await _refreshStatuses(transaction);
        return purged;
      });

  Future<CloudWorkspace?> _workspace(int id, Transaction transaction) =>
      CloudWorkspace.db.findById(
        session,
        id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

  Future<bool> _ready(
    CloudWorkspace workspace,
    Transaction transaction, {
    required bool objectCleanupConfirmed,
  }) async {
    if (workspace.deletedAt == null || workspace.erasureRequestedAt == null) {
      return false;
    }
    final objects = await WorkspaceObject.db.find(
      session,
      where: (row) => row.workspaceId.equals(workspace.id!),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final object in objects) {
      if (!objectCleanupConfirmed) return false;
      final deletion = await ObjectDeletion.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) &
            row.objectId.equals(object.id!),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (deletion?.completedAt == null) return false;
    }
    final pending = await ObjectDeletion.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspace.id!) & row.completedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (pending != null) return false;
    final background = await BackgroundWorkRecord.db.find(
      session,
      where: (row) => row.workspaceId.equals(workspace.id!),
      transaction: transaction,
    );
    return !background.any(
      (row) => row.status == 'running' || row.status == 'stopRequested',
    );
  }

  Future<void> _purge(CloudWorkspace workspace, Transaction transaction) async {
    final id = workspace.id!;
    await ObjectReference.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await ObjectUpload.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await ObjectDeletion.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceObject.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceResource.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceRevision.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceTrashBatch.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceSecret.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await ConversationToolCall.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await ConversationEvent.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await ConversationUsage.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await ConversationExecution.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await ConversationJob.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    final turns = await ConversationTurn.db.find(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final turn in turns) {
      await ConversationTurn.db.updateRow(
        session,
        turn.copyWith(userMessageId: null, assistantMessageId: null),
        transaction: transaction,
      );
    }
    await ConversationMessage.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await ConversationTurn.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await Conversation.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await MessageBookmark.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await ConnectorWrite.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await BackgroundWorkRecord.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceContentReport.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceModelConnection.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await RecentModelSelection.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceView.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await SkillResource.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceConversationContext.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceMutationReceipt.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceEvent.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceAuditRecord.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceInvite.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await WorkspaceMember.db.deleteWhere(
      session,
      where: (row) => row.workspaceId.equals(id),
      transaction: transaction,
    );
    await _markComplete(id, transaction);
    await CloudWorkspace.db.deleteRow(
      session,
      workspace,
      transaction: transaction,
    );
  }

  Future<void> _refreshStatuses(Transaction transaction) async {
    final requests = await WorkspaceErasureRequest.db.find(
      session,
      where: (row) => row.state.notEquals('complete'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final workspaceId in requests.map((row) => row.workspaceId).toSet()) {
      await _refreshStatus(workspaceId, transaction);
    }
  }

  Future<void> _refreshStatus(int workspaceId, Transaction transaction) async {
    final workspace = await CloudWorkspace.db.findById(
      session,
      workspaceId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) {
      await _markComplete(workspaceId, transaction);
      return;
    }
    final deletions = await ObjectDeletion.db.find(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) & row.completedAt.equals(null),
      transaction: transaction,
    );
    final needsAttention = deletions.any((row) => row.attempts >= 8);
    final requests = await WorkspaceErasureRequest.db.find(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) & row.state.notEquals('complete'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final request in requests) {
      await WorkspaceErasureRequest.db.updateRow(
        session,
        request.copyWith(
          state: needsAttention ? 'needsAttention' : 'pending',
          failureReason: needsAttention ? 'objectCleanupFailed' : null,
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _markComplete(int workspaceId, Transaction transaction) async {
    final requests = await WorkspaceErasureRequest.db.find(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) & row.state.notEquals('complete'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final now = DateTime.now().toUtc();
    for (final request in requests) {
      await WorkspaceErasureRequest.db.updateRow(
        session,
        request.copyWith(
          state: 'complete',
          completedAt: now,
          failureReason: null,
        ),
        transaction: transaction,
      );
    }
  }
}
