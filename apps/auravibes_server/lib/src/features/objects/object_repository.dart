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
    required DateTime now,
  }) => ObjectDeletion.db.updateRow(
    session,
    deletion.copyWith(completedAt: now, lastError: null),
  );

  Future<void> failDeletion(
    Session session, {
    required ObjectDeletion deletion,
    required DateTime now,
    required String error,
  }) {
    final attempts = deletion.attempts + 1;
    final delayMinutes = 1 << (attempts - 1).clamp(0, 6);
    return ObjectDeletion.db.updateRow(
      session,
      deletion.copyWith(
        attempts: attempts,
        availableAt: now.add(Duration(minutes: delayMinutes)),
        lastError: error,
      ),
    );
  }
}
