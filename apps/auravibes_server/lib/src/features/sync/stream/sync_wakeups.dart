import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

abstract final class SyncWakeups {
  static String workspaceChannel(int workspaceId) =>
      'auravibes.workspace.$workspaceId';

  static const conversationJobsChannel = 'auravibes.conversation.jobs';

  static Future<void> publishWorkspace(Session session, int workspaceId) =>
      _publish(
        session,
        workspaceChannel(workspaceId),
        WorkspaceSubscribeRequest(
          workspaceId: workspaceId,
          afterSequence: 0,
          activeTurnIds: const [],
        ),
      );

  static Future<void> publishConversationJob(
    Session session,
    StartTurnResult result,
  ) => _publish(session, conversationJobsChannel, result);

  static Future<void> _publish(
    Session session,
    String channel,
    SerializableModel message,
  ) async {
    if (session.serverpod.redisController == null) return;
    try {
      await session.messages.postMessage(channel, message, global: true);
    } catch (error, stackTrace) {
      session.log(
        'Redis wakeup failed; PostgreSQL polling remains active.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }
}
