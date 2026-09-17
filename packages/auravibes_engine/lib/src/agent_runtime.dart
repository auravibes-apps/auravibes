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

  Future<void> markMessagesErrored(List<String> messageIds);
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
  final _cleanupFutures = <Future<void>>[];
  final _closedCompleter = Completer<void>();
  bool _isCancellationRequested = false;
  bool _isClosed = false;

  bool get isCancellationRequested => _isCancellationRequested;

  Future<void> get cleanupCompletion async {
    if (_cleanupFutures.isEmpty) return;

    await Future.wait(List<Future<void>>.of(_cleanupFutures));
  }

  Future<void> waitForCleanupCompletion() async {
    var observed = 0;
    while (true) {
      final futures = List<Future<void>>.of(_cleanupFutures);
      if (futures.length > observed) {
        observed = futures.length;
        await Future.wait(futures);
        continue;
      }
      if (_isClosed) return;
      await _closedCompleter.future;
    }
  }

  void close() {
    if (_isClosed) return;

    _isClosed = true;
    _closedCompleter.complete();
  }

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
        final future = result.catchError((Object _) {});
        _cleanupFutures.add(future);
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
