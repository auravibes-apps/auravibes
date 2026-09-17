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
      unawaited(_completeScope(scope));
    }
    final _ = _pendingStops.remove(conversationId);
  }

  Future<void> _completeScope(AgentCancellationScope scope) async {
    await scope.waitForCleanupCompletion();
    final conversationId = _conversationByScope.remove(scope);
    if (conversationId == null) return;
    final completion = _completionByConversationId[conversationId];
    if (completion == null || completion.isCompleted) return;
    if (identical(_entries[conversationId], scope)) return;
    final _ = _completionByConversationId.remove(conversationId);
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
    _completionByConversationId[conversationId] ??= Completer<void>();
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
    previous.requestStop();
    unawaited(_completeScope(previous));
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

typedef _SubAgentCompletionRequest = ({
  String parentId,
  String childId,
  SubAgentCompletionStatus status,
  Object? error,
  StackTrace? stackTrace,
});

class ActiveSubAgentRuntime extends Notifier<Map<String, Set<String>>>
    implements ActiveSubAgentController {
  final _completionByChildId = <String, Completer<SubAgentCompletionStatus>>{};
  final _stoppedChildIds = <String>{};
  final _failureByChildId = <String, SubAgentCompletionFailure>{};

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

  void finish(_SubAgentCompletionRequest request) {
    _completeChild(request);

    final children = {...state[request.parentId] ?? const <String>{}}
      ..remove(request.childId);
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

  void _completeChild(_SubAgentCompletionRequest request) {
    final completion = _completionByChildId.remove(request.childId);
    _recordSubAgentFailure(_failureByChildId, request, completion);
    _updateSubAgentStoppedState(_stoppedChildIds, request);
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
  _SubAgentCompletionRequest request,
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

void _updateSubAgentStoppedState(
  Set<String> stoppedChildIds,
  _SubAgentCompletionRequest request,
) {
  if (request.status == SubAgentCompletionStatus.stopped) {
    final _ = stoppedChildIds.add(request.childId);
  } else {
    final _ = stoppedChildIds.remove(request.childId);
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

  @override
  void finish([
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
  ]) {
    _runtime.finish((
      parentId: _parentId,
      childId: _childId,
      status: status,
      error: null,
      stackTrace: null,
    ));
  }

  void finishStopped() {
    finish(.stopped);
  }
}

final activeSubAgentRuntimeProvider =
    NotifierProvider<ActiveSubAgentRuntime, Map<String, Set<String>>>(
      ActiveSubAgentRuntime.new,
    );
