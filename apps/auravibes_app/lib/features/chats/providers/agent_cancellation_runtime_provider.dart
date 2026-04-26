import 'dart:async';

import 'package:async/async.dart';
import 'package:riverpod/riverpod.dart';

class AgentCancellationRuntime {
  final _entries = <String, _AgentCancellationEntry>{};

  void start(String conversationId) {
    _entries[conversationId] = _AgentCancellationEntry();
  }

  bool isCancellationRequested(String conversationId) {
    return _entries[conversationId]?.isCancellationRequested ?? false;
  }

  void requestStop(String conversationId) {
    _entries
        .putIfAbsent(
          conversationId,
          _AgentCancellationEntry.new,
        )
        .requestStop();
  }

  void clear(String conversationId) {
    _entries.remove(conversationId);
  }

  void registerStreamSubscription<T>(
    String conversationId,
    StreamSubscription<T> subscription,
  ) {
    registerCleanup(
      conversationId,
      subscription.cancel,
    );
  }

  void registerCancelableOperation<T>(
    String conversationId,
    CancelableOperation<T> operation,
  ) {
    registerCleanup(
      conversationId,
      operation.cancel,
    );
  }

  void registerCleanup(
    String conversationId,
    FutureOr<void> Function() cleanup,
  ) {
    _entries
        .putIfAbsent(
          conversationId,
          _AgentCancellationEntry.new,
        )
        .registerCleanup(cleanup);
  }
}

class _AgentCancellationEntry {
  final _cleanupCallbacks = <FutureOr<void> Function()>[];
  bool _isCancellationRequested = false;

  bool get isCancellationRequested => _isCancellationRequested;

  void requestStop() {
    if (_isCancellationRequested) return;

    _isCancellationRequested = true;
    for (final cleanup in List.of(_cleanupCallbacks)) {
      final result = cleanup();
      if (result is Future<void>) {
        unawaited(result);
      }
    }
  }

  void registerCleanup(FutureOr<void> Function() cleanup) {
    _cleanupCallbacks.add(cleanup);
    if (!_isCancellationRequested) return;

    final result = cleanup();
    if (result is Future<void>) {
      unawaited(result);
    }
  }
}

final agentCancellationRuntimeProvider = Provider<AgentCancellationRuntime>((
  ref,
) {
  return AgentCancellationRuntime();
});
