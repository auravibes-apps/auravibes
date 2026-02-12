import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/usecases/tools/batch_execute_tools_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/check_tool_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execute_tool_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/filter_tools_by_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/grant_tool_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/send_tool_responses_to_ai_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/update_message_metadata_usecase.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/providers/grouped_tools_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tool_execution_controller.freezed.dart';
part 'tool_execution_controller.g.dart';

/// A trigger that increments whenever tool call results are updated.
///
/// UI components can watch this to know when to refresh message data
/// after tool calls are resolved (stopped, skipped, or completed).
final toolUpdateRefreshTriggerProvider =
    NotifierProvider<ToolUpdateRefreshTriggerNotifier, int>(
      ToolUpdateRefreshTriggerNotifier.new,
    );

class ToolUpdateRefreshTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

/// Permission level when user grants a tool call.
enum ToolGrantLevel {
  /// Run this tool once, but ask again next time
  once,

  /// Grant permission for this conversation (persists to DB)
  conversation,
}

/// Tool response item for sending to AI
@Freezed(toJson: true)
abstract class ToolResponseItem with _$ToolResponseItem {
  const factory ToolResponseItem({
    required String id,
    required String content,
  }) = _ToolResponseItem;
}

/// Represents a tool call currently being tracked
@freezed
abstract class TrackedToolCall with _$TrackedToolCall {
  const factory TrackedToolCall({
    required String id,
    required String toolName,
    required String messageId,
    required bool isRunning,
  }) = _TrackedToolCall;
}

@Riverpod(keepAlive: true)
class ToolExecutionController extends _$ToolExecutionController {
  @override
  List<TrackedToolCall> build() => [];

  /// Query: Check if a specific tool is running
  bool isToolRunning(String toolCallId) {
    return state.any((t) => t.id == toolCallId && t.isRunning);
  }

  /// Query: Check if any tools for a message are running
  bool hasRunningToolsForMessage(String messageId) {
    return state.any((t) => t.messageId == messageId && t.isRunning);
  }

  /// Query: Get all tracked tool calls for a message
  List<TrackedToolCall> getToolCallsForMessage(String messageId) {
    return state.where((t) => t.messageId == messageId).toList();
  }

  /// Main API: Process tool calls from AI response
  Future<void> runTask(
    List<ToolToCall> toolCalling,
    String responseMessageId,
  ) async {
    // Get dependencies from Riverpod
    final conversationToolsRepo = ref.read(conversationToolsRepositoryProvider);
    final toolsGroupsRepo = ref.read(toolsGroupsRepositoryProvider);
    final workspaceToolsRepo = ref.read(workspaceToolsRepositoryProvider);
    final updateMetadataUseCase = UpdateMessageMetadataUseCase(
      ref.read(messageRepositoryProvider),
    );

    // Create use case instances with injected dependencies
    final checkPermissionUseCase = CheckToolPermissionUseCase(
      conversationToolsRepo,
      toolsGroupsRepo,
      workspaceToolsRepo,
    );

    final filterUseCase = FilterToolsByPermissionUseCase(
      checkPermissionUseCase,
      updateMetadataUseCase,
    );

    final conversationId = await _getConversationId(responseMessageId);
    final workspaceId = await _getWorkspaceId(responseMessageId);

    // Filter tools by permission
    final filtered = await filterUseCase.call(
      tools: toolCalling,
      conversationId: conversationId,
      workspaceId: workspaceId,
      responseMessageId: responseMessageId,
    );

    // Execute granted tools
    if (filtered.grantedTools.isNotEmpty) {
      // Mark as running
      for (final tool in filtered.grantedTools) {
        markToolRunning(tool.id, tool.tool.toolIdentifier, responseMessageId);
      }

      const executeToolUseCase = ExecuteToolUseCase();
      final batchUseCase = BatchExecuteToolsUseCase(
        executeToolUseCase,
        updateMetadataUseCase,
      );

      try {
        await batchUseCase.call(
          tools: filtered.grantedTools,
          messageId: responseMessageId,
        );
      } finally {
        // Clear running state (even if execution fails)
        clearRunningToolsForMessage(responseMessageId);
      }
    }

    // Continue AI only if ALL tools were granted
    final allToolsGranted = filtered.grantedTools.length == toolCalling.length;
    if (allToolsGranted && !filtered.hasPendingTools) {
      final sendToAI = SendToolResponsesToAIUseCase(
        ref.read(messageRepositoryProvider),
        ref,
      );
      await sendToAI.call(messageId: responseMessageId);
    }
  }

  /// Grant and execute a specific tool call
  Future<void> grantToolCall({
    required String toolCallId,
    required String messageId,
    required ToolGrantLevel level,
  }) async {
    // Get dependencies from Riverpod
    final messageRepo = ref.read(messageRepositoryProvider);
    final conversationToolsRepo = ref.read(conversationToolsRepositoryProvider);
    final toolsGroupsRepo = ref.read(toolsGroupsRepositoryProvider);
    final workspaceToolsRepo = ref.read(workspaceToolsRepositoryProvider);

    const executeToolUseCase = ExecuteToolUseCase();
    final updateMetadataUseCase = UpdateMessageMetadataUseCase(messageRepo);
    final batchExecuteUseCase = BatchExecuteToolsUseCase(
      executeToolUseCase,
      updateMetadataUseCase,
    );

    final grantUseCase = GrantToolPermissionUseCase(
      messageRepo,
      conversationToolsRepo,
      toolsGroupsRepo,
      workspaceToolsRepo,
      batchExecuteUseCase,
      updateMetadataUseCase,
    );

    await grantUseCase.call(
      toolCallId: toolCallId,
      messageId: messageId,
      level: level,
    );

    // Send tool response to AI after execution
    final sendToAI = SendToolResponsesToAIUseCase(
      ref.read(messageRepositoryProvider),
      ref,
    );
    await sendToAI.call(messageId: messageId);
  }

  /// Skip a tool call
  Future<void> skipToolCall({
    required String toolCallId,
    required String messageId,
  }) async {
    final updateMetadata = UpdateMessageMetadataUseCase(
      ref.read(messageRepositoryProvider),
    );

    await updateMetadata.call(
      messageId: messageId,
      updates: [
        ToolResultUpdate(
          toolCallId: toolCallId,
          resultStatus: ToolCallResultStatus.skippedByUser,
        ),
      ],
    );

    // Check if all tools resolved
    final sendToAI = SendToolResponsesToAIUseCase(
      ref.read(messageRepositoryProvider),
      ref,
    );
    await sendToAI.call(messageId: messageId);
  }

  /// Stop all pending tool calls for a message
  Future<void> stopAllToolCalls({required String messageId}) async {
    final messageRepo = ref.read(messageRepositoryProvider);
    final message = await messageRepo.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final pendingToolIds = metadata.toolCalls
        .where((t) => t.isPending && !isToolRunning(t.id))
        .map((t) => t.id)
        .toList();

    if (pendingToolIds.isEmpty) return;

    final updateMetadata = UpdateMessageMetadataUseCase(messageRepo);
    await updateMetadata.call(
      messageId: messageId,
      updates: pendingToolIds
          .map(
            (id) => ToolResultUpdate(
              toolCallId: id,
              resultStatus: ToolCallResultStatus.stoppedByUser,
            ),
          )
          .toList(),
    );
  }

  /// Mark tools as not found
  Future<void> setToolsToNotFound(
    String responseMessageId,
    List<String> toolIds,
  ) async {
    final updateMetadata = UpdateMessageMetadataUseCase(
      ref.read(messageRepositoryProvider),
    );

    await updateMetadata.call(
      messageId: responseMessageId,
      updates: toolIds
          .map(
            (id) => ToolResultUpdate(
              toolCallId: id,
              resultStatus: ToolCallResultStatus.toolNotFound,
            ),
          )
          .toList(),
    );
  }

  // State management helpers
  void markToolRunning(String id, String toolName, String messageId) {
    state = [
      ...state,
      TrackedToolCall(
        id: id,
        toolName: toolName,
        messageId: messageId,
        isRunning: true,
      ),
    ];
  }

  void clearRunningToolsForMessage(String messageId) {
    state = state.where((t) => t.messageId != messageId).toList();
  }

  void removeRunningTool(String toolCallId) {
    state = state.where((t) => t.id != toolCallId).toList();
  }

  // Helper methods
  Future<String> _getConversationId(String messageId) async {
    final messageRepo = ref.read(messageRepositoryProvider);
    final message = await messageRepo.getMessageById(messageId);
    return message?.conversationId ?? '';
  }

  Future<String> _getWorkspaceId(String messageId) async {
    final messageRepo = ref.read(messageRepositoryProvider);
    final conversationRepo = ref.read(conversationRepositoryProvider);
    final message = await messageRepo.getMessageById(messageId);
    if (message == null) return '';
    final conversation = await conversationRepo.getConversationById(
      message.conversationId,
    );
    return conversation?.workspaceId ?? '';
  }
}
