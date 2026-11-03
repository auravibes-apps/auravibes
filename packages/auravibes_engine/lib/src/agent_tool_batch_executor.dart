import 'dart:convert';

import 'package:auravibes_engine/src/agent_tool_lifecycle_hooks.dart';
import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';

class const AgentToolBatchCall<TTool extends Object>({
  required final String conversationId,
  required final String messageId,
  required final String toolCallId,
  required final TTool tool,
  required final String argumentsRaw,
  final String? workspaceId,
});

class const AgentToolBatchResult<TTool extends Object>({
  required final AgentToolBatchCall<TTool> call,
  required final AgentToolExecutionResult result,
});

typedef AgentToolBatchResultHandler<TTool extends Object> =
    Future<void> Function(AgentToolBatchResult<TTool> result);

class const AgentToolBatchExecutor<TTool extends Object>({
  required final AgentResolvedToolRunner<TTool> runResolvedTool,
  required final AgentToolCancellationChecker isCancellationRequested,
  required final AgentToolExecutionErrorLogger<TTool> logToolExecutionError,
  final bool captureOutputDigest = false,
  final AgentToolOutputPolicyResolver<TTool>? outputPolicyForTool,
  final AgentToolLifecycleHookRunner<TTool>? lifecycleHookRunner,
  final String workspaceId = '',
}) {
  Future<List<AgentToolBatchResult<TTool>>> call(
    Iterable<AgentToolBatchCall<TTool>> calls, {
    AgentToolBatchResultHandler<TTool>? onResult,
  }) => Future.wait(
    calls.map((call) async {
      final result = await _executeCall(call);
      final batchResult = AgentToolBatchResult(call: call, result: result);
      if (onResult != null) await onResult(batchResult);

      return batchResult;
    }),
  );

  Future<AgentToolExecutionResult> _executeCall(
    AgentToolBatchCall<TTool> call,
  ) async {
    final callWorkspaceId = call.workspaceId ?? workspaceId;
    if (isCancellationRequested(call.conversationId)) {
      return const AgentToolExecutionResult(resultStatus: .stoppedByUser);
    }

    final hookRunner = lifecycleHookRunner;
    if (hookRunner != null) {
      final hookResult = await _runBeforeToolHook(
        hookRunner,
        call,
        callWorkspaceId,
      );
      if (isCancellationRequested(call.conversationId) ||
          hookResult.outcome == AgentToolHookOutcome.cancelled) {
        return const AgentToolExecutionResult(resultStatus: .stoppedByUser);
      }
      if (hookResult.outcome != AgentToolHookOutcome.allow) {
        _logPreToolHookFailure(call, hookResult);

        return _preToolHookResult(hookResult);
      }
    }

    return await AgentToolExecutionDispatcher<TTool>(
      runResolvedTool: runResolvedTool,
      isCancellationRequested: isCancellationRequested,
      logToolExecutionError: logToolExecutionError,
      captureOutputDigest: captureOutputDigest,
      outputPolicyForTool: outputPolicyForTool,
      lifecycleHookRunner: lifecycleHookRunner,
      workspaceId: callWorkspaceId,
    ).call(
      conversationId: call.conversationId,
      toolCallId: call.toolCallId,
      tool: call.tool,
      argumentsRaw: call.argumentsRaw,
    );
  }

  Future<AgentPreToolHookResult> _runBeforeToolHook(
    AgentToolLifecycleHookRunner<TTool> hookRunner,
    AgentToolBatchCall<TTool> call,
    String workspaceId,
  ) async {
    try {
      return await hookRunner.beforeTool(
        request: AgentToolLifecycleHookRequest(
          workspaceId: workspaceId,
          conversationId: call.conversationId,
          toolCallId: call.toolCallId,
          tool: call.tool,
          argumentNames: sanitizedAgentToolHookArgumentNames(call.argumentsRaw),
        ),
        isCancellationRequested: isCancellationRequested,
      );
    } on Object {
      return const AgentPreToolHookResult(outcome: .failed);
    }
  }

  void _logPreToolHookFailure(
    AgentToolBatchCall<TTool> call,
    AgentPreToolHookResult result,
  ) {
    if (result.outcome == AgentToolHookOutcome.block) return;
    final failureCode = _preHookFailureCode(result.outcome);
    try {
      logToolExecutionError((
        conversationId: call.conversationId,
        toolCallId: call.toolCallId,
        tool: call.tool,
        error: StateError(failureCode),
        stackTrace: StackTrace.current,
        failurePhase: 'lifecycle_hook_pre_$failureCode',
      ));
    } on Object {
      // Logging must not allow a failed pre-hook to dispatch the tool.
    }
  }

  AgentToolExecutionResult _preToolHookResult(AgentPreToolHookResult result) {
    final outcome = result.outcome == AgentToolHookOutcome.block
        ? 'blocked'
        : 'failed';

    return AgentToolExecutionResult(
      resultStatus: .executionError,
      responseRaw: jsonEncode({
        'outcome': outcome,
        'code': _preHookFailureCode(result.outcome),
        'reason': _boundedHookText(result.reason, maxAgentToolHookReasonBytes),
      }),
    );
  }
}

String _preHookFailureCode(AgentToolHookOutcome outcome) => switch (outcome) {
  .block => 'hook_blocked',
  .timedOut => 'hook_timeout',
  .outputLimitExceeded => 'hook_output_limit',
  .unavailable => 'hook_unavailable',
  .failed || .allow || .success => 'hook_failed',
  .cancelled => 'hook_cancelled',
};

String? _boundedHookText(String? value, int maxBytes) {
  if (value == null) return null;

  return truncateAgentToolHookText(value, maxBytes);
}
