import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/auth_user_lock.dart';
import '../sync/stream/sync_wakeups.dart';
import 'engine/a2ui_protocol.dart';

typedef ConversationWakeupStreamFactory =
    Stream<ConversationSubscribeRequest> Function(
      Session session,
      String channel,
    );
typedef ConversationProgressStreamFactory =
    Stream<ConversationStreamEvent> Function(Session session, String channel);

class const ConversationStreamService({
  final ConversationWakeupStreamFactory wakeupStream =
      _defaultConversationWakeupStream,
  final ConversationProgressStreamFactory progressStream =
      _defaultConversationProgressStream,
}) {
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
      wakeupStream(
        session,
        SyncWakeups.conversationChannel(
          request.workspaceId,
          request.conversationId,
        ),
      ),
    );
    final progress = StreamIterator<ConversationStreamEvent>(
      progressStream(
        session,
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
        final page = await _readPage(
          session,
          workspaceId: request.workspaceId,
          conversationId: request.conversationId,
          userId: userId,
          afterSequence: cursor,
        );
        final components = cloudA2uiComponentsForClient(
          request.a2uiSupportedComponents,
          isChildConversation:
              page.conversation.parentConversationStableId != null,
        );
        for (final event in page.events) {
          cursor = event.sequence;
          final outgoing = eventFor(
            event,
            conversationId: request.conversationId,
          );
          if (canDeliver(outgoing, components)) yield outgoing;
        }
        if (page.events.length < pageSize) {
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
          if (source == 'progress') {
            final activeConversation = await _readConversation(
              session,
              workspaceId: request.workspaceId,
              conversationId: request.conversationId,
              userId: userId,
            );
            final progressComponents = cloudA2uiComponentsForClient(
              request.a2uiSupportedComponents,
              isChildConversation:
                  activeConversation.parentConversationStableId != null,
            );
            if (canDeliver(progress.current, progressComponents)) {
              yield progress.current;
            }
          }
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
    eventId: event.eventId,
    kind: event.kind,
    actorUserId: event.actorUserId,
    payloadJson: event.payloadJson,
    createdAt: event.createdAt,
  );

  static bool canDeliver(
    ConversationStreamEvent event,
    Set<String> components,
  ) =>
      event.kind != ConversationEventType.a2uiMessage ||
      isCloudA2uiPayloadSupported(event.payloadJson, components);

  Future<({Conversation conversation, List<ConversationEvent> events})>
  _readPage(
    Session session, {
    required int workspaceId,
    required String conversationId,
    required String userId,
    required int afterSequence,
  }) async {
    return session.db.transaction((transaction) async {
      final conversation = await _requireActiveConversation(
        session,
        workspaceId: workspaceId,
        conversationId: conversationId,
        userId: userId,
        transaction: transaction,
      );
      final events = await ConversationEvent.db.find(
        session,
        where: (table) =>
            table.conversationId.equals(conversation.id!) &
            (table.sequence > afterSequence),
        orderBy: (table) => table.sequence,
        limit: pageSize,
        transaction: transaction,
      );
      return (conversation: conversation, events: events);
    });
  }

  Future<Conversation> _readConversation(
    Session session, {
    required int workspaceId,
    required String conversationId,
    required String userId,
  }) => session.db.transaction(
    (transaction) => _requireActiveConversation(
      session,
      workspaceId: workspaceId,
      conversationId: conversationId,
      userId: userId,
      transaction: transaction,
    ),
  );

  Future<Conversation> _requireActiveConversation(
    Session session, {
    required int workspaceId,
    required String conversationId,
    required String userId,
    required Transaction transaction,
  }) async {
    final authUser = await const AuthUserLock().lock(
      session,
      userId: userId,
      transaction: transaction,
    );
    if (authUser == null) {
      throw ConversationException(code: ConversationErrorCode.permissionDenied);
    }
    final workspace = await CloudWorkspace.db.findById(
      session,
      workspaceId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
    if (workspace.deletedAt != null) {
      throw ConversationException(code: ConversationErrorCode.notFound);
    }
    if (workspace.erasureRequestedAt != null) {
      throw ConversationException(
        code: ConversationErrorCode.permissionDenied,
      );
    }
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.userId.equals(userId) &
          table.removedAt.equals(null),
      transaction: transaction,
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
      transaction: transaction,
    );
    if (conversation == null) {
      throw ConversationException(code: ConversationErrorCode.notFound);
    }
    return conversation;
  }
}

Stream<ConversationSubscribeRequest> _defaultConversationWakeupStream(
  Session session,
  String channel,
) => session.messages.createStream<ConversationSubscribeRequest>(channel);

Stream<ConversationStreamEvent> _defaultConversationProgressStream(
  Session session,
  String channel,
) => session.messages.createStream<ConversationStreamEvent>(channel);
