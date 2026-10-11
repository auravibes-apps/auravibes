import 'dart:async';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

typedef _ToolCancellationRegistrationRequest = ({
  String conversationId,
  String toolCallId,
  bool isSupported,
  Future<void> Function() cancel,
});

typedef _ToolCancellationHandleKey = ({
  String conversationId,
  String toolCallId,
});

class AgentCancellationRuntime implements AgentCancellationEffects {
  new({@visibleForTesting this.cleanupTimeout = const Duration(seconds: 5)});

  @visibleForTesting
  final Duration cleanupTimeout;
  final _entries = <String, AgentCancellationScope>{};
  final _completionByConversationId = <String, Completer<void>>{};
  final _conversationByScope = <AgentCancellationScope, String>{};
  final _pendingStops = <String>{};
  final _toolCancellationHandles =
      <String, Map<String, AgentToolCancellationHandle>>{};
  final _toolCancellationHandleChanges =
      StreamController<_ToolCancellationHandleKey>.broadcast(sync: true);

  @override
  AgentCancellationScope start(String conversationId) =>
      _startScope(conversationId);

  @override
  AgentCancellationScope? current(String conversationId) =>
      _entries[conversationId];

  bool canRunToolInBackground({
    required String conversationId,
    required String toolCallId,
  }) {
    final handle = toolCancellationHandle(
      conversationId: conversationId,
      toolCallId: toolCallId,
    );

    return handle?.status == AgentToolCancellationStatus.running &&
        handle?.operationCompleted == false;
  }

  Stream<bool> watchCanRunToolInBackground({
    required String conversationId,
    required String toolCallId,
  }) => Stream<bool>.multi((controller) {
    bool canRun() => canRunToolInBackground(
      conversationId: conversationId,
      toolCallId: toolCallId,
    );

    final subscription = _toolCancellationHandleChanges.stream.listen((key) {
      if (key.conversationId == conversationId &&
          key.toolCallId == toolCallId) {
        controller.add(canRun());
      }
    });
    controller
      ..addSync(canRun())
      ..onCancel = subscription.cancel;
  });

  void dispose() => _toolCancellationHandleChanges.close();

  @override
  void requestStop(String conversationId) {
    _entries[conversationId]?.requestStop();
  }

  @override
  void requestStopOnStart(String conversationId) {
    final scope = _entries[conversationId];
    if (scope == null) {
      final _ = _pendingStops.add(conversationId);
      final _ = _completionByConversationId.putIfAbsent(
        conversationId,
        Completer<void>.new,
      );

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
        _completeConversation(this, conversationId);
      }
    } else {
      scope
        ..requestStop()
        ..close();
      unawaited(
        _completeScope(
          this,
          scope,
          _completionByConversationId[conversationId],
        ),
      );
    }
    final _ = _pendingStops.remove(conversationId);
  }

  void _notifyToolCancellationHandleChanged(
    String conversationId,
    String toolCallId,
  ) {
    if (_toolCancellationHandleChanges.isClosed) return;
    _toolCancellationHandleChanges.add((
      conversationId: conversationId,
      toolCallId: toolCallId,
    ));
  }
}

Future<void> _observeToolOperationResult(
  AgentToolCancellationHandle handle,
  Future<Object?> operation,
) async {
  try {
    final _ = await operation;
  } on Object {
    handle.markOperationCompleted();

    return;
  }
  handle.markOperationCompleted();
}

enum AgentToolCancellationStatus {
  running,
  unsupported,
  detached,
  cancellationRequested,
  cancellationConfirmed,
  completed,
}

class AgentToolCancellationHandle {
  new({
    required this.toolCallId,
    required bool isSupported,
    required this._cancel,
    required this.operationResult,
    this._onChanged,
  }) : _isSupported = isSupported,
       _status = isSupported
           ? AgentToolCancellationStatus.running
           : AgentToolCancellationStatus.unsupported {
    unawaited(_observeToolOperationResult(this, operationResult));
  }

  final String toolCallId;
  final Future<Object?> operationResult;
  final Future<void> Function() _cancel;
  final void Function()? _onChanged;
  final bool _isSupported;
  AgentCancellationCleanupRegistration? _cleanupRegistration;
  AgentToolCancellationStatus _status;
  Future<void>? _cancellation;
  String? _backgroundWorkId;
  final _detachedCompleter = Completer<String>();
  bool _operationCompleted = false;
  bool _cancellationWasConfirmed = false;

  AgentToolCancellationStatus get status => _status;
  Future<String> get detached => _detachedCompleter.future;
  String? get backgroundWorkId => _backgroundWorkId;
  bool get operationCompleted => _operationCompleted;
  bool get cancellationWasConfirmed => _cancellationWasConfirmed;

  bool tryDetach({required String workId}) {
    if (!_isSupported ||
        _operationCompleted ||
        _status != AgentToolCancellationStatus.running) {
      return false;
    }
    final registration = _cleanupRegistration;
    if (registration == null || !registration.remove()) return false;
    _cleanupRegistration = null;
    _backgroundWorkId = workId;
    _status = .detached;
    _detachedCompleter.complete(workId);
    _onChanged?.call();

    return true;
  }

  void markOperationCompleted() {
    _operationCompleted = true;
    _status = .completed;
    _onChanged?.call();
  }

  Future<bool> requestCancellation() async {
    if (!_isSupported || _operationCompleted) {
      return false;
    }
    final existing = _cancellation;
    if (existing != null) {
      await existing;

      return _cancellationWasConfirmed;
    }

    _status = .cancellationRequested;
    _onChanged?.call();
    final cancellation = _cancelToolOnce(this);
    _cancellation = cancellation;
    await cancellation;

    return _cancellationWasConfirmed;
  }
}

void _markToolCancellationCompleted(AgentToolCancellationHandle handle) {
  handle.markOperationCompleted();
}

Future<void> _cancelToolOnce(AgentToolCancellationHandle handle) async {
  await handle._cancel();
  if (!handle._operationCompleted) {
    handle
      .._cancellationWasConfirmed = true
      .._status = .cancellationConfirmed;
  }
  handle._onChanged?.call();
}

extension AgentCancellationRuntimeHelpers on AgentCancellationRuntime {
  Future<void> waitForCompletion(String conversationId) =>
      _completionByConversationId[conversationId]?.future ??
      Future<void>.value();

  AgentToolCancellationHandle registerToolCancellationHandle(
    _ToolCancellationRegistrationRequest request, {
    required Future<Object?> operationResult,
  }) => _registerToolCancellationHandle(this, request, operationResult);

  AgentToolCancellationHandle? toolCancellationHandle({
    required String conversationId,
    required String toolCallId,
  }) => _toolCancellationHandles[conversationId]?[toolCallId];

  bool detachToolCall({
    required String conversationId,
    required String toolCallId,
    required String workId,
  }) =>
      toolCancellationHandle(
        conversationId: conversationId,
        toolCallId: toolCallId,
      )?.tryDetach(workId: workId) ??
      false;

  void completeToolCancellationHandle({
    required String conversationId,
    required String toolCallId,
    required AgentToolCancellationHandle handle,
  }) {
    if (handle.backgroundWorkId != null && !handle.operationCompleted) return;
    _markToolCancellationCompleted(handle);
    final handles = _toolCancellationHandles[conversationId];
    if (handles == null || !identical(handles[toolCallId], handle)) return;
    final _ = handles.remove(toolCallId);
    if (handles.isEmpty) {
      final _ = _toolCancellationHandles.remove(conversationId);
    }
    _notifyToolCancellationHandleChanged(conversationId, toolCallId);
  }

  bool isCancellationRequested(String conversationId) =>
      current(conversationId)?.isCancellationRequested ?? false;

  AgentCancellationScope _startScope(String conversationId) {
    final scope = AgentCancellationScope();
    _replaceScope(conversationId);
    final _ = _completionByConversationId.putIfAbsent(
      conversationId,
      Completer<void>.new,
    );
    _conversationByScope[scope] = conversationId;
    _entries[conversationId] = scope;
    if (_pendingStops.remove(conversationId)) scope.requestStop();

    return scope;
  }

  void registerStreamSubscription<T>(
    String conversationId,
    StreamSubscription<T> subscription,
  ) {
    final _ = current(conversationId)?.registerCleanup(subscription.cancel);
  }

  void registerCancelableOperation<T>(
    String conversationId,
    CancelableOperation<T> operation,
  ) {
    final _ = current(conversationId)?.registerCleanup(operation.cancel);
  }

  void registerCleanup(
    String conversationId,
    FutureOr<void> Function() cleanup,
  ) {
    final _ = current(conversationId)?.registerCleanup(cleanup);
  }

  void _replaceScope(String conversationId) {
    final previous = _entries.remove(conversationId);
    if (previous == null) return;
    final completion = _completionByConversationId[conversationId];
    previous
      ..requestStop()
      ..close();
    unawaited(_completeScope(this, previous, completion));
    _completionByConversationId[conversationId] = Completer<void>();
  }
}

AgentToolCancellationHandle _registerToolCancellationHandle(
  AgentCancellationRuntime runtime,
  _ToolCancellationRegistrationRequest request,
  Future<Object?> operationResult,
) {
  final handle = _newToolCancellationHandle(runtime, request, operationResult);
  _storeToolCancellationHandle(runtime, request, handle);
  _registerToolCancellationCleanup(runtime, request, handle);
  runtime._notifyToolCancellationHandleChanged(
    request.conversationId,
    request.toolCallId,
  );

  return handle;
}

AgentToolCancellationHandle _newToolCancellationHandle(
  AgentCancellationRuntime runtime,
  _ToolCancellationRegistrationRequest request,
  Future<Object?> operationResult,
) => AgentToolCancellationHandle(
  toolCallId: request.toolCallId,
  isSupported: request.isSupported,
  cancel: request.cancel,
  operationResult: operationResult,
  onChanged: () => runtime._notifyToolCancellationHandleChanged(
    request.conversationId,
    request.toolCallId,
  ),
);

void _storeToolCancellationHandle(
  AgentCancellationRuntime runtime,
  _ToolCancellationRegistrationRequest request,
  AgentToolCancellationHandle handle,
) {
  final handles = runtime._toolCancellationHandles.putIfAbsent(
    request.conversationId,
    () => <String, AgentToolCancellationHandle>{},
  );
  handles[request.toolCallId] = handle;
}

void _registerToolCancellationCleanup(
  AgentCancellationRuntime runtime,
  _ToolCancellationRegistrationRequest request,
  AgentToolCancellationHandle handle,
) {
  handle._cleanupRegistration = runtime
      .current(request.conversationId)
      ?.registerCleanup(() async {
        final _ = await handle.requestCancellation();
      });
}

Future<void> _completeScope(
  AgentCancellationRuntime runtime,
  AgentCancellationScope scope,
  Completer<void>? completion,
) async {
  await _waitForScopeCleanup(scope, runtime.cleanupTimeout);
  _completeScopeCompletion(runtime, scope, completion);
}

void _completeScopeCompletion(
  AgentCancellationRuntime runtime,
  AgentCancellationScope scope,
  Completer<void>? completion,
) {
  final conversationId = runtime._conversationByScope.remove(scope);
  if (conversationId == null || completion == null || completion.isCompleted) {
    return;
  }
  if (identical(runtime._entries[conversationId], scope)) return;
  _removeScopeCompletion(runtime, conversationId, completion);
  completion.complete();
}

void _removeScopeCompletion(
  AgentCancellationRuntime runtime,
  String conversationId,
  Completer<void> completion,
) {
  final currentCompletion = runtime._completionByConversationId[conversationId];
  if (identical(currentCompletion, completion)) {
    final _ = runtime._completionByConversationId.remove(conversationId);
  }
}

void _completeConversation(
  AgentCancellationRuntime runtime,
  String conversationId,
) {
  final completion = runtime._completionByConversationId.remove(conversationId);
  if (completion != null && !completion.isCompleted) completion.complete();
}

Future<void> _waitForScopeCleanup(
  AgentCancellationScope scope,
  Duration timeout,
) async {
  try {
    await scope.waitForCleanupCompletion().timeout(timeout);
  } on Object {
    // Cleanup failure or timeout must not strand completion waiters.
  }
}

final agentCancellationRuntimeProvider = Provider<AgentCancellationRuntime>((
  ref,
) {
  final runtime = AgentCancellationRuntime();
  final _ = ref.onDispose(runtime.dispose);

  return runtime;
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
