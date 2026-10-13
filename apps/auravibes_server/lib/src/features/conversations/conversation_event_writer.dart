import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../sync/stream/sync_wakeups.dart';

typedef ConversationWakeupPublisher = Future<void> Function(
  Session session, {
  required int workspaceId,
  required String conversationId,
});

class ConversationEventWriter {
  new({
    ConversationWakeupPublisher? publishConversation,
  }) : _publishConversation =
           publishConversation ?? SyncWakeups.publishConversation;

  final ConversationWakeupPublisher _publishConversation;

  Future<ConversationEventWriteResult> write(
    Session session, {
    required int workspaceId,
    required String conversationId,
    required String actorUserId,
    required String requestId,
    required ConversationEventType kind,
    required String payloadJson,
    String? eventId,
    Future<void> Function(Transaction transaction)? guard,
    Future<void> Function(
      Transaction transaction,
      Conversation conversation,
      DateTime now,
    )?
    persist,
    required Conversation Function(Conversation conversation) updateProjection,
  }) async {
    final result = await session.db.transaction((transaction) async {
      final conversation = await Conversation.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(workspaceId) &
            table.stableId.equals(conversationId) &
            table.deletedAt.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (conversation == null) {
        throw ConversationException(code: ConversationErrorCode.notFound);
      }

      if (eventId != null) {
        final existing = await ConversationEvent.db.findFirstRow(
          session,
          where: (table) =>
              table.workspaceId.equals(workspaceId) &
              table.eventId.equals(eventId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (existing != null) {
          if (existing.conversationId != conversation.id ||
              existing.actorUserId != actorUserId ||
              existing.kind != kind ||
              existing.payloadJson != payloadJson) {
            throw ConversationException(
              code: ConversationErrorCode.idempotencyConflict,
            );
          }
          return ConversationEventWriteResult(
            conversation: conversation,
            event: existing,
          );
        }
      }

      final now = DateTime.now().toUtc();
      await guard?.call(transaction);
      await persist?.call(transaction, conversation, now);
      final sequence = conversation.eventSequence + 1;
      final projection = await Conversation.db.updateRow(
        session,
        updateProjection(conversation).copyWith(
          eventSequence: sequence,
          projectionRevision: conversation.projectionRevision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      final event = await ConversationEvent.db.insertRow(
        session,
        ConversationEvent(
          workspaceId: workspaceId,
          conversationId: conversation.id!,
          sequence: sequence,
          eventId: eventId ?? const Uuid().v7(),
          actorUserId: actorUserId,
          requestId: requestId,
          kind: kind,
          payloadJson: payloadJson,
          createdAt: now,
        ),
        transaction: transaction,
      );
      return ConversationEventWriteResult(
        conversation: projection,
        event: event,
      );
    });

    await _publishConversation(
      session,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    return result;
  }
}

class const ConversationEventWriteResult({
  required final Conversation conversation,
  required final ConversationEvent event,
});
