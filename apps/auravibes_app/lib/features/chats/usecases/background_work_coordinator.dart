import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/background_work_detach_request.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:uuid/v7.dart';

typedef BackgroundWorkWorkspaceResolver = Future<String?> Function(
  String conversationId,
);

typedef _DetachableOperation = ({
  AgentToolCancellationHandle handle,
  Future<Object?> result,
});

typedef _TrackedBackgroundWork = ({
  String workspaceId,
  AgentToolCancellationHandle handle,
});

typedef _WorkspaceStopRequest = ({
  String conversationId,
  String workId,
  AgentToolCancellationHandle handle,
});

typedef _BackgroundWorkCompletionRequest = ({
  String conversationId,
  String workspaceId,
  String workId,
  AgentToolCancellationHandle handle,
});

typedef _CompletionDetails = ({
  AgentBackgroundWorkStatus status,
  String? resultContent,
  int resultByteLength,
  String statusPreview,
  String? errorCode,
});

/// Transfers a running tool invocation from turn cleanup to durable work.
class BackgroundWorkCoordinator(
  final AgentBackgroundWorkStore _store,
  final AgentCancellationRuntime _cancellationRuntime,
  final BackgroundWorkWorkspaceResolver _resolveWorkspaceId,
) {
  final _handlesByConversation =
      <String, Map<String, _TrackedBackgroundWork>>{};
  final _closingConversations = <String>{};
  final _closingWorkspaces = <String>{};

  Future<AgentBackgroundWork?> runInBackground(
    BackgroundWorkDetachRequest request,
  ) async {
    if (_closingConversations.contains(request.conversationId)) return null;
    final operation = _findDetachableOperation(request);
    if (operation == null) return null;

    final workspaceId = await _resolveWorkspaceId(request.conversationId);
    if (workspaceId == null ||
        _isClosing(request.conversationId, workspaceId)) {
      return null;
    }

    return await _persistAndTransfer(request, operation, workspaceId);
  }

  Future<bool> requestStop({
    required String conversationId,
    required String workId,
  }) async {
    final tracked = _handlesByConversation[conversationId]?[workId];
    if (tracked == null) return false;

    return await _requestStop(conversationId, workId, tracked.handle);
  }

  /// Requests cancellation before deleting a conversation and blocks new work.
  Future<void> prepareConversationDeletion(String conversationId) async {
    final _ = _closingConversations.add(conversationId);
    final tracked = _handlesByConversation[conversationId];
    if (tracked == null || tracked.isEmpty) return;
    final _ = await Future.wait([
      for (final entry in tracked.entries)
        _requestStop(conversationId, entry.key, entry.value.handle),
    ]);
  }

  /// Reopens background work if the conversation deletion did not complete.
  void restoreConversationAfterFailedDeletion(String conversationId) {
    final _ = _closingConversations.remove(conversationId);
  }

  /// Requests cancellation before deleting a workspace and blocks new work.
  Future<void> prepareWorkspaceDeletion(String workspaceId) async {
    final _ = _closingWorkspaces.add(workspaceId);
    await _requestWorkspaceStops(workspaceId);
  }

  /// Reopens background work if the workspace deletion did not complete.
  void restoreWorkspaceAfterFailedDeletion(String workspaceId) {
    final _ = _closingWorkspaces.remove(workspaceId);
  }

  Future<bool> _requestStop(
    String conversationId,
    String workId,
    AgentToolCancellationHandle handle,
  ) async {
    final requested = await _store.requestStop(
      conversationId: conversationId,
      workId: workId,
    );
    if (!requested) return false;

    try {
      return await _cancellationRuntime.requestToolCancellation(handle);
    } on Object {
      return false;
    }
  }

  bool _isClosing(String conversationId, String workspaceId) =>
      _closingConversations.contains(conversationId) ||
      _closingWorkspaces.contains(workspaceId);
}

extension _BackgroundWorkWorkspaceDeletionOps on BackgroundWorkCoordinator {
  Future<void> _requestWorkspaceStops(String workspaceId) async {
    final requests = _workspaceStopRequests(workspaceId);
    if (requests.isEmpty) return;
    final _ = await Future.wait(requests.map(_requestTrackedStop));
  }

  List<_WorkspaceStopRequest> _workspaceStopRequests(String workspaceId) => [
    for (final conversationEntry in _handlesByConversation.entries)
      for (final workEntry in conversationEntry.value.entries)
        if (workEntry.value.workspaceId == workspaceId)
          (
            conversationId: conversationEntry.key,
            workId: workEntry.key,
            handle: workEntry.value.handle,
          ),
  ];

  Future<bool> _requestTrackedStop(_WorkspaceStopRequest request) =>
      _requestStop(request.conversationId, request.workId, request.handle);
}

extension _BackgroundWorkLookupOps on BackgroundWorkCoordinator {
  _DetachableOperation? _findDetachableOperation(
    BackgroundWorkDetachRequest request,
  ) {
    final handle = _cancellationRuntime.toolCancellationHandle(
      conversationId: request.conversationId,
      toolCallId: request.toolCallId,
    );
    if (handle == null ||
        handle.status != AgentToolCancellationStatus.running ||
        handle.isOperationCompleted()) {
      return null;
    }
    final result = handle.operationResult;
    if (result == null) return null;

    return (handle: handle, result: result);
  }
}

extension _BackgroundWorkTransferOps on BackgroundWorkCoordinator {
  Future<AgentBackgroundWork?> _persistAndTransfer(
    BackgroundWorkDetachRequest request,
    _DetachableOperation operation,
    String workspaceId,
  ) async {
    final provisional = await _createProvisional(request, workspaceId);
    if (_isClosing(request.conversationId, workspaceId)) {
      await _discardProvisional(request, provisional);

      return null;
    }
    if (!_transferCleanup(request, provisional)) {
      await _discardProvisional(request, provisional);

      return null;
    }
    _trackCompletion(request, provisional, operation);

    return provisional;
  }

  Future<AgentBackgroundWork> _createProvisional(
    BackgroundWorkDetachRequest request,
    String workspaceId,
  ) => _store.create(
    .new(
      id: const UuidV7().generate(),
      workspaceId: workspaceId,
      conversationId: request.conversationId,
      toolCallId: request.toolCallId,
      toolKind: request.toolKind,
      originatingMessageId: request.originatingMessageId,
    ),
  );

  bool _transferCleanup(
    BackgroundWorkDetachRequest request,
    AgentBackgroundWork provisional,
  ) => _cancellationRuntime.detachToolCall(
    conversationId: request.conversationId,
    toolCallId: request.toolCallId,
    workId: provisional.identity.id,
  );

  Future<void> _discardProvisional(
    BackgroundWorkDetachRequest request,
    AgentBackgroundWork provisional,
  ) => _store.discard(
    conversationId: request.conversationId,
    workId: provisional.identity.id,
  );

  void _trackCompletion(
    BackgroundWorkDetachRequest request,
    AgentBackgroundWork provisional,
    _DetachableOperation operation,
  ) {
    (_handlesByConversation[request.conversationId] ??=
        {})[provisional.identity.id] = (
      workspaceId: provisional.identity.workspaceId,
      handle: operation.handle,
    );
    final completionRequest = (
      conversationId: request.conversationId,
      workspaceId: provisional.identity.workspaceId,
      workId: provisional.identity.id,
      handle: operation.handle,
    );
    unawaited(_recordCompletion(completionRequest, operation.result));
  }
}

extension _BackgroundWorkCompletionOps on BackgroundWorkCoordinator {
  Future<void> _recordCompletion(
    _BackgroundWorkCompletionRequest request,
    Future<Object?> operationResult,
  ) async {
    final details = await _captureCompletion(
      request.conversationId,
      request.workspaceId,
      request.handle,
      operationResult,
    );
    try {
      await _persistCompletion(request, details);
    } finally {
      _releaseHandle(request.conversationId, request.workId, request.handle);
    }
  }

  Future<void> _persistCompletion(
    _BackgroundWorkCompletionRequest request,
    _CompletionDetails details,
  ) async {
    final _ = await _store.finish(
      .new(
        conversationId: request.conversationId,
        workId: request.workId,
        status: details.status,
        resultContent: details.resultContent,
        resultByteLength: details.resultByteLength,
        statusPreview: details.statusPreview,
        errorCode: details.errorCode,
      ),
    );
  }

  Future<_CompletionDetails> _captureCompletion(
    String conversationId,
    String workspaceId,
    AgentToolCancellationHandle handle,
    Future<Object?> operationResult,
  ) async {
    try {
      final result = await operationResult;
      final cancelled = await _wasCancellationConfirmed(handle);
      if (cancelled) return _successfulCompletion(result, true);
      if (_isClosing(conversationId, workspaceId)) {
        return _unknownOutcomeCompletion();
      }

      return _successfulCompletion(result, false);
    } on Object {
      final cancelled = await _wasCancellationConfirmed(handle);
      if (cancelled) return _failedCompletion(true);
      if (_isClosing(conversationId, workspaceId)) {
        return _unknownOutcomeCompletion();
      }

      return _failedCompletion(false);
    }
  }

  Future<bool> _wasCancellationConfirmed(AgentToolCancellationHandle handle) =>
      _cancellationRuntime.waitForToolCancellationConfirmation(handle);

  _CompletionDetails _successfulCompletion(Object? result, bool cancelled) {
    if (cancelled) {
      return (
        status: AgentBackgroundWorkStatus.cancelled,
        resultContent: null,
        resultByteLength: 0,
        statusPreview: 'Stopped',
        errorCode: null,
      );
    }
    final resultContent = jsonEncode(result);

    return (
      status: AgentBackgroundWorkStatus.completed,
      resultContent: resultContent,
      resultByteLength: utf8.encode(resultContent).length,
      statusPreview: 'Completed',
      errorCode: null,
    );
  }

  _CompletionDetails _failedCompletion(bool cancelled) => (
    status: cancelled
        ? AgentBackgroundWorkStatus.cancelled
        : AgentBackgroundWorkStatus.failed,
    resultContent: null,
    resultByteLength: 0,
    statusPreview: cancelled ? 'Stopped' : 'Failed',
    errorCode: cancelled ? null : 'operation_failed',
  );

  _CompletionDetails _unknownOutcomeCompletion() => (
    status: AgentBackgroundWorkStatus.failed,
    resultContent: null,
    resultByteLength: 0,
    statusPreview: 'Outcome unknown',
    errorCode: 'outcome_unknown',
  );

  void _releaseHandle(
    String conversationId,
    String workId,
    AgentToolCancellationHandle handle,
  ) {
    _cancellationRuntime.completeToolCancellationHandle(
      conversationId: conversationId,
      toolCallId: handle.toolCallId,
      handle: handle,
    );
    final handles = _handlesByConversation[conversationId];
    final _ = handles?.remove(workId);
    if (handles?.isEmpty ?? false) {
      final _ = _handlesByConversation.remove(conversationId);
    }
  }
}
