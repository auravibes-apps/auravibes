import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/tools/usecases/get_agent_iteration_decision_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_latest_message_tool_calls_usecase.dart';
import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:riverpod/riverpod.dart';

class RunAllowedToolsUsecase {
  const RunAllowedToolsUsecase({
    required this.loadLatestMessageToolCallsUsecase,
    required this.messageRepository,
    required this.conversationToolsRepository,
    required this.toolsGroupsRepository,
    required this.workspaceToolsRepository,
    required this.mcpToolCaller,
    required this.getAgentIterationDecisionUsecase,
    required this.agentCancellationRuntime,
  });

  final LoadLatestMessageToolCallsUsecase loadLatestMessageToolCallsUsecase;
  final MessageRepository messageRepository;
  final ConversationToolsRepository conversationToolsRepository;
  final ToolsGroupsRepository toolsGroupsRepository;
  final WorkspaceToolsRepository workspaceToolsRepository;
  final McpToolCaller mcpToolCaller;
  final GetAgentIterationDecisionUsecase getAgentIterationDecisionUsecase;
  final AgentCancellationRuntime agentCancellationRuntime;

  Future<AgentIterationDecision> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final latestToolCalls = await loadLatestMessageToolCallsUsecase.call(
      conversationId: conversationId,
    );
    final updates = <_ToolResultUpdate>[];
    var hasPendingTools = false;

    if (!latestToolCalls.hasToolCalls) {
      return AgentIterationDecision.done;
    }

    if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
      await _stopPendingTools(messageId: latestToolCalls.messageId);
      return AgentIterationDecision.done;
    }

    if (latestToolCalls.notFoundToolCallIds.isNotEmpty) {
      updates.addAll(
        latestToolCalls.notFoundToolCallIds.map(
          (toolCallId) => _ToolResultUpdate(
            toolCallId: toolCallId,
            resultStatus: ToolCallResultStatus.toolNotFound,
            responseRaw: 'Tool not found for tool call: $toolCallId.',
          ),
        ),
      );
    }

    if (latestToolCalls.previouslyFailedToolCallIds.isNotEmpty) {
      updates.addAll(
        latestToolCalls.previouslyFailedToolCallIds.map(
          (toolCallId) => _ToolResultUpdate(
            toolCallId: toolCallId,
            resultStatus: ToolCallResultStatus.executionError,
            responseRaw:
                'Tool execution was already attempted and failed. '
                'Not retrying.',
          ),
        ),
      );
    }

    final grantedTools = <ToolToCall>[];
    for (final toolToCall in latestToolCalls.toolsToRun) {
      if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
        updates.add(
          _ToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: ToolCallResultStatus.stoppedByUser,
          ),
        );
        continue;
      }

      final permission = await _checkToolPermission(
        conversationId: conversationId,
        workspaceId: workspaceId,
        resolvedTool: toolToCall.tool,
      );

      switch (permission) {
        case ToolPermissionResult.granted:
          grantedTools.add(toolToCall);
        case ToolPermissionResult.needsConfirmation:
          hasPendingTools = true;
        case ToolPermissionResult.disabledInConversation:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInConversation,
              responseRaw:
                  'Tool "${toolToCall.tool.toolIdentifier}" is disabled for '
                  'this conversation.',
            ),
          );
        case ToolPermissionResult.disabledInWorkspace:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInWorkspace,
              responseRaw:
                  'Tool "${toolToCall.tool.toolIdentifier}" is disabled in '
                  'workspace settings.',
            ),
          );
        case ToolPermissionResult.notConfigured:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.notConfigured,
              responseRaw:
                  'Tool "${toolToCall.tool.toolIdentifier}" is not configured. '
                  'Enable it in workspace settings to use it.',
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
      await _updateToolResults(
        messageId: latestToolCalls.messageId,
        updates: updates,
      );
    }

    if (hasPendingTools) {
      return AgentIterationDecision.waitForToolApproval;
    }

    if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
      return AgentIterationDecision.done;
    }

    return getAgentIterationDecisionUsecase.call(
      messageId: latestToolCalls.messageId,
    );
  }

  Future<ToolPermissionResult> _checkToolPermission({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool resolvedTool,
  }) async {
    final permissionTableId = await _resolvePermissionTableId(resolvedTool);
    if (permissionTableId == null) {
      return ToolPermissionResult.notConfigured;
    }

    return conversationToolsRepository.checkToolPermission(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolId: permissionTableId,
    );
  }

  Future<String?> _resolvePermissionTableId(ResolvedTool resolvedTool) async {
    if (resolvedTool.mcpServerId == null) {
      return resolvedTool.toolIdentifier;
    }

    final toolGroup = await toolsGroupsRepository.getToolsGroupByMcpServerId(
      resolvedTool.mcpServerId!,
    );
    if (toolGroup == null) return null;

    final workspaceTool = await workspaceToolsRepository
        .getWorkspaceToolByToolName(
          toolGroupId: toolGroup.id,
          toolName: resolvedTool.toolIdentifier,
        );

    return workspaceTool?.id;
  }

  Future<_ToolExecutionResult> _executeTool({
    required String conversationId,
    required ToolToCall toolToCall,
  }) async {
    final arguments =
        safeJsonDecode(toolToCall.argumentsRaw) ?? const <String, dynamic>{};

    try {
      final result = await _runTool(conversationId, toolToCall.tool, arguments);
      if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
        return const _ToolExecutionResult(
          resultStatus: ToolCallResultStatus.stoppedByUser,
        );
      }
      if (result == null) {
        return const _ToolExecutionResult(
          resultStatus: ToolCallResultStatus.toolNotFound,
        );
      }
      return _ToolExecutionResult(
        resultStatus: ToolCallResultStatus.success,
        responseRaw: result.toString(),
      );
    } on Object catch (_) {
      return const _ToolExecutionResult(
        resultStatus: ToolCallResultStatus.executionError,
      );
    }
  }

  Future<Object?> _runTool(
    String conversationId,
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    if (tool.isBuiltIn) {
      final input = arguments['input'];
      if (input == null) {
        throw const FormatException(
          'Built-in tools require an input argument.',
        );
      }

      final builtInTool = tool.builtInTool;
      final toolService = builtInTool == null
          ? null
          : ToolService.getTool(builtInTool);
      if (toolService == null) {
        return null;
      }
      final operation = toolService.runner(input as Object);
      agentCancellationRuntime.registerCancelableOperation(
        conversationId,
        operation,
      );
      return operation.valueOrCancellation();
    }

    if (tool.isNative) {
      final input = arguments['input'];
      if (input == null) {
        throw const FormatException('Native tools require an input argument.');
      }

      final nativeTool = tool.nativeTool;
      final toolService = nativeTool == null
          ? null
          : NativeToolService.getTool(nativeTool);
      if (toolService == null) {
        return null;
      }
      final operation = toolService.runner(input as Object);
      agentCancellationRuntime.registerCancelableOperation(
        conversationId,
        operation,
      );
      return operation.valueOrCancellation();
    }

    if (tool.isMcp) {
      final mcpServerId = tool.mcpServerId;
      if (mcpServerId == null) {
        return null;
      }

      return mcpToolCaller(
        mcpServerId: mcpServerId,
        toolIdentifier: tool.toolIdentifier,
        arguments: arguments,
      );
    }

    return null;
  }

  Future<_ToolResultUpdate> _executeSafely({
    required String conversationId,
    required ToolToCall toolToCall,
  }) async {
    try {
      final result = await _executeTool(
        conversationId: conversationId,
        toolToCall: toolToCall,
      );
      return _ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: result.resultStatus,
        responseRaw: result.responseRaw,
      );
    } on Object catch (_) {
      return _ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus:
            agentCancellationRuntime.isCancellationRequested(
              conversationId,
            )
            ? ToolCallResultStatus.stoppedByUser
            : ToolCallResultStatus.executionError,
      );
    }
  }

  Future<void> _stopPendingTools({required String messageId}) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    var didUpdate = false;
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      if (!toolCall.isPending) return toolCall;

      didUpdate = true;
      return toolCall.copyWith(
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
    }).toList();
    if (!didUpdate) return;

    await messageRepository.patchMessage(
      messageId,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }

  Future<void> _updateToolResults({
    required String messageId,
    required List<_ToolResultUpdate> updates,
  }) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      final update = updates
          .where((candidate) => candidate.toolCallId == toolCall.id)
          .firstOrNull;
      if (update == null) return toolCall;

      return toolCall.copyWith(
        resultStatus: update.resultStatus,
        responseRaw: update.responseRaw,
      );
    }).toList();

    await messageRepository.patchMessage(
      messageId,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }
}

final runAllowedToolsUsecaseProvider = Provider<RunAllowedToolsUsecase>((ref) {
  return RunAllowedToolsUsecase(
    loadLatestMessageToolCallsUsecase: ref.watch(
      loadLatestMessageToolCallsUsecaseProvider,
    ),
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationToolsRepository: ref.watch(conversationToolsRepositoryProvider),
    toolsGroupsRepository: ref.watch(toolsGroupsRepositoryProvider),
    workspaceToolsRepository: ref.watch(workspaceToolsRepositoryProvider),
    mcpToolCaller: ref.watch(mcpToolCallerProvider),
    getAgentIterationDecisionUsecase: ref.watch(
      getAgentIterationDecisionUsecaseProvider,
    ),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
  );
});

typedef McpToolCaller =
    Future<String> Function({
      required String mcpServerId,
      required String toolIdentifier,
      required Map<String, dynamic> arguments,
    });

final mcpToolCallerProvider = Provider<McpToolCaller>((ref) {
  return ({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) {
    return ref
        .read(mcpConnectionProvider.notifier)
        .callTool(
          mcpServerId: mcpServerId,
          toolIdentifier: toolIdentifier,
          arguments: arguments,
        );
  };
});

class _ToolResultUpdate {
  const _ToolResultUpdate({
    required this.toolCallId,
    required this.resultStatus,
    this.responseRaw,
  });

  final String toolCallId;
  final ToolCallResultStatus resultStatus;
  final String? responseRaw;
}

class _ToolExecutionResult {
  const _ToolExecutionResult({required this.resultStatus, this.responseRaw});

  final ToolCallResultStatus resultStatus;
  final String? responseRaw;
}
