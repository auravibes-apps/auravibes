import 'dart:convert';

import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/providers/grouped_tools_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/providers/mcp_manager_provider.dart';
import 'package:auravibes_app/providers/messages_manager_provider.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/tool_resolution.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tool_calling_manager_provider.freezed.dart';
part 'tool_calling_manager_provider.g.dart';

/// A trigger that increments whenever tool call results are updated.
///
/// UI components can watch this to know when to refresh message data
/// after tool calls are resolved (stopped, skipped, or completed).
@Riverpod(keepAlive: true)
class ToolUpdateRefreshTrigger extends _$ToolUpdateRefreshTrigger {
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

// ============================================================
// Internal helper classes
// ============================================================

/// Internal class to represent an update to a tool call.
class _ToolUpdate {
  const _ToolUpdate({
    required this.toolCallId,
    required this.resultStatus,
    this.responseRaw,
  });

  final String toolCallId;
  final ToolCallResultStatus resultStatus;
  final String? responseRaw;
}

@Riverpod(keepAlive: true)
class ToolCallingManagerNotifier extends _$ToolCallingManagerNotifier {
  @override
  List<TrackedToolCall> build() {
    return [];
  }

  // ============================================================
  // Public query methods
  // ============================================================

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

  // ============================================================
  // Main public API
  // ============================================================

  /// Process tool calls from an AI response.
  ///
  /// Checks permissions for each tool, executes granted ones,
  /// and only continues the AI loop if ALL tools are granted.
  /// If any tool is not granted (needs confirmation, not found, disabled),
  /// the granted tools are still executed but the AI is not called.
  /// The user will handle pending tools via the conversation UI.
  Future<void> runTask(
    List<ToolToCall> toolCalling,
    String responseMessageId,
  ) async {
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

    // Categorize tools by permission
    final grantedTools = await _filterToolsGaranted(
      toolCalling,
      conversationId: conversationId,
      workspaceId: workspaceId,
      responseMessageId: responseMessageId,
    );

    // Execute granted tools and get their updates
    final executedUpdates = await _executeToolsBatch(
      grantedTools,
      responseMessageId,
    );

    // Store updates in message metadata
    await _updateToolResults(responseMessageId, executedUpdates);

    // Only continue AI loop if ALL tools were granted.
    // If any tool is not granted (needs confirmation, not found, disabled,
    // etc.) stop here and let the user handle via conversation UI.
    final allToolsGranted = grantedTools.length == toolCalling.length;
    if (!allToolsGranted) {
      return;
    }

    // All tools granted and executed - respond to AI
    await _sendAllResponsesToAI(responseMessageId);
  }

  Future<void> setToolsToNotFound(
    String responseMessageId,
    List<String> toolIds,
  ) async {
    await _updateToolResults(responseMessageId, [
      for (final id in toolIds)
        .new(toolCallId: id, resultStatus: .toolNotFound),
    ]);
  }

  /// Grant permission and execute a specific tool call.
  ///
  /// After granting, re-evaluates all pending tools for this message
  /// and runs any that are now granted. If all tools are resolved,
  /// sends response to AI.
  Future<void> grantToolCall({
    required String toolCallId,
    required String messageId,
    required ToolGrantLevel level,
  }) async {
    final message = await ref
        .read(messageRepositoryProvider)
        .getMessageById(messageId);
    if (message == null) return;

    final conversationId = message.conversationId;
    final metadata = message.metadata ?? const MessageMetadataEntity();
    final toolCall = metadata.toolCalls
        .where((t) => t.id == toolCallId)
        .firstOrNull;
    if (toolCall == null) return;

    final resolvedTool = ToolResolverUtil().resolveTool(toolCall.name);

    if (resolvedTool == null) {
      await _updateToolResults(messageId, [
        _ToolUpdate(
          toolCallId: toolCallId,
          resultStatus: ToolCallResultStatus.toolNotFound,
        ),
      ]);
      return;
    }

    // If granting for conversation, persist the permission using the table ID
    String? grantedPermissionTableId;
    if (level == ToolGrantLevel.conversation) {
      // Parse the composite ID to get the table ID for permission storage
      grantedPermissionTableId = await _resolvePermissionTableId(
        resolvedTool,
      );
      if (grantedPermissionTableId != null) {
        await ref
            .read(conversationToolsRepositoryProvider)
            .setConversationToolPermission(
              conversationId,
              grantedPermissionTableId,
              permissionMode: ToolPermissionMode.alwaysAllow,
            );
      }
    }

    if (level == ToolGrantLevel.conversation &&
        grantedPermissionTableId != null) {
      await _runPendingToolsForConversation(
        conversationId: conversationId,
        permissionTableId: grantedPermissionTableId,
      );
    } else {
      // Execute the tool (bypasses permission check for "once" grants)
      final update = await _executeSingleTool(
        .new(
          tool: resolvedTool,
          id: toolCallId,
          argumentsRaw: toolCall.argumentsRaw,
        ),
        messageId,
      );
      await _updateToolResults(messageId, [update]);
      // Check if all tools are now resolved
      await _checkAndRespondToAI(messageId);
    }
  }

  /// Skip a specific tool call (mark as skipped).
  ///
  /// After skipping, checks if all tools are resolved and sends
  /// response to AI if so.
  Future<void> skipToolCall({
    required String toolCallId,
    required String messageId,
  }) async {
    await _updateToolResults(messageId, [
      _ToolUpdate(
        toolCallId: toolCallId,
        resultStatus: ToolCallResultStatus.skippedByUser,
      ),
    ]);

    await _checkAndRespondToAI(messageId);
  }

  /// Stop all pending tool calls for this message.
  ///
  /// All pending tools will be marked as stopped and NO response is sent
  /// to the AI. This effectively stops the agent loop entirely.
  Future<void> stopAllToolCalls({
    required String messageId,
  }) async {
    final message = await ref
        .read(messageRepositoryProvider)
        .getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();

    // Find all pending tools (not resolved and not running)
    final pendingToolIds = metadata.toolCalls
        .where((t) => t.isPending && !isToolRunning(t.id))
        .map((t) => t.id)
        .toList();

    // Mark all as stopped
    final stoppedUpdates = pendingToolIds
        .map(
          (id) => _ToolUpdate(
            toolCallId: id,
            resultStatus: ToolCallResultStatus.stoppedByUser,
          ),
        )
        .toList();

    // Save updates but do NOT send to AI - this stops the agent loop
    await _updateToolResults(messageId, stoppedUpdates);
  }

  Future<String?> _resolvePermissionTableId(
    ResolvedTool resolvedTool,
  ) async {
    // Built-in tools already include the workspace tool table ID in the
    // composite identifier, so we can return early.
    if (resolvedTool.mcpServerId == null) {
      return resolvedTool.tableId;
    }

    final toolsGroupsRepository = ref.read(toolsGroupsRepositoryProvider);
    final workspaceToolsRepository = ref.read(workspaceToolsRepositoryProvider);

    final toolGroup = await toolsGroupsRepository.getToolsGroupByMcpServerId(
      resolvedTool.mcpServerId!,
    );

    if (toolGroup == null) {
      return null;
    }

    final workspaceTool = await workspaceToolsRepository
        .getWorkspaceToolByToolName(
          toolGroupId: toolGroup.id,
          toolName: resolvedTool.toolIdentifier,
        );

    return workspaceTool?.id;
  }

  Future<ToolPermissionResult> _checkPermission({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool resolvedTool,
  }) async {
    final conversationToolsRepo = ref.read(conversationToolsRepositoryProvider);
    final permissionTableId = await _resolvePermissionTableId(resolvedTool);

    if (permissionTableId == null) {
      return ToolPermissionResult.notConfigured;
    }

    // Check permission using the table ID for granular permissions
    return conversationToolsRepo.checkToolPermission(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolId: permissionTableId,
    );
  }

  // ============================================================
  // Helper: Tool categorization by permission
  // ============================================================

  /// Categorizes tool calls by their permission status.
  ///
  /// Returns granted tools to execute, resolved tool updates, and
  /// whether any tools are pending confirmation.
  Future<List<ToolToCall>> _filterToolsGaranted(
    List<ToolToCall> toolCalls, {
    required String conversationId,
    required String workspaceId,
    required String responseMessageId,
  }) async {
    final grantedTools = <ToolToCall>[];
    final resolvedToolUpdates = <_ToolUpdate>[];

    for (final toolToCall in toolCalls) {
      if (toolToCall.tool.isBuiltIn && toolToCall.tool.builtInTool == null) {
        resolvedToolUpdates.add(
          _ToolUpdate(
            toolCallId: toolToCall.id,
            resultStatus: ToolCallResultStatus.toolNotFound,
          ),
        );
        continue;
      }

      final permission = await _checkPermission(
        conversationId: conversationId,
        workspaceId: workspaceId,
        resolvedTool: toolToCall.tool,
      );

      switch (permission) {
        case ToolPermissionResult.granted:
          grantedTools.add(toolToCall);

        case ToolPermissionResult.needsConfirmation:
          // Don't add to resolved - leave as pending
          continue;

        case ToolPermissionResult.notConfigured:
          resolvedToolUpdates.add(
            _ToolUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.notConfigured,
            ),
          );

        case ToolPermissionResult.disabledInConversation:
          resolvedToolUpdates.add(
            _ToolUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInConversation,
            ),
          );

        case ToolPermissionResult.disabledInWorkspace:
          resolvedToolUpdates.add(
            _ToolUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInWorkspace,
            ),
          );
      }
    }

    await _updateToolResults(responseMessageId, resolvedToolUpdates);

    return grantedTools;
  }

  // ============================================================
  // Helper: Tool execution
  // ============================================================

  /// Executes a batch of granted tools and returns their updates.
  Future<List<_ToolUpdate>> _executeToolsBatch(
    List<ToolToCall> toolsToCall,
    String messageId,
  ) async {
    if (toolsToCall.isEmpty) return [];

    // Track running tools in state
    _addRunningTools(
      toolsToCall.map(
        (t) => TrackedToolCall(
          id: t.id,
          toolName: t.tool.toolIdentifier,
          messageId: messageId,
          isRunning: true,
        ),
      ),
    );

    // Execute all tools
    final updates = <_ToolUpdate>[];
    for (final toolToCall in toolsToCall) {
      final update = await _runToolExecution(toolToCall);
      updates.add(update);
    }

    // Remove from running state
    _removeRunningToolsForMessage(messageId);

    return updates;
  }

  /// Executes a single tool call with running state management.
  ///
  /// Used when granting individual tool calls after confirmation.
  Future<_ToolUpdate> _executeSingleTool(
    ToolToCall toolCall,
    String messageId,
  ) async {
    // Track as running
    _addRunningTools([
      TrackedToolCall(
        id: toolCall.id,
        toolName: toolCall.tool.toolIdentifier,
        messageId: messageId,
        isRunning: true,
      ),
    ]);

    // Execute the tool
    final update = await _runToolExecution(toolCall);

    // Remove from running state
    _removeRunningTool(toolCall.id);

    return update;
  }

  Future<void> _runPendingToolsForConversation({
    required String conversationId,
    required String permissionTableId,
  }) async {
    final repo = ref.read(messageRepositoryProvider);
    // TODO(optimize): Limit to only the last message
    final messages = await repo.getMessagesByConversation(conversationId);

    for (final message in messages) {
      final metadata = message.metadata ?? const MessageMetadataEntity();
      final pendingToolCalls = <ToolToCall>[];

      for (final toolCall in metadata.toolCalls) {
        if (!toolCall.isPending) {
          continue;
        }
        if (isToolRunning(toolCall.id)) {
          continue;
        }

        final resolvedTool = ToolResolverUtil().resolveTool(toolCall.name);

        if (resolvedTool == null) {
          continue;
        }

        final tableId = await _resolvePermissionTableId(resolvedTool);
        if (tableId != permissionTableId) {
          continue;
        }

        pendingToolCalls.add(
          .new(
            tool: resolvedTool,
            id: toolCall.id,
            argumentsRaw: toolCall.argumentsRaw,
          ),
        );
      }

      if (pendingToolCalls.isEmpty) {
        continue;
      }

      await Future.wait(
        pendingToolCalls.map(
          (toolCall) async {
            final update = await _executeSingleTool(toolCall, message.id);
            await _updateToolResults(message.id, [update]);
          },
        ),
      );

      await _checkAndRespondToAI(message.id);
    }
  }

  /// Runs a tool and returns its update (success or error).
  ///
  /// Handles both built-in tools and MCP tools.
  Future<_ToolUpdate> _runToolExecution(
    ToolToCall resolvedTool,
  ) async {
    try {
      String result;

      final argumentsJson =
          jsonDecode(resolvedTool.argumentsRaw) as Map<String, dynamic>;
      if (resolvedTool.tool.isBuiltIn) {
        final toolType = resolvedTool.tool.builtInTool;
        if (toolType == null) {
          return _ToolUpdate(
            toolCallId: resolvedTool.id,
            resultStatus: ToolCallResultStatus.toolNotFound,
          );
        }
        final input = argumentsJson['input'] as Object;
        final tools = ToolService.getTool(toolType);
        final toolResult = await tools?.runner(input).value;
        result = toolResult.toString();
      } else {
        // Execute MCP tool
        final mcpManager = ref.read(mcpManagerProvider.notifier);
        result = await mcpManager.callTool(
          mcpServerId: resolvedTool.tool.mcpServerId!,
          toolIdentifier: resolvedTool.tool.toolIdentifier,
          arguments: argumentsJson,
        );
      }

      return _ToolUpdate(
        toolCallId: resolvedTool.id,
        resultStatus: ToolCallResultStatus.success,
        responseRaw: result,
      );
    } on Exception {
      return _ToolUpdate(
        toolCallId: resolvedTool.id,
        resultStatus: ToolCallResultStatus.executionError,
      );
    }
  }

  // ============================================================
  // Helper: State management
  // ============================================================

  void _addRunningTools(Iterable<TrackedToolCall> tools) {
    state = [...state, ...tools];
  }

  void _removeRunningToolsForMessage(String messageId) {
    state = state.where((t) => t.messageId != messageId).toList();
  }

  void _removeRunningTool(String toolCallId) {
    state = state.where((t) => t.id != toolCallId).toList();
  }

  // ============================================================
  // Helper: Result persistence
  // ============================================================

  /// Update tool results in message metadata.
  ///
  /// This stores the resultStatus and optionally responseRaw for each tool.
  Future<void> _updateToolResults(
    String messageId,
    List<_ToolUpdate> updates,
  ) async {
    final repo = ref.read(messageRepositoryProvider);
    final message = await repo.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      final update = updates
          .where((u) => u.toolCallId == toolCall.id)
          .firstOrNull;
      if (update != null) {
        return toolCall.copyWith(
          resultStatus: update.resultStatus,
          responseRaw: update.responseRaw,
        );
      }
      return toolCall;
    }).toList();

    await repo.updateMessage(
      messageId,
      MessageToUpdate(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );

    // Trigger UI refresh for chat messages
    ref.read(toolUpdateRefreshTriggerProvider.notifier).trigger();
  }

  // ============================================================
  // Helper: AI response flow
  // ============================================================

  /// Checks if all tools are resolved and sends response to AI if so.
  Future<void> _checkAndRespondToAI(String messageId) async {
    final message = await ref
        .read(messageRepositoryProvider)
        .getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();

    // Check if any tools are still pending
    final hasPending = metadata.toolCalls.any(
      (t) => t.isPending && !isToolRunning(t.id),
    );

    if (!hasPending && !hasRunningToolsForMessage(messageId)) {
      await _sendAllResponsesToAI(messageId);
    }
  }

  /// Sends all tool responses to AI.
  ///
  /// Skips sending if any tool has a status that stops the agent loop.
  Future<void> _sendAllResponsesToAI(String messageId) async {
    final message = await ref
        .read(messageRepositoryProvider)
        .getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();

    // Check if any tool stopped the agent loop
    final shouldStop = metadata.toolCalls.any(
      (t) => t.resultStatus?.stopsAgentLoop ?? false,
    );
    if (shouldStop) {
      // Don't send to AI - agent loop is stopped
      return;
    }

    // Build responses using getResponseForAI() which uses
    // responseRaw if available, otherwise resultStatus.toResponseString()
    final allResponses = metadata.toolCalls
        .where((t) => t.isResolved)
        .map((t) => ToolResponseItem(id: t.id, content: t.getResponseForAI()))
        .toList();

    _sendResponsesToAI(allResponses, messageId);
  }

  void _sendResponsesToAI(List<ToolResponseItem> responses, String messageId) {
    ref
        .read(messagesManagerProvider.notifier)
        .sendToolsResponse(responses, messageId);
  }
}
