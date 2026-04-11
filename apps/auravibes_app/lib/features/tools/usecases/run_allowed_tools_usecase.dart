import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/tools/usecases/get_agent_iteration_decision_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_latest_message_tool_calls_usecase.dart';
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
    required this.getAgentIterationDecisionUsecase,
  });

  final LoadLatestMessageToolCallsUsecase loadLatestMessageToolCallsUsecase;
  final MessageRepository messageRepository;
  final ConversationToolsRepository conversationToolsRepository;
  final ToolsGroupsRepository toolsGroupsRepository;
  final WorkspaceToolsRepository workspaceToolsRepository;
  final GetAgentIterationDecisionUsecase getAgentIterationDecisionUsecase;

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

    if (latestToolCalls.notFoundToolCallIds.isNotEmpty) {
      updates.addAll(
        latestToolCalls.notFoundToolCallIds.map(
          (toolCallId) => _ToolResultUpdate(
            toolCallId: toolCallId,
            resultStatus: ToolCallResultStatus.toolNotFound,
          ),
        ),
      );
    }

    final grantedTools = <ToolToCall>[];
    for (final toolToCall in latestToolCalls.toolsToRun) {
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
            ),
          );
        case ToolPermissionResult.disabledInWorkspace:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInWorkspace,
            ),
          );
        case ToolPermissionResult.notConfigured:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.notConfigured,
            ),
          );
      }
    }

    if (grantedTools.isNotEmpty) {
      final executionResults = await Future.wait(
        grantedTools.map((tool) => _executeSafely(toolToCall: tool)),
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
      return resolvedTool.tableId;
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
    required ToolToCall toolToCall,
  }) async {
    final arguments =
        safeJsonDecode(toolToCall.argumentsRaw) ?? const <String, dynamic>{};
    final input = arguments['input'];
    if (input == null) {
      return const _ToolExecutionResult(
        resultStatus: ToolCallResultStatus.executionError,
      );
    }

    try {
      final result = await _runTool(toolToCall.tool, input as Object);
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

  Future<Object> _runTool(ResolvedTool tool, Object input) async {
    if (tool.isBuiltIn) {
      final builtInTool = tool.builtInTool;
      final toolService = builtInTool == null
          ? null
          : ToolService.getTool(builtInTool);
      if (toolService == null) {
        throw StateError('Built-in tool not found');
      }
      return toolService.runner(input).value;
    }

    if (tool.isNative) {
      final nativeTool = tool.nativeTool;
      final toolService = nativeTool == null
          ? null
          : NativeToolService.getTool(nativeTool);
      if (toolService == null) {
        throw StateError('Native tool not found');
      }
      return toolService.runner(input).value;
    }

    throw StateError('Tool not found');
  }

  Future<_ToolResultUpdate> _executeSafely({
    required ToolToCall toolToCall,
  }) async {
    try {
      final result = await _executeTool(toolToCall: toolToCall);
      return _ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: result.resultStatus,
        responseRaw: result.responseRaw,
      );
    } on Object catch (_) {
      return _ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: ToolCallResultStatus.executionError,
      );
    }
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

    await messageRepository.updateMessage(
      messageId,
      MessageToUpdate(
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
    getAgentIterationDecisionUsecase: ref.watch(
      getAgentIterationDecisionUsecaseProvider,
    ),
  );
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
