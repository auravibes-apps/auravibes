import 'dart:async';

import 'package:auravibes_agent/src/agent_runtime.dart';
import 'package:auravibes_agent/src/continue_agent_result.dart';

typedef CurrentAgentMessageId = String? Function();

abstract interface class AgentChunkSink<TChunk> {
  void add(TChunk chunk);

  Future<void> close();
}

abstract interface class AgentStreamProvider<TChunk> {
  void startConversationStreaming(String conversationId);

  void removeConversationStreaming(String conversationId);

  AgentChunkSink<TChunk> createPersistenceSink(
    CurrentAgentMessageId currentMessageId,
  );

  AgentChunkSink<TChunk> createUiStreamingSink(String messageId);

  Future<String> createAssistantMessage({
    required String conversationId,
    required TChunk chunk,
  });

  Future<void> startMessageStreaming(String messageId);

  Future<void> removeMessageStreaming(String messageId);

  Future<void> markPendingUsersSent(List<String> messageIds);

  Future<void> markPendingUsersErrored(List<String> messageIds);

  Future<void> persistStoppedAssistantMessage(
    String? messageId,
    TChunk? result,
  );

  Future<void> persistCompletedAssistantMessage(
    String messageId,
    TChunk result,
  );

  Future<void> markAssistantErrored(String messageId);

  TChunk concatChunks(TChunk current, TChunk delta);

  bool shouldCreateAssistantMessage(TChunk chunk);

  bool hasToolCalls(TChunk chunk);

  void trackResponseStreamError(Object error, StackTrace stackTrace);

  void trackCancellationStreamError(Object error, StackTrace stackTrace);
}

class AgentStreamService<TChunk> {
  const AgentStreamService({
    required this.agentCancellationRuntime,
    required this.provider,
  });

  final AgentCancellationRuntime agentCancellationRuntime;
  final AgentStreamProvider<TChunk> provider;

  Future<ContinueAgentResult> call({
    required String conversationId,
    required Stream<TChunk> responseStream,
    required List<String> pendingUserMessageIds,
  }) async {
    final state = _ContinueAgentStreamState<TChunk>(
      conversationId: conversationId,
      pendingUserMessageIds: pendingUserMessageIds,
    );
    provider.startConversationStreaming(conversationId);
    state.persistenceSink = provider.createPersistenceSink(
      () => state.messageId,
    );
    try {
      _listenToResponse(state, responseStream);
      await state.responseCompleter.future;

      if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
        return _completeCancelledRun(state);
      }

      final completedMessageId = state.messageId;
      final completedResult = state.accumulatedResult;
      if (completedMessageId == null || completedResult == null) {
        throw StateError('Agent stream completed without any result');
      }

      await _closeSinks(state);
      await provider.removeMessageStreaming(completedMessageId);
      state.streamingRuntimeRemoved = true;
      await provider.persistCompletedAssistantMessage(
        completedMessageId,
        completedResult,
      );
    } on Object catch (error, stackTrace) {
      await _handleContinuationError(state, error, stackTrace);
    } finally {
      await _cleanupContinuation(state);
    }

    final messageId = state.messageId;
    final accumulatedResult = state.accumulatedResult;
    if (messageId == null || accumulatedResult == null) {
      throw StateError('Agent run completed without persisted result');
    }

    return ContinueAgentResult(
      messageId: messageId,
      hasToolCalls: provider.hasToolCalls(accumulatedResult),
    );
  }

  void _listenToResponse(
    _ContinueAgentStreamState<TChunk> state,
    Stream<TChunk> responseStream,
  ) {
    agentCancellationRuntime.registerCleanup(state.conversationId, () async {
      await state.responseSubscription?.cancel();
      await state.activeChunkProcessing;
      _completeResponse(state);
    });
    // ignore: cancel_subscriptions, cancelled by registered cleanup/finalizer.
    final subscription = responseStream.listen(
      null,
      onError: (Object error, StackTrace stackTrace) {
        provider.trackResponseStreamError(error, stackTrace);
        _handleResponseError(state, error, stackTrace);
      },
      onDone: () {
        _completeResponse(state);
      },
      cancelOnError: true,
    );
    state.responseSubscription = subscription;
    subscription.onData((chunk) {
      state.responseSubscription?.pause();
      state.activeChunkProcessing = _processResponseChunk(state, chunk);
    });
  }

  Future<void> _processResponseChunk(
    _ContinueAgentStreamState<TChunk> state,
    TChunk chunk,
  ) async {
    try {
      await _handleChunk(state, chunk);
      if (agentCancellationRuntime.isCancellationRequested(
        state.conversationId,
      )) {
        await state.responseSubscription?.cancel();
        _completeResponse(state);

        return;
      }

      state.responseSubscription?.resume();
    } on Object catch (error, stackTrace) {
      await state.responseSubscription?.cancel();
      _completeResponseError(state, error, stackTrace);
    }
  }

  Future<void> _handleChunk(
    _ContinueAgentStreamState<TChunk> state,
    TChunk chunk,
  ) async {
    if (agentCancellationRuntime.isCancellationRequested(
      state.conversationId,
    )) {
      return;
    }

    final currentResult = state.accumulatedResult == null
        ? chunk
        : provider.concatChunks(state.accumulatedResult as TChunk, chunk);
    state
      ..chunkCount += 1
      ..accumulatedResult = currentResult;

    final pendingUserMessageIds = state.pendingUserMessageIds;
    final alreadyAcknowledged = state.hasAcknowledgedPendingUsers;
    state.hasAcknowledgedPendingUsers = await _acknowledgePendingUsers(
      pendingUserMessageIds,
      alreadyAcknowledged: alreadyAcknowledged,
    );

    if (!provider.shouldCreateAssistantMessage(currentResult)) return;

    await _ensureAssistantMessage(state, currentResult);
    state.persistenceSink?.add(currentResult);
    state.uiStreamingSink?.add(currentResult);
  }

  Future<void> _ensureAssistantMessage(
    _ContinueAgentStreamState<TChunk> state,
    TChunk currentResult,
  ) async {
    if (state.messageId != null) return;

    final messageId = await provider.createAssistantMessage(
      conversationId: state.conversationId,
      chunk: currentResult,
    );
    state.messageId = messageId;
    await provider.startMessageStreaming(messageId);
    state.uiStreamingSink = provider.createUiStreamingSink(messageId);
  }

  void _handleResponseError(
    _ContinueAgentStreamState<TChunk> state,
    Object error,
    StackTrace stackTrace,
  ) {
    if (agentCancellationRuntime.isCancellationRequested(
      state.conversationId,
    )) {
      provider.trackCancellationStreamError(error, stackTrace);
      _completeResponse(state);

      return;
    }

    _completeResponseError(state, error, stackTrace);
  }

  void _completeResponse(_ContinueAgentStreamState<TChunk> state) {
    if (!state.responseCompleter.isCompleted) {
      state.responseCompleter.complete();
    }
  }

  void _completeResponseError(
    _ContinueAgentStreamState<TChunk> state,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!state.responseCompleter.isCompleted) {
      state.responseCompleter.completeError(error, stackTrace);
    }
  }

  Future<ContinueAgentResult> _completeCancelledRun(
    _ContinueAgentStreamState<TChunk> state,
  ) async {
    await _closeSinks(state);
    state.hasAcknowledgedPendingUsers = await _acknowledgePendingUsers(
      state.pendingUserMessageIds,
      alreadyAcknowledged: state.hasAcknowledgedPendingUsers,
    );
    await provider.persistStoppedAssistantMessage(
      state.messageId,
      state.accumulatedResult,
    );

    return ContinueAgentResult(
      messageId: state.messageId ?? '',
      hasToolCalls: false,
    );
  }

  Future<void> _closeSinks(_ContinueAgentStreamState<TChunk> state) async {
    await state.persistenceSink?.close();
    await state.uiStreamingSink?.close();
    state
      ..persistenceSink = null
      ..uiStreamingSink = null;
  }

  Future<Never> _handleContinuationError(
    _ContinueAgentStreamState<TChunk> state,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (!state.hasAcknowledgedPendingUsers) {
      await provider.markPendingUsersErrored(state.pendingUserMessageIds);
    }

    final messageId = state.messageId;
    if (messageId != null) {
      await _closeSinks(state);
      await provider.markAssistantErrored(messageId);
    }

    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<void> _cleanupContinuation(
    _ContinueAgentStreamState<TChunk> state,
  ) async {
    await state.responseSubscription?.cancel();
    await _closeSinks(state);
    provider.removeConversationStreaming(state.conversationId);
    final messageId = state.messageId;
    if (messageId != null && !state.streamingRuntimeRemoved) {
      await provider.removeMessageStreaming(messageId);
    }
  }

  Future<bool> _acknowledgePendingUsers(
    List<String> pendingUserMessageIds, {
    required bool alreadyAcknowledged,
  }) async {
    if (alreadyAcknowledged || pendingUserMessageIds.isEmpty) {
      return alreadyAcknowledged;
    }

    await provider.markPendingUsersSent(pendingUserMessageIds);

    return true;
  }
}

class _ContinueAgentStreamState<TChunk> {
  _ContinueAgentStreamState({
    required this.conversationId,
    required this.pendingUserMessageIds,
  });

  final String conversationId;
  final List<String> pendingUserMessageIds;
  final Completer<void> responseCompleter = Completer<void>();

  TChunk? accumulatedResult;
  String? messageId;
  bool hasAcknowledgedPendingUsers = false;
  AgentChunkSink<TChunk>? persistenceSink;
  AgentChunkSink<TChunk>? uiStreamingSink;
  StreamSubscription<TChunk>? responseSubscription;
  Future<void>? activeChunkProcessing;
  int chunkCount = 0;
  bool streamingRuntimeRemoved = false;
}
