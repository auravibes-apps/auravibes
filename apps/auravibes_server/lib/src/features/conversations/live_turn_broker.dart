import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

class LiveTurnBroker {
  const LiveTurnBroker();

  static String channel(int workspaceId, String turnId) =>
      'auravibes.live-turn.$workspaceId.$turnId';

  static bool usesGlobalFanout({required bool redisEnabled}) => redisEnabled;

  Future<void> publish(Session session, LiveTurnEvent event) =>
      session.messages.postMessage(
        channel(event.workspaceId, event.turnId),
        event,
        // Redis distributes transient events between server instances.
        global: usesGlobalFanout(
          redisEnabled: session.serverpod.redisController != null,
        ),
      );

  Stream<LiveTurnEvent> listen(
    Session session,
    LiveTurnSubscribeRequest request,
  ) => session.messages.createStream<LiveTurnEvent>(
    channel(request.workspaceId, request.turnId),
  );

  Stream<LiveTurnEvent> authorize(
    Session session, {
    required LiveTurnSubscribeRequest request,
    required String userId,
    required Stream<LiveTurnEvent> events,
  }) async* {
    await _requireAccess(session, request: request, userId: userId);
    await for (final event in events) {
      yield event;
    }
  }

  Future<void> _requireAccess(
    Session session, {
    required LiveTurnSubscribeRequest request,
    required String userId,
  }) async {
    await _requireMembership(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    final turn = await ConversationTurn.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(request.workspaceId) &
          table.requestId.equals(request.turnId),
    );
    if (turn == null) {
      throw ConversationException(code: ConversationErrorCode.notFound);
    }
  }

  Future<void> _requireMembership(
    Session session, {
    required int workspaceId,
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
  }
}
