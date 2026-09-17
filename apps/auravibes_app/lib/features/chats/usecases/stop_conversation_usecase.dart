import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_pending_tool_stopper.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';

typedef _StopResult = ({Object? error, StackTrace? stackTrace});

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
    final result = await _stopConversations(await _descendants(conversationId));
    final error = result.error;
    final stackTrace = result.stackTrace;
    if (error == null || stackTrace == null) return;
    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<_StopResult> _stopConversations(List<String> ids) async {
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

    return (error: firstError, stackTrace: firstStackTrace);
  }

  Future<List<String>> _descendants(String rootId) async {
    final ordered = <String>[];
    final visited = <String>{};

    await _visitDescendant(rootId, visited, ordered);

    return ordered;
  }

  Future<void> _visitDescendant(
    String id,
    Set<String> visited,
    List<String> ordered,
  ) async {
    if (!visited.add(id)) return;
    for (final childId in await _childIds(id)) {
      await _visitDescendant(childId, visited, ordered);
    }
    ordered.add(id);
  }

  Future<Set<String>> _childIds(String id) async {
    final persisted = await conversationRepository.getChildConversations(id);

    return {
      ...persisted.map((conversation) => conversation.id),
      ...activeSubAgents.childrenOf(id),
    };
  }

  Future<void> _stopOne(String conversationId) async {
    final parentId = activeSubAgents.parentOf(conversationId);
    await _stopRuntime(conversationId);
    _releaseParent(conversationId, parentId);
  }

  Future<void> _stopRuntime(String conversationId) async {
    cancellationRuntime.requestStopOnStart(conversationId);
    sendQueueRuntime.clear(conversationId);
    retryRuntime.clear(conversationId);
    final _ = streamingRuntime.remove(conversationId);
    await cancellationRuntime.waitForCompletion(conversationId);
    await _pendingToolStopper.call(conversationId);
  }

  void _releaseParent(String conversationId, String? parentId) {
    if (parentId != null &&
        activeSubAgents.parentOf(conversationId) == parentId) {
      activeSubAgents.finish((
        parentId: parentId,
        childId: conversationId,
        status: .stopped,
        error: null,
        stackTrace: null,
      ));
    }
  }
}
