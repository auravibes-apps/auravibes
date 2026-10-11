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
      <String, Map<String, AgentToolCancellationHandle>>{};

  Future<AgentBackgroundWork?> runInBackground(
    BackgroundWorkDetachRequest request,
  ) async {
    final operation = _findDetachableOperation(request);
    if (operation == null) return null;

    final workspaceId = await _resolveWorkspaceId(request.conversationId);
    if (workspaceId == null) return null;

    return await _persistAndTransfer(request, operation, workspaceId);
  }

  Future<bool> requestStop({
    required String conversationId,
    required String workId,
  }) async {
    final handle = _handlesByConversation[conversationId]?[workId];
    if (handle == null) return false;
    final requested = await _store.requestStop(
      conversationId: conversationId,
      workId: workId,
    );
    if (!requested) return false;

    try {
      return await handle.requestCancellation();
    } on Object {
      return false;
    }
  }
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
        handle.operationCompleted) {
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
            {})[provisional.identity.id] =
        operation.handle;
    unawaited(
      _recordCompletion(
        request.conversationId,
        provisional.identity.id,
        operation.handle,
        operation.result,
      ),
    );
  }
}

extension _BackgroundWorkCompletionOps on BackgroundWorkCoordinator {
  Future<void> _recordCompletion(
    String conversationId,
    String workId,
    AgentToolCancellationHandle handle,
    Future<Object?> operationResult,
  ) async {
    final details = await _captureCompletion(handle, operationResult);
    try {
      final _ = await _store.finish(
        .new(
          conversationId: conversationId,
          workId: workId,
          status: details.status,
          resultContent: details.resultContent,
          resultByteLength: details.resultByteLength,
          statusPreview: details.statusPreview,
          errorCode: details.errorCode,
        ),
      );
    } finally {
      _releaseHandle(conversationId, workId, handle);
    }
  }

  Future<_CompletionDetails> _captureCompletion(
    AgentToolCancellationHandle handle,
    Future<Object?> operationResult,
  ) async {
    try {
      final result = await operationResult;
      final cancelled = await _wasCancellationConfirmed(handle);

      return _successfulCompletion(result, cancelled);
    } on Object {
      return _failedCompletion(await _wasCancellationConfirmed(handle));
    }
  }

  Future<bool> _wasCancellationConfirmed(
    AgentToolCancellationHandle handle,
  ) async {
    final cancellation = handle.cancellationCompletion;

    return cancellation == null
        ? handle.cancellationWasConfirmed
        : await cancellation;
  }

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
