import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_grant_level.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/batch_execute_tools_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/check_tool_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/execute_tool_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/filter_tools_by_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/grant_tool_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/send_tool_responses_to_ai_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/update_message_metadata_usecase.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_controller.dart';
import 'package:auravibes_app/features/tools/providers/grouped_tools_controller.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/providers/messages_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'tool_execution_controller.freezed.dart';

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

class ToolExecutionContextException implements Exception {
  const ToolExecutionContextException(this.message);

  final String message;

  @override
  String toString() => 'ToolExecutionContextException: $message';
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

final toolExecutionControllerProvider =
    NotifierProvider<ToolExecutionController, List<TrackedToolCall>>(
      ToolExecutionController.new,
    );

class ToolExecutionController extends Notifier<List<TrackedToolCall>> {
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
    final messageRepo = ref.read(messageRepositoryProvider);

    final executionContext = await _resolveExecutionContext(responseMessageId);
    if (executionContext == null) {
      throw ToolExecutionContextException(
        'Unable to resolve conversation/workspace context for message '
        '$responseMessageId',
      );
    }

    // Get dependencies from Riverpod
    final conversationToolsRepo = ref.read(conversationToolsRepositoryProvider);
    final toolsGroupsRepo = ref.read(toolsGroupsRepositoryProvider);
    final workspaceToolsRepo = ref.read(workspaceToolsRepositoryProvider);
    final updateMetadataUseCase = UpdateMessageMetadataUseCase(
      messageRepo,
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

    // Filter tools by permission
    final filtered = await filterUseCase.call(
      tools: toolCalling,
      conversationId: executionContext.conversationId,
      workspaceId: executionContext.workspaceId,
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
      final sendToAI = _createSendToolResponsesUseCase();
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

    final canContinueAI = await _canContinueAi(messageId);
    if (!canContinueAI) return;

    // Send tool response to AI after execution
    final sendToAI = _createSendToolResponsesUseCase();
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

    final canContinueAI = await _canContinueAi(messageId);
    if (!canContinueAI) return;

    // Check if all tools resolved
    final sendToAI = _createSendToolResponsesUseCase();
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

  Future<_ToolExecutionContext?> _resolveExecutionContext(
    String responseMessageId,
  ) async {
    final messageRepo = ref.read(messageRepositoryProvider);
    final conversationRepo = ref.read(conversationRepositoryProvider);

    final message = await messageRepo.getMessageById(responseMessageId);
    if (message == null) return null;

    final conversationId = message.conversationId;
    if (conversationId.isEmpty) return null;

    final conversation = await conversationRepo.getConversationById(
      conversationId,
    );
    if (conversation == null) return null;

    final workspaceId = conversation.workspaceId;
    if (workspaceId.isEmpty) return null;

    return _ToolExecutionContext(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

  Future<bool> _canContinueAi(String messageId) async {
    if (hasRunningToolsForMessage(messageId)) return false;

    final messageRepo = ref.read(messageRepositoryProvider);
    final message = await messageRepo.getMessageById(messageId);
    if (message == null) return false;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final hasPendingTools = metadata.toolCalls.any(
      (toolCall) => toolCall.isPending,
    );
    return !hasPendingTools;
  }

  SendToolResponsesToAIUseCase _createSendToolResponsesUseCase() {
    return SendToolResponsesToAIUseCase(
      ref.read(messageRepositoryProvider),
      (responses, messageId) async {
        await ref
            .read(messagesControllerProvider.notifier)
            .sendToolsResponse(responses, messageId);
      },
    );
  }
}

class _ToolExecutionContext {
  const _ToolExecutionContext({
    required this.conversationId,
    required this.workspaceId,
  });

  final String conversationId;
  final String workspaceId;
}
