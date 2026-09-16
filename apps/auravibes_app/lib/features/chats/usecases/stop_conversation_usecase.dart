import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_pending_tool_stopper.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';

class const StopConversationUsecase({
  required final ConversationRepository conversationRepository,
  required final MessageRepository messageRepository,
  required final AgentCancellationRuntime cancellationRuntime,
  required final ConversationSendQueueRuntime sendQueueRuntime,
  required final ConversationStreamingRuntime streamingRuntime,
  required final ConversationRateLimitRetryRuntime retryRuntime,
  required final ActiveSubAgentRuntime activeSubAgents,
}) {
  AppAgentPendingToolStopper get _pendingToolStopper =>
      AppAgentPendingToolStopper(messageRepository);

  Future<void> call(String conversationId) async {
    final ids = await _descendants(conversationId);
    Object? firstError;
    StackTrace? firstStackTrace;
    for (final id in ids) {
      try {
        await _stopOne(id);
      } on Object catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    final error = firstError;
    final stackTrace = firstStackTrace;
    if (error != null && stackTrace != null) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<List<String>> _descendants(String rootId) async {
    final ordered = <String>[];
    final visited = <String>{};

    Future<void> visit(String id) async {
      if (!visited.add(id)) return;
      final persisted = await conversationRepository.getChildConversations(id);
      final children = <String>{
        ...persisted.map((conversation) => conversation.id),
        ...activeSubAgents.childrenOf(id),
      };
      for (final childId in children) {
        await visit(childId);
      }
      ordered.add(id);
    }

    await visit(rootId);

    return ordered;
  }

  Future<void> _stopOne(String conversationId) async {
    final parentId = activeSubAgents.parentOf(conversationId);
    cancellationRuntime.requestStopOnStart(conversationId);
    sendQueueRuntime.clear(conversationId);
    retryRuntime.clear(conversationId);
    streamingRuntime.remove(conversationId);
    await cancellationRuntime.waitForCompletion(conversationId);
    await _pendingToolStopper.call(conversationId);
    if (parentId != null &&
        activeSubAgents.parentOf(conversationId) == parentId) {
      activeSubAgents.finish(
        parentId: parentId,
        childId: conversationId,
        status: .stopped,
      );
    }
  }
}
