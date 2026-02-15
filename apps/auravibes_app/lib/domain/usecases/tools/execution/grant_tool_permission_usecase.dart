import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_grant_level.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/batch_execute_tools_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/update_message_metadata_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/tool_resolution.dart';

/// Use case for granting tool permissions.
///
/// This is a simple class with constructor injection - no Riverpod.
class GrantToolPermissionUseCase {
  const GrantToolPermissionUseCase(
    this._messageRepository,
    this._conversationToolsRepo,
    this._toolsGroupsRepo,
    this._workspaceToolsRepo,
    this._batchExecuteUseCase,
    this._updateMetadataUseCase,
  );

  final MessageRepository _messageRepository;
  final ConversationToolsRepository _conversationToolsRepo;
  final ToolsGroupsRepository _toolsGroupsRepo;
  final WorkspaceToolsRepository _workspaceToolsRepo;
  final BatchExecuteToolsUseCase _batchExecuteUseCase;
  final UpdateMessageMetadataUseCase _updateMetadataUseCase;

  /// Grants permission for a tool call and executes it
  Future<void> call({
    required String toolCallId,
    required String messageId,
    required ToolGrantLevel level,
  }) async {
    final message = await _messageRepository.getMessageById(messageId);
    if (message == null) return;

    final conversationId = message.conversationId;
    final metadata = message.metadata ?? const MessageMetadataEntity();

    final toolCall = metadata.toolCalls
        .where((t) => t.id == toolCallId)
        .firstOrNull;
    if (toolCall == null) return;

    final resolvedTool = ToolResolverUtil().resolveTool(toolCall.name);
    if (resolvedTool == null) {
      // Handle tool not found
      await _updateMetadataUseCase.call(
        messageId: messageId,
        updates: [
          ToolResultUpdate(
            toolCallId: toolCallId,
            resultStatus: ToolCallResultStatus.toolNotFound,
          ),
        ],
      );
      return;
    }

    // If granting for conversation, persist the permission
    if (level == ToolGrantLevel.conversation) {
      final permissionTableId = await _resolvePermissionTableId(resolvedTool);
      if (permissionTableId != null) {
        await _conversationToolsRepo.setConversationToolPermission(
          conversationId,
          permissionTableId,
          permissionMode: ToolPermissionMode.alwaysAllow,
        );
      }
    }

    // Execute the tool
    await _batchExecuteUseCase.call(
      tools: [
        ToolToCall(
          id: toolCallId,
          tool: resolvedTool,
          argumentsRaw: toolCall.argumentsRaw,
        ),
      ],
      messageId: messageId,
    );
  }

  Future<String?> _resolvePermissionTableId(ResolvedTool resolvedTool) async {
    if (resolvedTool.mcpServerId == null) {
      return resolvedTool.tableId;
    }

    final toolGroup = await _toolsGroupsRepo.getToolsGroupByMcpServerId(
      resolvedTool.mcpServerId!,
    );
    if (toolGroup == null) return null;

    final workspaceTool = await _workspaceToolsRepo.getWorkspaceToolByToolName(
      toolGroupId: toolGroup.id,
      toolName: resolvedTool.toolIdentifier,
    );

    return workspaceTool?.id;
  }
}
