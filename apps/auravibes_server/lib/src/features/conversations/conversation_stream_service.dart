import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../sync/stream/sync_wakeups.dart';

class ConversationStreamService {
  const ConversationStreamService();

  static const pageSize = 100;
  static const pollInterval = Duration(seconds: 1);

  Stream<ConversationStreamEvent> subscribe(
    Session session, {
    required ConversationSubscribeRequest request,
    required String userId,
  }) async* {
    if (request.afterSequence < 0) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.invalidCursor,
      );
    }

    final wakeups = StreamIterator<ConversationSubscribeRequest>(
      session.messages.createStream<ConversationSubscribeRequest>(
        SyncWakeups.conversationChannel(
          request.workspaceId,
          request.conversationId,
        ),
      ),
    );
    final progress = StreamIterator<ConversationStreamEvent>(
      session.messages.createStream<ConversationStreamEvent>(
        SyncWakeups.conversationProgressChannel(
          request.workspaceId,
          request.conversationId,
        ),
      ),
    );
    var cursor = request.afterSequence;
    Future<bool>? pendingWakeup;
    Future<bool>? pendingProgress;
    try {
      while (true) {
        final conversation = await _requireMembership(
          session,
          workspaceId: request.workspaceId,
          conversationId: request.conversationId,
          userId: userId,
        );
        final events = await ConversationEvent.db.find(
          session,
          where: (table) =>
              table.conversationId.equals(conversation.id!) &
              (table.sequence > cursor),
          orderBy: (table) => table.sequence,
          limit: pageSize,
        );
        for (final event in events) {
          cursor = event.sequence;
          yield eventFor(event, conversationId: request.conversationId);
        }
        if (events.length < pageSize) {
          final wakeup = pendingWakeup ??= wakeups.moveNext().whenComplete(
            () => pendingWakeup = null,
          );
          final progressEvent = pendingProgress ??= progress
              .moveNext()
              .whenComplete(() => pendingProgress = null);
          final source = await Future.any<String>([
            wakeup.then((_) => 'wakeup'),
            progressEvent.then((hasEvent) => hasEvent ? 'progress' : 'none'),
            Future<String>.delayed(pollInterval, () => 'poll'),
          ]);
          if (source == 'progress') yield progress.current;
        }
      }
    } finally {
      await wakeups.cancel();
      await progress.cancel();
    }
  }

  static ConversationStreamEvent eventFor(
    ConversationEvent event, {
    required String conversationId,
  }) => ConversationStreamEvent(
    workspaceId: event.workspaceId,
    conversationId: conversationId,
    sequence: event.sequence,
    kind: event.kind,
    actorUserId: event.actorUserId,
    payloadJson: event.payloadJson,
    createdAt: event.createdAt,
  );

  Future<Conversation> _requireMembership(
    Session session, {
    required int workspaceId,
    required String conversationId,
    required String userId,
  }) async {
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.userId.equals(userId) &
          table.removedAt.equals(null),
    );
    if (member == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.stableId.equals(conversationId) &
          table.deletedAt.equals(null),
    );
    if (conversation == null) {
      throw ConversationException(code: ConversationErrorCode.notFound);
    }
    return conversation;
  }
}
