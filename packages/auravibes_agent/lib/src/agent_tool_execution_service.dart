import 'dart:convert';

import 'package:auravibes_agent/src/agent_iteration_decision.dart';
import 'package:auravibes_agent/src/tool_calls.dart';

enum AgentToolPermissionResult {
  granted,
  needsConfirmation,
  disabledInConversation,
  disabledInWorkspace,
  notConfigured,
}

enum AgentToolResultStatus {
  success,
  toolNotFound,
  executionError,
  disabledInConversation,
  disabledInWorkspace,
  notConfigured,
  stoppedByUser,
}

class AgentToolApprovalDecision {
  const AgentToolApprovalDecision({required this.permissionResult});

  final AgentToolPermissionResult permissionResult;
}

class AgentToolResultUpdate {
  const AgentToolResultUpdate({
    required this.toolCallId,
    required this.resultStatus,
    this.responseRaw,
  });

  final String toolCallId;
  final AgentToolResultStatus resultStatus;
  final String? responseRaw;
}

class AgentToolExecutionResult {
  const AgentToolExecutionResult({
    required this.resultStatus,
    this.responseRaw,
  });

  final AgentToolResultStatus resultStatus;
  final String? responseRaw;
}

abstract interface class AgentToolExecutionProvider<TTool extends Object> {
  Future<LoadLatestMessageToolCallsResult<TTool>> loadLatestToolCalls({
    required String conversationId,
  });

  Future<AgentToolApprovalDecision> resolveToolApprovalDecision({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required TTool resolvedTool,
  });

  Future<Object?> runResolvedTool({
    required String conversationId,
    required TTool tool,
    required Map<String, dynamic> arguments,
  });

  Future<AgentIterationDecision> getAgentIterationDecision({
    required String messageId,
  });

  bool isCancellationRequested(String conversationId);

  Future<void> stopPendingTools({required String messageId});

  Future<void> updateToolResults({
    required String messageId,
    required List<AgentToolResultUpdate> updates,
  });

  String toolIdentifier(TTool tool);

  void logToolExecutionError({
    required String conversationId,
    required String toolCallId,
    required TTool tool,
    required Object error,
    required StackTrace stackTrace,
  });
}

class AgentToolExecutionService<TTool extends Object> {
  const AgentToolExecutionService({required this.provider});

  final AgentToolExecutionProvider<TTool> provider;

  Future<AgentIterationDecision> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final latestToolCalls = await provider.loadLatestToolCalls(
      conversationId: conversationId,
    );
    final updates = <AgentToolResultUpdate>[];
    var hasPendingTools = false;

    if (!latestToolCalls.hasToolCalls) {
      return AgentIterationDecision.done;
    }

    if (provider.isCancellationRequested(conversationId)) {
      await provider.stopPendingTools(messageId: latestToolCalls.messageId);

      return AgentIterationDecision.done;
    }

    _addNotFoundToolUpdates(latestToolCalls, updates);
    _addPreviouslyFailedToolUpdates(latestToolCalls, updates);

    final grantedTools = <AgentToolToCall<TTool>>[];
    for (final toolToCall in latestToolCalls.toolsToRun) {
      if (provider.isCancellationRequested(conversationId)) {
        updates.add(
          AgentToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: AgentToolResultStatus.stoppedByUser,
          ),
        );
        continue;
      }

      final decision = await provider.resolveToolApprovalDecision(
        conversationId: conversationId,
        workspaceId: workspaceId,
        toolCallId: toolToCall.id,
        resolvedTool: toolToCall.tool,
      );

      switch (decision.permissionResult) {
        case AgentToolPermissionResult.granted:
          grantedTools.add(toolToCall);
        case AgentToolPermissionResult.needsConfirmation:
          hasPendingTools = true;
        case AgentToolPermissionResult.disabledInConversation:
          updates.add(
            AgentToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: AgentToolResultStatus.disabledInConversation,
              responseRaw:
                  'Tool "${provider.toolIdentifier(toolToCall.tool)}" is '
                  'disabled for '
                  'this conversation.',
            ),
          );
        case AgentToolPermissionResult.disabledInWorkspace:
          updates.add(
            AgentToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: AgentToolResultStatus.disabledInWorkspace,
              responseRaw:
                  'Tool "${provider.toolIdentifier(toolToCall.tool)}" is '
                  'disabled in '
                  'workspace settings.',
            ),
          );
        case AgentToolPermissionResult.notConfigured:
          updates.add(
            AgentToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: AgentToolResultStatus.notConfigured,
              responseRaw:
                  'Tool "${provider.toolIdentifier(toolToCall.tool)}" is not '
                  'configured. Enable it in workspace settings to use it.',
            ),
          );
      }
    }

    if (grantedTools.isNotEmpty) {
      final executionResults = await Future.wait(
        grantedTools.map(
          (tool) => _executeSafely(
            conversationId: conversationId,
            toolToCall: tool,
          ),
        ),
      );
      updates.addAll(executionResults);
    }

    if (updates.isNotEmpty) {
      await provider.updateToolResults(
        messageId: latestToolCalls.messageId,
        updates: updates,
      );
    }

    if (hasPendingTools) {
      return AgentIterationDecision.waitForToolApproval;
    }

    if (provider.isCancellationRequested(conversationId)) {
      return AgentIterationDecision.done;
    }

    return provider.getAgentIterationDecision(
      messageId: latestToolCalls.messageId,
    );
  }

  void _addNotFoundToolUpdates(
    LoadLatestMessageToolCallsResult<TTool> latestToolCalls,
    List<AgentToolResultUpdate> updates,
  ) {
    if (latestToolCalls.notFoundToolCallIds.isEmpty) return;

    updates.addAll(
      latestToolCalls.notFoundToolCallIds.map(
        (toolCallId) => AgentToolResultUpdate(
          toolCallId: toolCallId,
          resultStatus: AgentToolResultStatus.toolNotFound,
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
          resultStatus: AgentToolResultStatus.executionError,
          responseRaw:
              'Tool execution was already attempted and failed. Not retrying.',
        ),
      ),
    );
  }

  Future<AgentToolExecutionResult> _executeTool({
    required String conversationId,
    required AgentToolToCall<TTool> toolToCall,
  }) async {
    final arguments = safeJsonDecodeToolArguments(toolToCall.argumentsRaw);

    try {
      final result = await provider.runResolvedTool(
        conversationId: conversationId,
        tool: toolToCall.tool,
        arguments: arguments,
      );
      if (provider.isCancellationRequested(conversationId)) {
        return const AgentToolExecutionResult(
          resultStatus: AgentToolResultStatus.stoppedByUser,
        );
      }
      if (result == null) {
        return const AgentToolExecutionResult(
          resultStatus: AgentToolResultStatus.toolNotFound,
        );
      }

      return AgentToolExecutionResult(
        resultStatus: AgentToolResultStatus.success,
        responseRaw: result.toString(),
      );
    } on FormatException catch (error, stackTrace) {
      _logExecutionError(
        conversationId: conversationId,
        toolCallId: toolToCall.id,
        tool: toolToCall.tool,
        error: error,
        stackTrace: stackTrace,
      );

      return AgentToolExecutionResult(
        resultStatus: AgentToolResultStatus.executionError,
        responseRaw: 'Tool execution failed: ${error.message}',
      );
    } on Object catch (error, stackTrace) {
      _logExecutionError(
        conversationId: conversationId,
        toolCallId: toolToCall.id,
        tool: toolToCall.tool,
        error: error,
        stackTrace: stackTrace,
      );

      return const AgentToolExecutionResult(
        resultStatus: AgentToolResultStatus.executionError,
      );
    }
  }

  Future<AgentToolResultUpdate> _executeSafely({
    required String conversationId,
    required AgentToolToCall<TTool> toolToCall,
  }) async {
    try {
      final result = await _executeTool(
        conversationId: conversationId,
        toolToCall: toolToCall,
      );

      return AgentToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: result.resultStatus,
        responseRaw: result.responseRaw,
      );
    } on Object catch (error, stackTrace) {
      _logExecutionError(
        conversationId: conversationId,
        toolCallId: toolToCall.id,
        tool: toolToCall.tool,
        error: error,
        stackTrace: stackTrace,
      );

      return AgentToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: provider.isCancellationRequested(conversationId)
            ? AgentToolResultStatus.stoppedByUser
            : AgentToolResultStatus.executionError,
      );
    }
  }

  void _logExecutionError({
    required String conversationId,
    required String toolCallId,
    required TTool tool,
    required Object error,
    required StackTrace stackTrace,
  }) {
    provider.logToolExecutionError(
      conversationId: conversationId,
      toolCallId: toolCallId,
      tool: tool,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Map<String, dynamic> safeJsonDecodeToolArguments(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
  } on Object catch (_) {}

  return const <String, dynamic>{};
}
