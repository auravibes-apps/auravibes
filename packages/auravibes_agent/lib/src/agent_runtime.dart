import 'dart:async';

class AgentQueuedDraft {
  const AgentQueuedDraft({
    required this.content,
  });

  final String content;
}

class AgentCreatedMessage {
  const AgentCreatedMessage({
    required this.id,
  });

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
  });

  Future<void> markMessagesSent(List<String> messageIds);
}

class AgentCancellationRuntime {
  final _entries = <String, _AgentCancellationEntry>{};
  final _pendingStops = <String>{};

  Object start(String conversationId) {
    final token = Object();
    final entry = _AgentCancellationEntry(token);
    if (_pendingStops.remove(conversationId)) {
      entry.requestStop();
    }
    _entries.remove(conversationId)?.requestStop();
    _entries[conversationId] = entry;

    return token;
  }

  bool isCancellationRequested(String conversationId) {
    return _entries[conversationId]?.isCancellationRequested ?? false;
  }

  void requestStop(String conversationId) {
    final entry = _entries[conversationId];
    if (entry == null) return;

    entry.requestStop();
  }

  void requestStopOnStart(String conversationId) {
    final entry = _entries[conversationId];
    if (entry == null) {
      final _ = _pendingStops.add(conversationId);

      return;
    }

    entry.requestStop();
  }

  void clear(String conversationId, Object token) {
    if (_entries[conversationId]?.token != token) return;

    _clearEntry(conversationId);
  }

  void forceClear(String conversationId) {
    _clearEntry(conversationId);
  }

  void _clearEntry(String conversationId) {
    final entry = _entries.remove(conversationId);
    _pendingStops.remove(conversationId);
    entry?.requestStop();
  }

  void registerCleanup(
    String conversationId,
    FutureOr<void> Function() cleanup,
  ) {
    _entries
        .putIfAbsent(
          conversationId,
          () => _AgentCancellationEntry(Object()),
        )
        .registerCleanup(cleanup);
  }
}

abstract interface class AgentSendQueueRuntime {
  List<AgentQueuedDraft> dequeueAll(String conversationId);

  void clear(String conversationId);
}

class AgentRateLimitRetryRuntime {
  const AgentRateLimitRetryRuntime({
    required this.start,
    required this.clear,
  });

  final void Function(String conversationId, DateTime retryAt) start;
  final void Function(String conversationId) clear;
}

class _AgentCancellationEntry {
  _AgentCancellationEntry(this.token);

  final Object token;
  final _cleanupCallbacks = <FutureOr<void> Function()>[];
  bool _isCancellationRequested = false;

  bool get isCancellationRequested => _isCancellationRequested;

  void requestStop() {
    if (_isCancellationRequested) return;

    _isCancellationRequested = true;
    for (final cleanup in List.of(_cleanupCallbacks)) {
      try {
        final result = cleanup();
        if (result is Future<void>) {
          unawaited(result.catchError((Object _) => null));
        }
      } on Object {
        continue;
      }
    }
  }

  void registerCleanup(FutureOr<void> Function() cleanup) {
    _cleanupCallbacks.add(cleanup);
    if (!_isCancellationRequested) return;

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
