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
      scope
        ..requestStop()
        ..close();
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
    await _waitForScopeCleanup(scope);
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
    previous
      ..requestStop()
      ..close();
    unawaited(_completeScope(previous, completion));
  }
}

Future<void> _waitForScopeCleanup(AgentCancellationScope scope) async {
  try {
    await scope.waitForCleanupCompletion().timeout(const Duration(seconds: 5));
  } on Object {
    // Cleanup failure or timeout must not strand completion waiters.
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

  _ActiveSubAgentRuntimeMaps get _maps => (
    completions: _completionByChildId,
    liveStatuses: _liveStatusByChildId,
    terminalStatuses: _terminalStatusByChildId,
    failures: _failureByChildId,
  );

  @override
  Map<String, Set<String>> build() => {};

  @override
  SubAgentRequestHandle start({
    required String parentId,
    required String childId,
  }) {
    final completion = _registerSubAgentStart(childId, _maps);
    state = {
      ...state,
      parentId: {...state[parentId] ?? const <String>{}, childId},
    };

    return _AppSubAgentRequestHandle(
      this,
      parentId,
      childId,
      completion.future,
    );
  }

  void finish(SubAgentCompletionRequest request) {
    final activeChildren = state[request.parentId];
    if (activeChildren == null || !activeChildren.contains(request.childId)) {
      return;
    }

    _completeSubAgentChild(request, _maps);
    state = _stateAfterChildCompletion(
      state,
      request.parentId,
      {...activeChildren}..remove(request.childId),
    );
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
      state = _stateAfterMarkingSubAgentStatus(
        state,
        _liveStatusByChildId,
        childId,
        .awaitingApproval,
      );

  @override
  void markRunning(String childId) => state = _stateAfterMarkingSubAgentStatus(
    state,
    _liveStatusByChildId,
    childId,
    .running,
  );
}

typedef _ActiveSubAgentRuntimeMaps = ({
  Map<String, Completer<SubAgentCompletionStatus>> completions,
  Map<String, ActiveSubAgentStatus> liveStatuses,
  Map<String, ActiveSubAgentStatus> terminalStatuses,
  Map<String, SubAgentCompletionFailure> failures,
});

Completer<SubAgentCompletionStatus> _registerSubAgentStart(
  String childId,
  _ActiveSubAgentRuntimeMaps maps,
) {
  final completion = Completer<SubAgentCompletionStatus>();
  maps.completions[childId] = completion;
  maps.liveStatuses[childId] = .running;
  final _ = maps.terminalStatuses.remove(childId);
  final _ = maps.failures.remove(childId);

  return completion;
}

void _completeSubAgentChild(
  SubAgentCompletionRequest request,
  _ActiveSubAgentRuntimeMaps maps,
) {
  final completion = maps.completions.remove(request.childId);
  _recordSubAgentFailure(maps.failures, request, completion);
  _recordSubAgentStatus(maps, request);
  _completeSubAgentWaiter(completion, request.status);
}

void _recordSubAgentStatus(
  _ActiveSubAgentRuntimeMaps maps,
  SubAgentCompletionRequest request,
) {
  final childId = request.childId;
  final _ = maps.liveStatuses.remove(childId);
  if (request.status == .done) {
    final _ = maps.terminalStatuses.remove(childId);
  } else {
    maps.terminalStatuses[childId] = request.status == .stopped
        ? .stopped
        : .failed;
  }
}

void _completeSubAgentWaiter(
  Completer<SubAgentCompletionStatus>? completion,
  SubAgentCompletionStatus status,
) {
  if (completion != null && !completion.isCompleted) {
    completion.complete(status);
  }
}

Map<String, Set<String>> _stateAfterChildCompletion(
  Map<String, Set<String>> currentState,
  String parentId,
  Set<String> children,
) => {
  for (final entry in currentState.entries)
    if (entry.key != parentId) entry.key: entry.value,
  if (children.isNotEmpty) parentId: children,
};

Map<String, Set<String>> _stateAfterMarkingSubAgentStatus(
  Map<String, Set<String>> currentState,
  Map<String, ActiveSubAgentStatus> liveStatuses,
  String childId,
  ActiveSubAgentStatus status,
) {
  if (!currentState.values.any((children) => children.contains(childId))) {
    return currentState;
  }

  liveStatuses[childId] = status;

  return {...currentState};
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
  final Future<SubAgentCompletionStatus> _completion,
) implements SubAgentRequestHandle {
  @override
  Future<SubAgentCompletionStatus> get completion => _completion;

  @override
  SubAgentCompletionFailure? get failure => _runtime.failure(_childId);

  @override
  bool get isStopped => _runtime.statusOf(_childId) == .stopped;

  @override
  void finish({
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
    SubAgentCompletionFailure? failure,
  }) {
    if (failure != null) {
      finishWithFailure(status: status, failure: failure);

      return;
    }

    _finish(status: status);
  }

  void finishWithFailure({
    required SubAgentCompletionStatus status,
    required SubAgentCompletionFailure failure,
  }) => _finish(status: status == .done ? .error : status, failure: failure);

  void _finish({
    required SubAgentCompletionStatus status,
    SubAgentCompletionFailure? failure,
  }) => _runtime.finish((
    parentId: _parentId,
    childId: _childId,
    status: status,
    error: failure?.error,
    stackTrace: failure?.stackTrace,
  ));
}

final activeSubAgentRuntimeProvider =
    NotifierProvider<ActiveSubAgentRuntime, Map<String, Set<String>>>(
      ActiveSubAgentRuntime.new,
    );
