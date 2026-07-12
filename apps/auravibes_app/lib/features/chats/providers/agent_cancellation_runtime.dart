import 'dart:async';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

extension AgentCancellationRuntimeSubscriptions on AgentCancellationRuntime {
  void registerStreamSubscription<T>(
    String conversationId,
    StreamSubscription<T> subscription,
  ) {
    current(conversationId)?.registerCleanup(subscription.cancel);
  }

  void registerCancelableOperation<T>(
    String conversationId,
    CancelableOperation<T> operation,
  ) {
    current(conversationId)?.registerCleanup(operation.cancel);
  }
}

class AgentCancellationRuntime implements AgentCancellationEffects {
  final _entries = <String, AgentCancellationScope>{};
  final _pendingStops = <String>{};

  @override
  AgentCancellationScope start(String conversationId) {
    final scope = AgentCancellationScope();
    if (_pendingStops.remove(conversationId)) scope.requestStop();
    _entries.remove(conversationId)?.requestStop();
    _entries[conversationId] = scope;

    return scope;
  }

  @override
  AgentCancellationScope? current(String conversationId) =>
      _entries[conversationId];

  bool isCancellationRequested(String conversationId) =>
      current(conversationId)?.isCancellationRequested ?? false;

  void registerCleanup(
    String conversationId,
    FutureOr<void> Function() cleanup,
  ) {
    current(conversationId)?.registerCleanup(cleanup);
  }

  @override
  void requestStop(String conversationId) {
    _entries[conversationId]?.requestStop();
  }

  @override
  void requestStopOnStart(String conversationId) {
    final scope = _entries[conversationId];
    if (scope == null) {
      final _ = _pendingStops.add(conversationId);

      return;
    }
    scope.requestStop();
  }

  @override
  void clear(String conversationId, AgentCancellationScope scope) {
    if (!identical(_entries[conversationId], scope)) return;
    _clear(conversationId);
  }

  @override
  void forceClear(String conversationId) => _clear(conversationId);

  void _clear(String conversationId) {
    _entries.remove(conversationId)?.requestStop();
    final _ = _pendingStops.remove(conversationId);
  }
}

final agentCancellationRuntimeProvider = Provider<AgentCancellationRuntime>((
  ref,
) {
  return AgentCancellationRuntime();
});

abstract interface class ActiveSubAgentController {
  SubAgentRequestHandle start({
    required String parentId,
    required String childId,
  });

  Set<String> childrenOf(String parentId);

  String? parentOf(String childId);
}

class ActiveSubAgentRuntime extends Notifier<Map<String, Set<String>>>
    implements ActiveSubAgentController {
  final _completionByChildId = <String, Completer<SubAgentCompletionStatus>>{};
  final _stoppedChildIds = <String>{};

  @override
  Map<String, Set<String>> build() => {};

  @override
  SubAgentRequestHandle start({
    required String parentId,
    required String childId,
  }) {
    _completionByChildId[childId] = Completer<SubAgentCompletionStatus>();
    state = {
      ...state,
      parentId: {...state[parentId] ?? const <String>{}, childId},
    };

    return _AppSubAgentRequestHandle(this, parentId, childId);
  }

  void finish({
    required String parentId,
    required String childId,
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
  }) {
    final completion = _completionByChildId.remove(childId);
    if (status == SubAgentCompletionStatus.stopped) {
      final _ = _stoppedChildIds.add(childId);
    } else {
      final _ = _stoppedChildIds.remove(childId);
    }
    if (completion != null && !completion.isCompleted) {
      completion.complete(status);
    }

    final children = {...state[parentId] ?? const <String>{}}..remove(childId);
    state = {
      for (final entry in state.entries)
        if (entry.key != parentId) entry.key: entry.value,
      if (children.isNotEmpty) parentId: children,
    };
  }

  @override
  Set<String> childrenOf(String parentId) => Set.unmodifiable(
    state[parentId] ?? const <String>{},
  );

  @override
  String? parentOf(String childId) {
    for (final entry in state.entries) {
      if (entry.value.contains(childId)) return entry.key;
    }

    return null;
  }

  Future<SubAgentCompletionStatus> waitForCompletion(String childId) {
    if (_stoppedChildIds.remove(childId)) {
      return Future<SubAgentCompletionStatus>.value(
        SubAgentCompletionStatus.stopped,
      );
    }

    return _completionByChildId[childId]?.future ??
        Future<SubAgentCompletionStatus>.value(SubAgentCompletionStatus.done);
  }

  bool isStopped(String childId) => _stoppedChildIds.contains(childId);
}

class _AppSubAgentRequestHandle implements SubAgentRequestHandle {
  const _AppSubAgentRequestHandle(this._runtime, this._parentId, this._childId);

  final ActiveSubAgentRuntime _runtime;
  final String _parentId;
  final String _childId;

  @override
  Future<SubAgentCompletionStatus> get completion =>
      _runtime.waitForCompletion(_childId);

  @override
  bool get isStopped => _runtime.isStopped(_childId);

  @override
  void finish([
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
  ]) {
    _runtime.finish(parentId: _parentId, childId: _childId, status: status);
  }
}

final activeSubAgentRuntimeProvider =
    NotifierProvider<ActiveSubAgentRuntime, Map<String, Set<String>>>(
      ActiveSubAgentRuntime.new,
    );
