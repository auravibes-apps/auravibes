import 'package:auravibes_engine/src/agent_iteration_decision.dart';
import 'package:auravibes_engine/src/agent_tool_batch_executor.dart';
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
  required final AgentToolResultStatus resultStatus,
  final String? responseRaw,
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
}) {
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
      await provider.stopPendingTools(
        messageId: latestToolCalls.messageId,
        conversationId: conversationId,
      );

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

      switch (decision.permissionResult) {
        case .granted:
          grantedTools.add(toolToCall);
        case .needsConfirmation:
          hasPendingTools = true;
        case .disabledInConversation:
          updates.add(
            AgentToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: .disabledInConversation,
              responseRaw:
                  'Tool "${provider.toolIdentifier(toolToCall.tool)}" is '
                  'disabled for '
                  'this conversation.',
            ),
          );
        case .disabledByAgent:
          updates.add(
            AgentToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: .disabledByAgent,
              responseRaw:
                  'Tool "${provider.toolIdentifier(toolToCall.tool)}" is '
                  'denied by the selected agent.',
            ),
          );
        case .disabledInWorkspace:
          updates.add(
            AgentToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: .disabledInWorkspace,
              responseRaw:
                  'Tool "${provider.toolIdentifier(toolToCall.tool)}" is '
                  'disabled in '
                  'workspace settings.',
            ),
          );
        case .notConfigured:
          updates.add(
            AgentToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: .notConfigured,
              responseRaw:
                  'Tool "${provider.toolIdentifier(toolToCall.tool)}" is not '
                  'configured. Enable it in workspace settings to use it.',
            ),
          );
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
        onResult: (batchResult) => persistResult(
          AgentToolResultUpdate(
            toolCallId: batchResult.call.toolCallId,
            resultStatus: batchResult.result.resultStatus,
            responseRaw: batchResult.result.responseRaw,
          ),
        ),
      );
    }

    if (hasPendingTools) {
      return AgentIterationDecision.waitForToolApproval;
    }

    if (provider.isCancellationRequested(conversationId)) {
      return AgentIterationDecision.done;
    }

    return await provider.getAgentIterationDecision(
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
