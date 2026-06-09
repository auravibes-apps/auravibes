// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_grant_level.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/resume_conversation_if_ready_usecase.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/usecases/run_resolved_tool_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _logger = Logger('approve_tool_call_usecase');

class ApproveToolCallUsecase {
  const ApproveToolCallUsecase({
    required this._messageRepository,
    required this._conversationToolsRepository,
    required this._toolsGroupsRepository,
    required this._workspaceToolsRepository,
    required this._toolResolverService,
    required this._resumeConversationIfReadyUsecase,
    required this._runResolvedToolUsecase,
    required this._agentCancellationRuntime,
  });

  final MessageRepository _messageRepository;
  final ConversationToolsRepository _conversationToolsRepository;
  final ToolsGroupsRepository _toolsGroupsRepository;
  final WorkspaceToolsRepository _workspaceToolsRepository;
  final ToolResolverService _toolResolverService;
  final ResumeConversationIfReadyUsecase _resumeConversationIfReadyUsecase;
  final RunResolvedToolUsecase _runResolvedToolUsecase;
  final AgentCancellationRuntime _agentCancellationRuntime;

  Future<void> call({
    required String toolCallId,
    required String messageId,
    required ToolGrantLevel level,
  }) async {
    final message = await _messageRepository.getMessageById(messageId);
    if (message == null) return;

    final toolCall = message.metadata?.toolCalls
        .where((tool) => tool.id == toolCallId)
        .firstOrNull;
    if (toolCall == null) return;

    final resolvedTool = _toolResolverService.resolveTool(toolCall.name);
    if (resolvedTool == null) {
      await _updateToolCall(
        message: message,
        toolCallId: toolCallId,
        resultStatus: ToolCallResultStatus.toolNotFound,
      );
      await _resumeConversationIfReadyUsecase.call(messageId: messageId);
      return;
    }

    if (level == ToolGrantLevel.conversation) {
      final permissionTableId = await _resolvePermissionTableId(resolvedTool);
      if (permissionTableId != null) {
        final _ = await _conversationToolsRepository
            .setConversationToolPermission(
              message.conversationId,
              permissionTableId,
              permissionMode: ToolPermissionMode.alwaysAllow,
            );
      }
    }

    final executionResult = await _executeTool(
      conversationId: message.conversationId,
      tool: resolvedTool,
      argumentsRaw: toolCall.argumentsRaw,
    );

    await _updateToolCall(
      message: message,
      toolCallId: toolCallId,
      resultStatus: executionResult.resultStatus,
      responseRaw: executionResult.responseRaw,
    );

    if (_agentCancellationRuntime.isCancellationRequested(
      message.conversationId,
    )) {
      return;
    }

    await _resumeConversationIfReadyUsecase.call(messageId: messageId);
  }

  Future<_ExecutionResult> _executeTool({
    required String conversationId,
    required ResolvedTool tool,
    required String argumentsRaw,
  }) async {
    final arguments = safeJsonDecode(argumentsRaw) ?? const <String, dynamic>{};

    try {
      final result = await _runResolvedToolUsecase(
        conversationId: conversationId,
        tool: tool,
        arguments: arguments,
      );
      if (_agentCancellationRuntime.isCancellationRequested(conversationId)) {
        return const _ExecutionResult(
          resultStatus: ToolCallResultStatus.stoppedByUser,
        );
      }
      if (result == null) {
        return const _ExecutionResult(
          resultStatus: ToolCallResultStatus.toolNotFound,
        );
      }
      return _ExecutionResult(
        resultStatus: ToolCallResultStatus.success,
        responseRaw: result.toString(),
      );
    } on FormatException catch (error, stackTrace) {
      _logger.severe(
        'Approved tool execution failed '
        'conversationId=$conversationId '
        'toolType=${tool.type.name} '
        'toolIdentifier=${tool.toolIdentifier}',
        error,
        stackTrace,
      );
      return _ExecutionResult(
        resultStatus: ToolCallResultStatus.executionError,
        responseRaw: 'Tool execution failed: ${error.message}',
      );
    } on Object catch (error, stackTrace) {
      _logger.severe(
        'Approved tool execution failed '
        'conversationId=$conversationId '
        'toolType=${tool.type.name} '
        'toolIdentifier=${tool.toolIdentifier}',
        error,
        stackTrace,
      );
      return const _ExecutionResult(
        resultStatus: ToolCallResultStatus.executionError,
      );
    }
  }

  Future<void> _updateToolCall({
    required MessageEntity message,
    required String toolCallId,
    required ToolCallResultStatus resultStatus,
    String? responseRaw,
  }) async {
    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      if (toolCall.id != toolCallId) return toolCall;

      return toolCall.copyWith(
        resultStatus: resultStatus,
        responseRaw: responseRaw,
      );
    }).toList();

    final _ = await _messageRepository.patchMessage(
      message.id,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }

  Future<String?> _resolvePermissionTableId(ResolvedTool resolvedTool) async {
    final mcpServerId = resolvedTool.mcpServerId;
    if (mcpServerId == null) {
      return resolvedTool.tableId;
    }

    final toolGroup = await _toolsGroupsRepository.getToolsGroupByMcpServerId(
      mcpServerId,
    );
    if (toolGroup == null) return null;

    final workspaceTool = await _workspaceToolsRepository
        .getWorkspaceToolByToolName(
          toolGroupId: toolGroup.id,
          toolName: resolvedTool.toolIdentifier,
        );

    return workspaceTool?.id;
  }
}

class _ExecutionResult {
  const _ExecutionResult({required this.resultStatus, this.responseRaw});

  final ToolCallResultStatus resultStatus;
  final String? responseRaw;
}

final approveToolCallUsecaseProvider = Provider<ApproveToolCallUsecase>((ref) {
  return ApproveToolCallUsecase(
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationToolsRepository: ref.watch(conversationToolsRepositoryProvider),
    toolsGroupsRepository: ref.watch(toolsGroupsRepositoryProvider),
    workspaceToolsRepository: ref.watch(workspaceToolsRepositoryProvider),
    toolResolverService: ToolResolverService(),
    resumeConversationIfReadyUsecase: ref.watch(
      resumeConversationIfReadyUsecaseProvider,
    ),
    runResolvedToolUsecase: ref.watch(runResolvedToolUsecaseProvider),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
  );
});
