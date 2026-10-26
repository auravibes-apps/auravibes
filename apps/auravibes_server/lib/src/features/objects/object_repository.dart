import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_deletion_guard.dart';

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
    return reference != null;
  }

  Future<bool> hasReadableMessageReference(
    Session session, {
    required int workspaceId,
    required int objectId,
    Transaction? transaction,
  }) =>
      _MessageReferences(session, transaction).contains(workspaceId, objectId);

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
    if (!await ObjectDeletionGuard.ownsCoordinator(
      session,
      transaction,
      coordinator,
    )) {
      return;
    }
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
    if (!await ObjectDeletionGuard.ownsCoordinator(
      session,
      transaction,
      coordinator,
    )) {
      return;
    }
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
}

class const _MessageReferences(
  final Session session,
  final Transaction? transaction,
) {
  Future<bool> contains(int workspaceId, int objectId) async {
    for (final reference in await _rows(workspaceId, objectId)) {
      if (await _readable(reference)) return true;
    }

    return false;
  }

  Future<List<ObjectReference>> _rows(int workspaceId, int objectId) =>
      ObjectReference.db.find(
        session,
        where: (row) => _liveReference(row, workspaceId, objectId),
        transaction: transaction,
      );

  Expression _liveReference(
    ObjectReferenceTable row,
    int workspaceId,
    int objectId,
  ) =>
      row.workspaceId.equals(workspaceId) &
      row.objectId.equals(objectId) &
      row.deletedAt.equals(null);

  Future<bool> _readable(ObjectReference reference) async {
    final message = await _message(reference);
    if (message == null) return false;
    final conversation = await _conversation(
      reference.workspaceId,
      message.conversationId,
    );

    return conversation != null;
  }

  Future<ConversationMessage?> _message(ObjectReference reference) =>
      ConversationMessage.db.findFirstRow(
        session,
        where: (row) => _messageScope(row, reference),
        transaction: transaction,
      );

  Expression _messageScope(
    ConversationMessageTable row,
    ObjectReference reference,
  ) =>
      row.id.equals(reference.messageId) &
      row.workspaceId.equals(reference.workspaceId) &
      row.status.notEquals('deleted');

  Future<Conversation?> _conversation(int workspaceId, int conversationId) =>
      Conversation.db.findFirstRow(
        session,
        where: (row) => _conversationScope(row, workspaceId, conversationId),
        transaction: transaction,
      );

  Expression _conversationScope(
    ConversationTable row,
    int workspaceId,
    int conversationId,
  ) =>
      row.id.equals(conversationId) &
      row.workspaceId.equals(workspaceId) &
      row.deletedAt.equals(null);
}
