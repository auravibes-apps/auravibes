import 'dart:async';

import 'package:async/async.dart';
import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:riverpod/riverpod.dart';

extension AgentCancellationRuntimeSubscriptions on AgentCancellationRuntime {
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
}

final agentCancellationRuntimeProvider = Provider<AgentCancellationRuntime>((
  ref,
) {
  return AgentCancellationRuntime();
});

abstract interface class ActiveSubAgentController
    implements ActiveSubAgentTracker {
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
  void start({required String parentId, required String childId}) {
    _completionByChildId[childId] = Completer<SubAgentCompletionStatus>();
    state = {
      ...state,
      parentId: {...state[parentId] ?? const <String>{}, childId},
    };
  }

  @override
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

  @override
  Future<SubAgentCompletionStatus> waitForCompletion(String childId) {
    if (_stoppedChildIds.remove(childId)) {
      return Future<SubAgentCompletionStatus>.value(
        SubAgentCompletionStatus.stopped,
      );
    }

    return _completionByChildId[childId]?.future ??
        Future<SubAgentCompletionStatus>.value(SubAgentCompletionStatus.done);
  }

  @override
  bool isStopped(String childId) => _stoppedChildIds.contains(childId);
}

final activeSubAgentRuntimeProvider =
    NotifierProvider<ActiveSubAgentRuntime, Map<String, Set<String>>>(
      ActiveSubAgentRuntime.new,
    );
