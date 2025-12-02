import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/providers/messages_manager_provider.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tool_calling_manager_provider.freezed.dart';
part 'tool_calling_manager_provider.g.dart';

@freezed
abstract class ToolCallItem with _$ToolCallItem {
  const factory ToolCallItem({
    required String id,
    required String name,
    required String argumentsRaw,
    required Map<String, dynamic> arguments,
  }) = _ToolCallItem;
}

@Freezed(toJson: true)
abstract class ToolResponseItem with _$ToolResponseItem {
  const factory ToolResponseItem({
    required String id,
    required String content,
  }) = _ToolResponseItem;
}

/// Represents a tool call currently being tracked by the manager.
///
/// This is used to track runtime state of tool execution, allowing the UI
/// to determine if a tool with no response is running or pending confirmation.
@freezed
abstract class TrackedToolCall with _$TrackedToolCall {
  const factory TrackedToolCall({
    /// The unique ID of the tool call
    required String id,

    /// The name/type of the tool
    required String toolName,

    /// The message ID this tool call belongs to
    required String messageId,

    /// Whether this tool is currently running
    required bool isRunning,
  }) = _TrackedToolCall;
}

@Riverpod(keepAlive: true)
class ToolCallingManagerNotifier extends _$ToolCallingManagerNotifier {
  @override
  List<TrackedToolCall> build() {
    return [];
  }

  /// Check if a specific tool call is currently running.
  ///
  /// Used by UI to distinguish between "pending confirmation" and "running".
  bool isToolRunning(String toolCallId) {
    return state.any((t) => t.id == toolCallId && t.isRunning);
  }

  /// Check if any tools for a message are currently running.
  bool hasRunningToolsForMessage(String messageId) {
    return state.any((t) => t.messageId == messageId && t.isRunning);
  }

  /// Get all tracked tool calls for a specific message.
  List<TrackedToolCall> getToolCallsForMessage(String messageId) {
    return state.where((t) => t.messageId == messageId).toList();
  }

  Future<void> runTask(
    List<MessageToolCallEntity> toolCalling,
    String responseMessageId,
  ) async {
    // Get message to find conversation/workspace context
    final message = await ref
        .read(messageRepositoryProvider)
        .getMessageById(responseMessageId);

    if (message == null) return;

    final conversation = await ref
        .read(conversationRepositoryProvider)
        .getConversationById(message.conversationId);

    if (conversation == null) return;

    final conversationId = message.conversationId;
    final workspaceId = conversation.workspaceId;

    final grantedTools =
        <(UserToolEntity<dynamic, dynamic, dynamic>, MessageToolCallEntity)>[];
    final skippedToolResponses = <ToolResponseItem>[];
    var hasPendingConfirmation = false;

    // Check permissions for each tool
    for (final tool in toolCalling) {
      final toolType = UserToolType.fromValue(tool.name);

      // Unknown tool type - skip
      if (toolType == null) {
        skippedToolResponses.add(
          ToolResponseItem(
            id: tool.id,
            content: 'skipped: unknown_tool',
          ),
        );
        continue;
      }

      final userTool = ToolService.getTool(toolType);

      // Tool implementation not found - skip
      if (userTool == null) {
        skippedToolResponses.add(
          ToolResponseItem(
            id: tool.id,
            content: 'skipped: tool_not_available',
          ),
        );
        continue;
      }

      // Check permission
      final conversationToolsRepo = ref.read(
        conversationToolsRepositoryProvider,
      );
      final permission = await conversationToolsRepo.checkToolPermission(
        conversationId: conversationId,
        workspaceId: workspaceId,
        toolId: tool.name,
      );

      switch (permission) {
        case ToolPermissionResult.granted:
          grantedTools.add((userTool, tool));

        case ToolPermissionResult.needsConfirmation:
          hasPendingConfirmation = true;
        // Don't add to skipped - leave responseRaw as null (pending)

        case ToolPermissionResult.notConfigured:
        case ToolPermissionResult.disabledInConversation:
        case ToolPermissionResult.disabledInWorkspace:
          skippedToolResponses.add(
            ToolResponseItem(
              id: tool.id,
              content: 'skipped: ${permission.skipReason}',
            ),
          );
      }
    }

    // Track running tools in state
    state = [
      ...state,
      ...grantedTools.map(
        (t) => TrackedToolCall(
          id: t.$2.id,
          toolName: t.$2.name,
          messageId: responseMessageId,
          isRunning: true,
        ),
      ),
    ];

    // Execute granted tools
    final executedResponses = <ToolResponseItem>[];
    for (final (userTool, toolCall) in grantedTools) {
      try {
        final input = toolCall.arguments['input'] as Object;
        final result = await userTool.runner(input).value;
        executedResponses.add(
          ToolResponseItem(
            id: toolCall.id,
            content: result.toString(),
          ),
        );
      } on Exception {
        executedResponses.add(
          ToolResponseItem(
            id: toolCall.id,
            content: 'aborted: execution_error',
          ),
        );
      }
    }

    // Remove from running state
    state = state.where((t) => t.messageId != responseMessageId).toList();

    // Combine all resolved responses (executed + skipped)
    final allResponses = [...executedResponses, ...skippedToolResponses];

    // Store responses in message metadata
    await _updateToolResponses(responseMessageId, allResponses);

    // DON'T respond to AI if there are tools pending confirmation
    // The UI will show a confirmation dialog, and when user approves/denies,
    // a separate method will be called to complete the flow.
    if (hasPendingConfirmation) {
      return;
    }

    // All tools resolved - respond to AI
    ref
        .read(messagesManagerProvider.notifier)
        .sendToolsResponse(allResponses, responseMessageId);
  }

  /// Update tool responses in message metadata.
  ///
  /// This stores the responseRaw for each tool call, including:
  /// - Executed tool results
  /// - Skipped tool reasons (e.g., "skipped: not_configured")
  /// - Aborted tool reasons (e.g., "aborted: execution_error")
  Future<void> _updateToolResponses(
    String messageId,
    List<ToolResponseItem> responses,
  ) async {
    final repo = ref.read(messageRepositoryProvider);
    final message = await repo.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      final response = responses.where((r) => r.id == toolCall.id).firstOrNull;
      if (response != null) {
        return toolCall.copyWith(responseRaw: response.content);
      }
      return toolCall;
    }).toList();

    await repo.updateMessage(
      messageId,
      MessageToUpdate(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }
}
