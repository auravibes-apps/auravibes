import 'package:auravibes_engine/src/agent_iteration_decision.dart';
import 'package:auravibes_engine/src/agent_loop_tool_result.dart';
import 'package:auravibes_engine/src/agent_tool_batch_executor.dart';
import 'package:auravibes_engine/src/agent_tool_loop_guard.dart';
import 'package:auravibes_engine/src/tool_calls.dart';
import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';

enum AgentToolPermissionResult {
  granted,
  needsConfirmation,
  disabledInConversation,
  disabledByAgent,
  disabledInWorkspace,
  notConfigured,
}

class const AgentToolApprovalDecision({
  required final AgentToolPermissionResult permissionResult,
});

class const AgentToolResultUpdate({
  required final String toolCallId,
  required final AgentToolResultStatus? resultStatus,
  final bool approvalRequested = false,
  final String? responseRaw,
  final String? responseContextRaw,
  final List<AgentToolResultMedia> media = const [],
  final bool outputTruncated = false,
  final int? originalResponseBytes,
  final bool fullOutputForContext = false,
});

typedef AgentToolApprovalRequest<TTool extends Object> = ({
  String conversationId,
  String workspaceId,
  String toolCallId,
  TTool resolvedTool,
  String? argumentsRaw,
});

abstract interface class AgentToolExecutionProvider<TTool extends Object> {
  Future<LoadLatestMessageToolCallsResult<TTool>> loadLatestToolCalls({
    required String conversationId,
  });

  Future<AgentToolApprovalDecision> resolveToolApprovalDecision(
    AgentToolApprovalRequest<TTool> request,
  );

  Future<Object?> runResolvedTool({
    required String conversationId,
    required String toolCallId,
    required TTool tool,
    required Map<String, dynamic> arguments,
  });

  Future<AgentIterationDecision> getAgentIterationDecision({
    required String messageId,
  });

  bool isCancellationRequested(String conversationId);

  Future<void> stopPendingTools({
    required String messageId,
    required String conversationId,
  });

  Future<void> updateToolResults({
    required String conversationId,
    required String messageId,
    required List<AgentToolResultUpdate> updates,
  });

  String toolIdentifier(TTool tool);

  void logToolExecutionError(AgentToolExecutionErrorRequest<TTool> request);
}

typedef _AgentToolPreparationResult<TTool extends Object> = ({
  AgentToolToCall<TTool>? grantedTool,
  bool hasPendingApproval,
  AgentToolResultUpdate? update,
});

typedef _PreparedAgentTools<TTool extends Object> = ({
  List<AgentToolToCall<TTool>> grantedTools,
  bool hasPendingTools,
  List<AgentToolResultUpdate> updates,
  Map<String, String> outcomeFingerprintsByCallId,
});

class const AgentToolExecutionService<TTool extends Object>({
  required final AgentToolExecutionProvider<TTool> provider,
  final AgentToolOutputPolicyResolver<TTool>? outputPolicyForTool,
}) {
  Future<AgentIterationDecision> call({
    required String conversationId,
    required String workspaceId,
  }) async => (await _runAgentLoopIteration(
    conversationId: conversationId,
    workspaceId: workspaceId,
    captureLoopFingerprint: false,
  )).decision;

  Future<AgentLoopToolResult> runAgentLoopIteration({
    required String conversationId,
    required String workspaceId,
  }) => _runAgentLoopIteration(
    conversationId: conversationId,
    workspaceId: workspaceId,
    captureLoopFingerprint: true,
  );

  Future<AgentLoopToolResult> _runAgentLoopIteration({
    required String conversationId,
    required String workspaceId,
    required bool captureLoopFingerprint,
  }) async {
    final latestToolCalls = await provider.loadLatestToolCalls(
      conversationId: conversationId,
    );
    if (!latestToolCalls.hasToolCalls) {
      return const AgentLoopToolResult(decision: .done);
    }
    if (provider.isCancellationRequested(conversationId)) {
      await provider.stopPendingTools(
        messageId: latestToolCalls.messageId,
        conversationId: conversationId,
      );

      return const AgentLoopToolResult(decision: .done);
    }

    final prepared = await _prepareAgentTools(
      latestToolCalls: latestToolCalls,
      conversationId: conversationId,
      workspaceId: workspaceId,
      captureLoopFingerprint: captureLoopFingerprint,
    );
    if (prepared.updates.isNotEmpty) {
      await provider.updateToolResults(
        messageId: latestToolCalls.messageId,
        conversationId: conversationId,
        updates: prepared.updates,
      );
    }

    await _runGrantedTools(
      grantedTools: prepared.grantedTools,
      latestToolCalls: latestToolCalls,
      conversationId: conversationId,
      captureLoopFingerprint: captureLoopFingerprint,
      outcomeFingerprintsByCallId: prepared.outcomeFingerprintsByCallId,
    );

    return await _agentLoopResult(
      latestToolCalls: latestToolCalls,
      conversationId: conversationId,
      hasPendingTools: prepared.hasPendingTools,
      captureLoopFingerprint: captureLoopFingerprint,
      outcomeFingerprintsByCallId: prepared.outcomeFingerprintsByCallId,
      updates: prepared.updates,
    );
  }

  Future<_PreparedAgentTools<TTool>> _prepareAgentTools({
    required LoadLatestMessageToolCallsResult<TTool> latestToolCalls,
    required String conversationId,
    required String workspaceId,
    required bool captureLoopFingerprint,
  }) async {
    final updates = <AgentToolResultUpdate>[];
    _addNotFoundToolUpdates(latestToolCalls, updates);
    _addPreviouslyFailedToolUpdates(latestToolCalls, updates);

    final modelToolNamesByCallId = {
      for (final call in latestToolCalls.allToolCalls) call.id: call.name,
    };
    final grantedTools = <AgentToolToCall<TTool>>[];
    final outcomeFingerprintsByCallId = <String, String>{};
    var hasPendingTools = latestToolCalls.pendingApprovalToolCallIds.isNotEmpty;

    for (final toolToCall in latestToolCalls.toolsToRun) {
      final result = await _prepareAgentTool(
        toolToCall: toolToCall,
        conversationId: conversationId,
        workspaceId: workspaceId,
      );
      if (result.grantedTool case final grantedTool?) {
        grantedTools.add(grantedTool);
      }
      if (result.hasPendingApproval) hasPendingTools = true;
      if (result.update case final update?) {
        updates.add(update);
        if (captureLoopFingerprint && update.resultStatus != null) {
          outcomeFingerprintsByCallId[toolToCall.id] = _fingerprintToolOutcome(
            toolToCall,
            update,
            toolName:
                modelToolNamesByCallId[toolToCall.id] ??
                provider.toolIdentifier(toolToCall.tool),
          );
        }
      }
    }

    return (
      grantedTools: grantedTools,
      hasPendingTools: hasPendingTools,
      updates: updates,
      outcomeFingerprintsByCallId: outcomeFingerprintsByCallId,
    );
  }

  Future<_AgentToolPreparationResult<TTool>> _prepareAgentTool({
    required AgentToolToCall<TTool> toolToCall,
    required String conversationId,
    required String workspaceId,
  }) async {
    if (provider.isCancellationRequested(conversationId)) {
      return _stoppedToolResult(toolToCall);
    }

    final decision = await provider.resolveToolApprovalDecision((
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolCallId: toolToCall.id,
      resolvedTool: toolToCall.tool,
      argumentsRaw: toolToCall.argumentsRaw,
    ));
    if (provider.isCancellationRequested(conversationId)) {
      return _stoppedToolResult(toolToCall);
    }

    return switch (decision.permissionResult) {
      .granted => (
        grantedTool: toolToCall,
        hasPendingApproval: false,
        update: null,
      ),
      .needsConfirmation => (
        grantedTool: null,
        hasPendingApproval: true,
        update: AgentToolResultUpdate(
          toolCallId: toolToCall.id,
          resultStatus: null,
          approvalRequested: true,
        ),
      ),
      .disabledInConversation ||
      .disabledByAgent ||
      .disabledInWorkspace ||
      .notConfigured => (
        grantedTool: null,
        hasPendingApproval: false,
        update: _permissionDeniedUpdate(toolToCall, decision.permissionResult),
      ),
    };
  }

  _AgentToolPreparationResult<TTool> _stoppedToolResult(
    AgentToolToCall<TTool> toolToCall,
  ) => (
    grantedTool: null,
    hasPendingApproval: false,
    update: AgentToolResultUpdate(
      toolCallId: toolToCall.id,
      resultStatus: .stoppedByUser,
    ),
  );

  AgentToolResultUpdate _permissionDeniedUpdate(
    AgentToolToCall<TTool> toolToCall,
    AgentToolPermissionResult permissionResult,
  ) {
    final toolName = provider.toolIdentifier(toolToCall.tool);

    return switch (permissionResult) {
      .disabledInConversation => AgentToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: .disabledInConversation,
        responseRaw: 'Tool "$toolName" is disabled for this conversation.',
      ),
      .disabledByAgent => AgentToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: .disabledByAgent,
        responseRaw: 'Tool "$toolName" is denied by the selected agent.',
      ),
      .disabledInWorkspace => AgentToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: .disabledInWorkspace,
        responseRaw: 'Tool "$toolName" is disabled in workspace settings.',
      ),
      .notConfigured => AgentToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: .notConfigured,
        responseRaw:
            'Tool "$toolName" is not configured. Enable it in workspace '
            'settings to use it.',
      ),
      .granted || .needsConfirmation => throw StateError(
        'Expected a permission-denied result.',
      ),
    };
  }

  Future<void> _runGrantedTools({
    required List<AgentToolToCall<TTool>> grantedTools,
    required LoadLatestMessageToolCallsResult<TTool> latestToolCalls,
    required String conversationId,
    required bool captureLoopFingerprint,
    required Map<String, String> outcomeFingerprintsByCallId,
  }) async {
    if (grantedTools.isEmpty) return;

    final modelToolNamesByCallId = {
      for (final call in latestToolCalls.allToolCalls) call.id: call.name,
    };
    var updateChain = Future<void>.value();

    Future<void> persistResult(AgentToolResultUpdate update) {
      final next = updateChain.then(
        (_) => provider.updateToolResults(
          messageId: latestToolCalls.messageId,
          conversationId: conversationId,
          updates: [update],
        ),
      );
      updateChain = next;

      return next;
    }

    await AgentToolBatchExecutor<TTool>(
      runResolvedTool: provider.runResolvedTool,
      isCancellationRequested: provider.isCancellationRequested,
      logToolExecutionError: provider.logToolExecutionError,
      captureOutputDigest: captureLoopFingerprint,
      outputPolicyForTool: outputPolicyForTool,
    ).call(
      grantedTools.map(
        (tool) => AgentToolBatchCall(
          conversationId: conversationId,
          messageId: latestToolCalls.messageId,
          toolCallId: tool.id,
          tool: tool.tool,
          argumentsRaw: tool.argumentsRaw,
        ),
      ),
      onResult: (batchResult) => _persistGrantedToolResult(
        batchResult: batchResult,
        captureLoopFingerprint: captureLoopFingerprint,
        modelToolNamesByCallId: modelToolNamesByCallId,
        outcomeFingerprintsByCallId: outcomeFingerprintsByCallId,
        persistResult: persistResult,
      ),
    );
  }

  Future<void> _persistGrantedToolResult({
    required AgentToolBatchResult<TTool> batchResult,
    required bool captureLoopFingerprint,
    required Map<String, String> modelToolNamesByCallId,
    required Map<String, String> outcomeFingerprintsByCallId,
    required Future<void> Function(AgentToolResultUpdate) persistResult,
  }) {
    final update = AgentToolResultUpdate(
      toolCallId: batchResult.call.toolCallId,
      resultStatus: batchResult.result.resultStatus,
      responseRaw: batchResult.result.responseRaw,
      responseContextRaw: batchResult.result.responseContextRaw,
      media: batchResult.result.media,
      outputTruncated: batchResult.result.outputTruncated,
      originalResponseBytes: batchResult.result.originalResponseBytes,
      fullOutputForContext: batchResult.result.fullOutputForContext,
    );
    if (captureLoopFingerprint) {
      outcomeFingerprintsByCallId[batchResult.call.toolCallId] =
          _fingerprintToolOutcome(
            AgentToolToCall(
              tool: batchResult.call.tool,
              id: batchResult.call.toolCallId,
              argumentsRaw: batchResult.call.argumentsRaw,
            ),
            update,
            toolName:
                modelToolNamesByCallId[batchResult.call.toolCallId] ??
                provider.toolIdentifier(batchResult.call.tool),
            outputDigest: batchResult.result.outputDigest,
          );
    }

    return persistResult(update);
  }

  Future<AgentLoopToolResult> _agentLoopResult({
    required LoadLatestMessageToolCallsResult<TTool> latestToolCalls,
    required String conversationId,
    required bool hasPendingTools,
    required bool captureLoopFingerprint,
    required Map<String, String> outcomeFingerprintsByCallId,
    required List<AgentToolResultUpdate> updates,
  }) async {
    if (hasPendingTools) {
      return const AgentLoopToolResult(decision: .waitForToolApproval);
    }
    if (provider.isCancellationRequested(conversationId)) {
      return const AgentLoopToolResult(decision: .done);
    }

    return await _resultForIterationDecision(
      latestToolCalls: latestToolCalls,
      captureLoopFingerprint: captureLoopFingerprint,
      outcomeFingerprintsByCallId: outcomeFingerprintsByCallId,
      updates: updates,
    );
  }

  Future<AgentLoopToolResult> _resultForIterationDecision({
    required LoadLatestMessageToolCallsResult<TTool> latestToolCalls,
    required bool captureLoopFingerprint,
    required Map<String, String> outcomeFingerprintsByCallId,
    required List<AgentToolResultUpdate> updates,
  }) async {
    final decision = await provider.getAgentIterationDecision(
      messageId: latestToolCalls.messageId,
    );
    final fingerprint =
        captureLoopFingerprint &&
            decision == AgentIterationDecision.continueIteration
        ? _fingerprintLatestToolIteration(
            latestToolCalls,
            outcomeFingerprintsByCallId,
            updates,
          )
        : null;

    return AgentLoopToolResult(decision: decision, fingerprint: fingerprint);
  }

  String? _fingerprintLatestToolIteration(
    LoadLatestMessageToolCallsResult<TTool> latestToolCalls,
    Map<String, String> outcomeFingerprintsByCallId,
    List<AgentToolResultUpdate> updates,
  ) {
    final calls = <String, ({String name, String argumentsRaw})>{};
    for (final call in latestToolCalls.allToolCalls) {
      calls[call.id] = (name: call.name, argumentsRaw: call.argumentsRaw);
    }
    for (final call in latestToolCalls.toolsToRun) {
      calls.putIfAbsent(
        call.id,
        () => (
          name: provider.toolIdentifier(call.tool),
          argumentsRaw: call.argumentsRaw,
        ),
      );
    }

    for (final update in updates) {
      if (outcomeFingerprintsByCallId.containsKey(update.toolCallId) ||
          update.resultStatus == null) {
        continue;
      }
      final call = calls[update.toolCallId];
      if (call == null) continue;
      outcomeFingerprintsByCallId[update.toolCallId] =
          agentToolOutcomeFingerprint(
            toolName: call.name,
            argumentsRaw: call.argumentsRaw,
            resultStatus: update.resultStatus!,
            responseRaw: update.responseRaw,
            responseContextRaw: update.responseContextRaw,
            media: update.media,
          );
    }

    final orderedCalls = latestToolCalls.allToolCalls.isNotEmpty
        ? latestToolCalls.allToolCalls
        : [
            for (final call in latestToolCalls.toolsToRun)
              AgentMessageToolCall(
                id: call.id,
                name: provider.toolIdentifier(call.tool),
                argumentsRaw: call.argumentsRaw,
              ),
          ];
    final fingerprints = [
      for (final call in orderedCalls) ?outcomeFingerprintsByCallId[call.id],
    ];
    if (fingerprints.isEmpty) return null;

    return agentToolIterationFingerprint(fingerprints);
  }

  String _fingerprintToolOutcome(
    AgentToolToCall<TTool> call,
    AgentToolResultUpdate update, {
    required String toolName,
    String? outputDigest,
  }) => agentToolOutcomeFingerprint(
    toolName: toolName,
    argumentsRaw: call.argumentsRaw,
    resultStatus: update.resultStatus!,
    responseRaw: update.responseRaw,
    responseContextRaw: update.responseContextRaw,
    outputDigest: outputDigest,
    media: update.media,
  );

  void _addNotFoundToolUpdates(
    LoadLatestMessageToolCallsResult<TTool> latestToolCalls,
    List<AgentToolResultUpdate> updates,
  ) {
    if (latestToolCalls.notFoundToolCallIds.isEmpty) return;

    updates.addAll(
      latestToolCalls.notFoundToolCallIds.map(
        (toolCallId) => AgentToolResultUpdate(
          toolCallId: toolCallId,
          resultStatus: .toolNotFound,
          responseRaw: 'Tool not found for tool call: $toolCallId.',
        ),
      ),
    );
  }

  void _addPreviouslyFailedToolUpdates(
    LoadLatestMessageToolCallsResult<TTool> latestToolCalls,
    List<AgentToolResultUpdate> updates,
  ) {
    if (latestToolCalls.previouslyFailedToolCallIds.isEmpty) return;

    updates.addAll(
      latestToolCalls.previouslyFailedToolCallIds.map(
        (toolCallId) => AgentToolResultUpdate(
          toolCallId: toolCallId,
          resultStatus: .executionError,
          responseRaw:
              'Tool execution was already attempted and failed. Not retrying.',
        ),
      ),
    );
  }
}
