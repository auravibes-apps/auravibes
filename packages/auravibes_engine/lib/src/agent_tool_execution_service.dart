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
    final updates = <AgentToolResultUpdate>[];
    var hasPendingTools = latestToolCalls.pendingApprovalToolCallIds.isNotEmpty;

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

    _addNotFoundToolUpdates(latestToolCalls, updates);
    _addPreviouslyFailedToolUpdates(latestToolCalls, updates);

    final grantedTools = <AgentToolToCall<TTool>>[];
    final outcomeFingerprintsByCallId = <String, String>{};
    for (final toolToCall in latestToolCalls.toolsToRun) {
      if (provider.isCancellationRequested(conversationId)) {
        updates.add(
          AgentToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: .stoppedByUser,
          ),
        );
        continue;
      }

      final decision = await provider.resolveToolApprovalDecision((
        conversationId: conversationId,
        workspaceId: workspaceId,
        toolCallId: toolToCall.id,
        resolvedTool: toolToCall.tool,
        argumentsRaw: toolToCall.argumentsRaw,
      ));

      if (provider.isCancellationRequested(conversationId)) {
        updates.add(
          AgentToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: .stoppedByUser,
          ),
        );
        continue;
      }

      switch (decision.permissionResult) {
        case .granted:
          grantedTools.add(toolToCall);
        case .needsConfirmation:
          hasPendingTools = true;
          updates.add(
            AgentToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: null,
              approvalRequested: true,
            ),
          );
        case .disabledInConversation:
          final update = AgentToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: .disabledInConversation,
            responseRaw:
                'Tool "${provider.toolIdentifier(toolToCall.tool)}" is '
                'disabled for '
                'this conversation.',
          );
          updates.add(update);
          if (captureLoopFingerprint) {
            outcomeFingerprintsByCallId[toolToCall.id] =
                _fingerprintToolOutcome(toolToCall, update);
          }
        case .disabledByAgent:
          final update = AgentToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: .disabledByAgent,
            responseRaw:
                'Tool "${provider.toolIdentifier(toolToCall.tool)}" is '
                'denied by the selected agent.',
          );
          updates.add(update);
          if (captureLoopFingerprint) {
            outcomeFingerprintsByCallId[toolToCall.id] =
                _fingerprintToolOutcome(toolToCall, update);
          }
        case .disabledInWorkspace:
          final update = AgentToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: .disabledInWorkspace,
            responseRaw:
                'Tool "${provider.toolIdentifier(toolToCall.tool)}" is '
                'disabled in '
                'workspace settings.',
          );
          updates.add(update);
          if (captureLoopFingerprint) {
            outcomeFingerprintsByCallId[toolToCall.id] =
                _fingerprintToolOutcome(toolToCall, update);
          }
        case .notConfigured:
          final update = AgentToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: .notConfigured,
            responseRaw:
                'Tool "${provider.toolIdentifier(toolToCall.tool)}" is not '
                'configured. Enable it in workspace settings to use it.',
          );
          updates.add(update);
          if (captureLoopFingerprint) {
            outcomeFingerprintsByCallId[toolToCall.id] =
                _fingerprintToolOutcome(toolToCall, update);
          }
      }
    }

    if (updates.isNotEmpty) {
      await provider.updateToolResults(
        messageId: latestToolCalls.messageId,
        conversationId: conversationId,
        updates: updates,
      );
    }

    if (grantedTools.isNotEmpty) {
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
        onResult: (batchResult) {
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
                  outputDigest: batchResult.result.outputDigest,
                );
          }

          return persistResult(update);
        },
      );
    }

    if (hasPendingTools) {
      return const AgentLoopToolResult(decision: .waitForToolApproval);
    }

    if (provider.isCancellationRequested(conversationId)) {
      return const AgentLoopToolResult(decision: .done);
    }

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
    String? outputDigest,
  }) => agentToolOutcomeFingerprint(
    toolName: provider.toolIdentifier(call.tool),
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
