import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

abstract final class SyncWakeups {
  static String workspaceChannel(int workspaceId) =>
      'auravibes.workspace.$workspaceId';

  static const conversationJobsChannel = 'auravibes.conversation.jobs';

  static String conversationChannel(int workspaceId, String conversationId) =>
      'auravibes.conversation.$workspaceId.$conversationId';

  static Future<void> publishConversation(
    Session session, {
    required int workspaceId,
    required String conversationId,
  }) => _publish(
    session,
    conversationChannel(workspaceId, conversationId),
    ConversationSubscribeRequest(
      workspaceId: workspaceId,
      conversationId: conversationId,
      afterSequence: 0,
    ),
  );

  static String conversationProgressChannel(
    int workspaceId,
    String conversationId,
  ) => 'auravibes.conversation.progress.$workspaceId.$conversationId';

  static Future<void> publishConversationProgress(
    Session session,
    ConversationStreamEvent event,
  ) => _publish(
    session,
    conversationProgressChannel(event.workspaceId, event.conversationId),
    event,
  );

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
    ConversationJob job,
  ) => _publish(session, conversationJobsChannel, job);

  static Future<void> _publish(
    Session session,
    String channel,
    SerializableModel message,
  ) async {
    final job = message is ConversationJob ? message : null;
    if (session.serverpod.redisController == null) {
      if (job != null) {
        session.log(
          'Conversation job wakeup skipped: Redis unavailable; '
          'job=${job.id}, workspace=${job.workspaceId}, kind=${job.kind}.',
          level: LogLevel.info,
        );
      }
      return;
    }
    try {
      await session.messages.postMessage(channel, message, global: true);
      if (job != null) {
        session.log(
          'Published global conversation job wakeup: '
          'job=${job.id}, workspace=${job.workspaceId}, kind=${job.kind}.',
          level: LogLevel.info,
        );
      }
    } catch (error, stackTrace) {
      session.log(
        job == null
            ? 'Redis wakeup failed; PostgreSQL polling remains active.'
            : 'Conversation job Redis wakeup failed; '
                  'PostgreSQL polling remains active. '
                  'job=${job.id}, workspace=${job.workspaceId}, '
                  'kind=${job.kind}.',
        level: LogLevel.warning,
        exception: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
  }
}
