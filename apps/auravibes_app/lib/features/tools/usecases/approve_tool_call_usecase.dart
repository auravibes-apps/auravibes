import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_grant_level.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/resume_conversation_if_ready_usecase.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart'
    show McpToolCaller, mcpToolCallerProvider;
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:riverpod/riverpod.dart';

class ApproveToolCallUsecase {
  const ApproveToolCallUsecase({
    required MessageRepository messageRepository,
    required ConversationToolsRepository conversationToolsRepository,
    required ToolsGroupsRepository toolsGroupsRepository,
    required WorkspaceToolsRepository workspaceToolsRepository,
    required ToolResolverService toolResolverService,
    required ResumeConversationIfReadyUsecase resumeConversationIfReadyUsecase,
    required McpToolCaller mcpToolCaller,
  }) : _messageRepository = messageRepository,
       _conversationToolsRepository = conversationToolsRepository,
       _toolsGroupsRepository = toolsGroupsRepository,
       _workspaceToolsRepository = workspaceToolsRepository,
       _toolResolverService = toolResolverService,
       _resumeConversationIfReadyUsecase = resumeConversationIfReadyUsecase,
       _mcpToolCaller = mcpToolCaller;

  final MessageRepository _messageRepository;
  final ConversationToolsRepository _conversationToolsRepository;
  final ToolsGroupsRepository _toolsGroupsRepository;
  final WorkspaceToolsRepository _workspaceToolsRepository;
  final ToolResolverService _toolResolverService;
  final ResumeConversationIfReadyUsecase _resumeConversationIfReadyUsecase;
  final McpToolCaller _mcpToolCaller;

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
        await _conversationToolsRepository.setConversationToolPermission(
          message.conversationId,
          permissionTableId,
          permissionMode: ToolPermissionMode.alwaysAllow,
        );
      }
    }

    final executionResult = await _executeTool(
      tool: resolvedTool,
      argumentsRaw: toolCall.argumentsRaw,
    );

    await _updateToolCall(
      message: message,
      toolCallId: toolCallId,
      resultStatus: executionResult.resultStatus,
      responseRaw: executionResult.responseRaw,
    );

    await _resumeConversationIfReadyUsecase.call(messageId: messageId);
  }

  Future<_ExecutionResult> _executeTool({
    required ResolvedTool tool,
    required String argumentsRaw,
  }) async {
    final arguments = safeJsonDecode(argumentsRaw) ?? const <String, dynamic>{};

    try {
      final result = await _runTool(tool, arguments);
      if (result == null) {
        return const _ExecutionResult(
          resultStatus: ToolCallResultStatus.toolNotFound,
        );
      }
      return _ExecutionResult(
        resultStatus: ToolCallResultStatus.success,
        responseRaw: result.toString(),
      );
    } on Object catch (_) {
      return const _ExecutionResult(
        resultStatus: ToolCallResultStatus.executionError,
      );
    }
  }

  Future<Object?> _runTool(
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
      return toolService.runner(input as Object).value;
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
      return toolService.runner(input as Object).value;
    }

    if (tool.isMcp) {
      final mcpServerId = tool.mcpServerId;
      if (mcpServerId == null) {
        return null;
      }

      return _mcpToolCaller(
        mcpServerId: mcpServerId,
        toolIdentifier: tool.toolIdentifier,
        arguments: arguments,
      );
    }

    return null;
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

    await _messageRepository.patchMessage(
      message.id,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }

  Future<String?> _resolvePermissionTableId(ResolvedTool resolvedTool) async {
    if (resolvedTool.mcpServerId == null) {
      return resolvedTool.tableId;
    }

    final toolGroup = await _toolsGroupsRepository.getToolsGroupByMcpServerId(
      resolvedTool.mcpServerId!,
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
    mcpToolCaller: ref.watch(mcpToolCallerProvider),
  );
});
