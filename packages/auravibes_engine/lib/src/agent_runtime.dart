import 'dart:async';

class const AgentQueuedDraft({
  required final String content,
  final Object? payload,
});

class const AgentCreatedMessage({required final String id});

class const AgentConversationMessage({
  required final String id,
  required final String conversationId,
  required final String content,
  required final String type,
  required final String status,
  required final bool isUser,
  required final DateTime createdAt,
  required final DateTime updatedAt,
});

abstract interface class AgentConversationDataProvider {
  Future<String?> getWorkspaceId(String conversationId);

  Future<List<AgentConversationMessage>> getMessages(String conversationId);

  Future<AgentCreatedMessage> createQueuedUserMessage({
    required String conversationId,
    required String content,
    Object? payload,
  });

  Future<void> markMessagesSent(List<String> messageIds);
}

abstract interface class AgentCancellationEffects {
  AgentCancellationScope start(String conversationId);

  AgentCancellationScope? current(String conversationId);

  void requestStop(String conversationId);

  void requestStopOnStart(String conversationId);

  void clear(String conversationId, AgentCancellationScope scope);

  void forceClear(String conversationId);
}

class AgentCancellationScope {
  final _cleanupCallbacks = <FutureOr<void> Function()>[];
  bool _isCancellationRequested = false;

  bool get isCancellationRequested => _isCancellationRequested;

  void requestStop() {
    if (_isCancellationRequested) return;

    _isCancellationRequested = true;
    List.of(_cleanupCallbacks).forEach(_runCleanup);
  }

  void registerCleanup(FutureOr<void> Function() cleanup) {
    _cleanupCallbacks.add(cleanup);
    if (_isCancellationRequested) _runCleanup(cleanup);
  }

  void _runCleanup(FutureOr<void> Function() cleanup) {
    try {
      final result = cleanup();
      if (result is Future<void>) {
        unawaited(result.catchError((Object _) => null));
      }
    } on Object {
      return;
    }
  }
}

abstract interface class AgentSendQueueRuntime {
  List<AgentQueuedDraft> dequeueAll(String conversationId);

  void clear(String conversationId);
}

class const AgentRateLimitRetryRuntime({
  required final void Function(String conversationId, DateTime retryAt) start,
  required final void Function(String conversationId) clear,
});
