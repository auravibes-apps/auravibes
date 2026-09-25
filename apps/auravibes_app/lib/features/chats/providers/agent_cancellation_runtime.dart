import 'dart:async';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class AgentCancellationRuntime implements AgentCancellationEffects {
  final _entries = <String, AgentCancellationScope>{};
  final _completionByConversationId = <String, Completer<void>>{};
  final _conversationByScope = <AgentCancellationScope, String>{};
  final _pendingStops = <String>{};

  @override
  AgentCancellationScope start(String conversationId) =>
      _startScope(conversationId);

  @override
  AgentCancellationScope? current(String conversationId) =>
      _entries[conversationId];

  bool isCancellationRequested(String conversationId) =>
      current(conversationId)?.isCancellationRequested ?? false;

  Future<void> waitForCompletion(String conversationId) {
    return _completionByConversationId[conversationId]?.future ??
        Future<void>.value();
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
    if (_conversationByScope[scope] != conversationId) return;
    scope.close();
    if (!identical(_entries[conversationId], scope)) return;
    forceClear(conversationId);
  }

  @override
  void forceClear(String conversationId) {
    final scope = _entries.remove(conversationId);
    if (scope == null) {
      if (!_conversationByScope.values.contains(conversationId)) {
        _complete(conversationId);
      }
    } else {
      scope.requestStop();
      scope.close();
      unawaited(
        _completeScope(scope, _completionByConversationId[conversationId]),
      );
    }
    final _ = _pendingStops.remove(conversationId);
  }

  Future<void> _completeScope(
    AgentCancellationScope scope,
    Completer<void>? completion,
  ) async {
    try {
      await scope.waitForCleanupCompletion().timeout(
        const Duration(seconds: 5),
      );
    } on Object {
      // Cleanup failure or timeout must not strand completion waiters.
    }
    final conversationId = _conversationByScope.remove(scope);
    if (conversationId == null ||
        completion == null ||
        completion.isCompleted) {
      return;
    }
    if (identical(_entries[conversationId], scope)) return;
    if (identical(_completionByConversationId[conversationId], completion)) {
      final _ = _completionByConversationId.remove(conversationId);
    }
    completion.complete();
  }

  void _complete(String conversationId) {
    final completion = _completionByConversationId.remove(conversationId);
    if (completion != null && !completion.isCompleted) completion.complete();
  }
}

extension AgentCancellationRuntimeHelpers on AgentCancellationRuntime {
  AgentCancellationScope _startScope(String conversationId) {
    final scope = AgentCancellationScope();
    _replaceScope(conversationId);
    _completionByConversationId[conversationId] = Completer<void>();
    _conversationByScope[scope] = conversationId;
    _entries[conversationId] = scope;
    if (_pendingStops.remove(conversationId)) scope.requestStop();

    return scope;
  }

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

  void registerCleanup(
    String conversationId,
    FutureOr<void> Function() cleanup,
  ) {
    current(conversationId)?.registerCleanup(cleanup);
  }

  void _replaceScope(String conversationId) {
    final previous = _entries.remove(conversationId);
    if (previous == null) return;
    final completion = _completionByConversationId[conversationId];
    previous.requestStop();
    previous.close();
    unawaited(_completeScope(previous, completion));
  }
}

final agentCancellationRuntimeProvider = Provider<AgentCancellationRuntime>((
  ref,
) {
  return AgentCancellationRuntime();
});

enum ActiveSubAgentStatus {
  running,
  awaitingApproval,
  completed,
  failed,
  stopped,
}

abstract interface class ActiveSubAgentController {
  SubAgentRequestHandle start({
    required String parentId,
    required String childId,
  });

  Set<String> childrenOf(String parentId);

  String? parentOf(String childId);

  ActiveSubAgentStatus statusOf(String childId);

  void markAwaitingApproval(String childId);

  void markRunning(String childId);
}

typedef SubAgentCompletionRequest = ({
  String parentId,
  String childId,
  SubAgentCompletionStatus status,
  Object? error,
  StackTrace? stackTrace,
});

class ActiveSubAgentRuntime extends Notifier<Map<String, Set<String>>>
    implements ActiveSubAgentController {
  final _completionByChildId = <String, Completer<SubAgentCompletionStatus>>{};
  final _liveStatusByChildId = <String, ActiveSubAgentStatus>{};
  final _terminalStatusByChildId = <String, ActiveSubAgentStatus>{};
  final _failureByChildId = <String, SubAgentCompletionFailure>{};

  @override
  Map<String, Set<String>> build() => {};

  @override
  SubAgentRequestHandle start({
    required String parentId,
    required String childId,
  }) {
    _completionByChildId[childId] = Completer<SubAgentCompletionStatus>();
    _liveStatusByChildId[childId] = .running;
    final _ = _terminalStatusByChildId.remove(childId);
    final _ = _failureByChildId.remove(childId);
    state = {
      ...state,
      parentId: {...state[parentId] ?? const <String>{}, childId},
    };

    return _AppSubAgentRequestHandle(this, parentId, childId);
  }

  void finish(SubAgentCompletionRequest request) {
    final activeChildren = state[request.parentId];
    if (activeChildren == null || !activeChildren.contains(request.childId)) {
      return;
    }

    _completeChild(request);
    final children = {...activeChildren}..remove(request.childId);
    state = _stateAfterChildCompletion(request.parentId, children);
  }

  SubAgentCompletionFailure? failure(String childId) =>
      _failureByChildId[childId];

  @override
  Set<String> childrenOf(String parentId) =>
      Set.unmodifiable(state[parentId] ?? const <String>{});

  @override
  String? parentOf(String childId) {
    for (final entry in state.entries) {
      if (entry.value.contains(childId)) return entry.key;
    }

    return null;
  }

  @override
  ActiveSubAgentStatus statusOf(String childId) =>
      _liveStatusByChildId[childId] ??
      _terminalStatusByChildId[childId] ??
      .completed;

  @override
  void markAwaitingApproval(String childId) =>
      _markStatus(childId, .awaitingApproval);

  @override
  void markRunning(String childId) => _markStatus(childId, .running);

  Future<SubAgentCompletionStatus> waitForCompletion(String childId) {
    final status = _terminalStatusByChildId[childId];
    if (status == .stopped) {
      return Future<SubAgentCompletionStatus>.value(.stopped);
    }
    if (status == .failed) {
      return Future<SubAgentCompletionStatus>.value(.error);
    }

    return _completionByChildId[childId]?.future ??
        Future<SubAgentCompletionStatus>.value(.done);
  }

  bool isStopped(String childId) =>
      _terminalStatusByChildId[childId] == .stopped;

  void _markStatus(String childId, ActiveSubAgentStatus status) {
    if (parentOf(childId) == null) return;
    _liveStatusByChildId[childId] = status;
    state = {...state};
  }

  void _completeChild(SubAgentCompletionRequest request) {
    final completion = _completionByChildId.remove(request.childId);
    _recordSubAgentFailure(_failureByChildId, request, completion);
    final _ = _liveStatusByChildId.remove(request.childId);
    if (request.status == .done) {
      final _ = _terminalStatusByChildId.remove(request.childId);
    } else {
      _terminalStatusByChildId[request.childId] = request.status == .stopped
          ? .stopped
          : .failed;
    }
    if (completion != null && !completion.isCompleted) {
      completion.complete(request.status);
    }
  }

  Map<String, Set<String>> _stateAfterChildCompletion(
    String parentId,
    Set<String> children,
  ) {
    return {
      for (final entry in state.entries)
        if (entry.key != parentId) entry.key: entry.value,
      if (children.isNotEmpty) parentId: children,
    };
  }
}

void _recordSubAgentFailure(
  Map<String, SubAgentCompletionFailure> failures,
  SubAgentCompletionRequest request,
  Completer<SubAgentCompletionStatus>? completion,
) {
  final error = request.error;
  if (error != null) {
    failures[request.childId] = SubAgentCompletionFailure(
      error: error,
      stackTrace: request.stackTrace ?? StackTrace.current,
    );
  } else if (completion == null) {
    final _ = failures.remove(request.childId);
  }
}

class const _AppSubAgentRequestHandle(
  final ActiveSubAgentRuntime _runtime,
  final String _parentId,
  final String _childId,
) implements SubAgentRequestHandle {
  @override
  Future<SubAgentCompletionStatus> get completion =>
      _runtime.waitForCompletion(_childId);

  @override
  SubAgentCompletionFailure? get failure => _runtime.failure(_childId);

  @override
  bool get isStopped => _runtime.isStopped(_childId);

  void finish({
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
    SubAgentCompletionFailure? failure,
  }) {
    _runtime.finish((
      parentId: _parentId,
      childId: _childId,
      status: status,
      error: failure?.error,
      stackTrace: failure?.stackTrace,
    ));
  }
}

final activeSubAgentRuntimeProvider =
    NotifierProvider<ActiveSubAgentRuntime, Map<String, Set<String>>>(
      ActiveSubAgentRuntime.new,
    );
