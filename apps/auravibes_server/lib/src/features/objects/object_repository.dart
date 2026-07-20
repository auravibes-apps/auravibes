import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

class ObjectRepository {
  Future<WorkspaceObject?> findObject(
    Session session, {
    required int workspaceId,
    required int objectId,
    Transaction? transaction,
    bool lock = false,
  }) => WorkspaceObject.db.findFirstRow(
    session,
    where: (t) => t.id.equals(objectId) & t.workspaceId.equals(workspaceId),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
  );

  Future<ObjectUpload?> findUpload(
    Session session, {
    required int workspaceId,
    required int objectId,
    Transaction? transaction,
  }) => ObjectUpload.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) & t.objectId.equals(objectId),
    transaction: transaction,
  );

  Future<ObjectUpload?> findUploadByRequest(
    Session session, {
    required int workspaceId,
    required String actorUserId,
    required String requestId,
  }) => ObjectUpload.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.actorUserId.equals(actorUserId) &
        t.requestId.equals(requestId),
  );

  Future<bool> hasLiveReference(
    Session session, {
    required int workspaceId,
    required int objectId,
    Transaction? transaction,
    bool lock = false,
  }) async {
    final reference = await ObjectReference.db.findFirstRow(
      session,
      where: (t) =>
          t.workspaceId.equals(workspaceId) &
          t.objectId.equals(objectId) &
          t.deletedAt.equals(null),
      transaction: transaction,
      lockMode: lock ? LockMode.forUpdate : null,
    );
    if (reference == null) return false;
    final message = await ConversationMessage.db.findFirstRow(
      session,
      where: (t) =>
          t.id.equals(reference.messageId) &
          t.workspaceId.equals(workspaceId) &
          t.status.notEquals('deleted'),
      transaction: transaction,
      lockMode: lock ? LockMode.forUpdate : null,
    );
    return message != null;
  }

  Future<ObjectDeletion?> findDeletionByRequest(
    Session session, {
    required int workspaceId,
    required String requestId,
    Transaction? transaction,
  }) => ObjectDeletion.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) & t.requestId.equals(requestId),
    transaction: transaction,
  );

  Future<List<ObjectDeletion>> listPendingDeletions(
    Session session, {
    required DateTime now,
    required int limit,
    required int maxAttempts,
  }) => ObjectDeletion.db.find(
    session,
    where: (t) =>
        t.completedAt.equals(null) &
        (t.availableAt <= now) &
        (t.attempts < maxAttempts),
    orderBy: (t) => t.availableAt,
    limit: limit,
  );

  Future<void> completeDeletion(
    Session session, {
    required ObjectDeletion deletion,
    required WorkerCoordinatorLease coordinator,
    required DateTime now,
  }) => session.db.transaction((transaction) async {
    if (!await _ownsCoordinator(session, transaction, coordinator)) return;
    final current = await ObjectDeletion.db.findById(
      session,
      deletion.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (current == null || current.completedAt != null) return;
    await ObjectDeletion.db.updateRow(
      session,
      current.copyWith(completedAt: now, lastError: null),
      transaction: transaction,
    );
  });

  Future<void> failDeletion(
    Session session, {
    required ObjectDeletion deletion,
    required WorkerCoordinatorLease coordinator,
    required DateTime now,
    required String error,
  }) => session.db.transaction((transaction) async {
    if (!await _ownsCoordinator(session, transaction, coordinator)) return;
    final current = await ObjectDeletion.db.findById(
      session,
      deletion.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (current == null || current.completedAt != null) return;
    final attempts = current.attempts + 1;
    final delayMinutes = 1 << (attempts - 1).clamp(0, 6);
    await ObjectDeletion.db.updateRow(
      session,
      current.copyWith(
        attempts: attempts,
        availableAt: now.add(Duration(minutes: delayMinutes)),
        lastError: error,
      ),
      transaction: transaction,
    );
  });

  Future<bool> _ownsCoordinator(
    Session session,
    Transaction transaction,
    WorkerCoordinatorLease coordinator,
  ) async {
    final lease = await WorkerCoordinatorLease.db.findFirstRow(
      session,
      where: (table) => table.key.equals('global'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final result = await session.db.unsafeQuery(
      'SELECT clock_timestamp() AS "now"',
      transaction: transaction,
    );
    final now = result.first.toColumnMap()['now']! as DateTime;
    return lease != null &&
        lease.ownerId == coordinator.ownerId &&
        lease.fencingToken == coordinator.fencingToken &&
        lease.expiresAt.isAfter(now);
  }
}
