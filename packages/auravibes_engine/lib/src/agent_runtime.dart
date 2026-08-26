import 'dart:async';

class AgentQueuedDraft {
  const AgentQueuedDraft({required this.content, this.payload});

  final String content;
  final Object? payload;
}

class AgentCreatedMessage {
  const AgentCreatedMessage({required this.id});

  final String id;
}

class AgentConversationMessage {
  const AgentConversationMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.type,
    required this.status,
    required this.isUser,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String conversationId;
  final String content;
  final String type;
  final String status;
  final bool isUser;
  final DateTime createdAt;
  final DateTime updatedAt;
}

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

class AgentRateLimitRetryRuntime {
  const AgentRateLimitRetryRuntime({required this.start, required this.clear});

  final void Function(String conversationId, DateTime retryAt) start;
  final void Function(String conversationId) clear;
}
