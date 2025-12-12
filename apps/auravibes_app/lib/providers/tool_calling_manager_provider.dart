import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/providers/grouped_tools_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/providers/mcp_manager_provider.dart';
import 'package:auravibes_app/providers/messages_manager_provider.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
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

/// Type of resolved tool.
enum _ResolvedToolType {
  /// A built-in tool (e.g., calculator)
  builtIn,

  /// An MCP tool from an external MCP server
  mcp,
}

/// Internal class to hold message and conversation context.
class _MessageContext {
  const _MessageContext({
    required this.message,
    required this.conversation,
  });

  final MessageEntity message;
  final ConversationEntity conversation;
}

/// Represents a resolved tool that can be either built-in or MCP.
///
/// This abstraction allows the tool calling manager to handle both types
/// uniformly while preserving the necessary information for execution.
class _ResolvedTool {
  const _ResolvedTool._({
    required this.type,
    required this.tableId,
    required this.toolIdentifier,
    this.builtInTool,
    this.mcpServerId,
  });

  /// Creates a resolved built-in tool.
  factory _ResolvedTool.builtIn({
    required String tableId,
    required String toolIdentifier,
    required UserToolEntity<Object, Object, Object> tool,
  }) {
    return _ResolvedTool._(
      type: _ResolvedToolType.builtIn,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      builtInTool: tool,
    );
  }

  /// Creates a resolved MCP tool.
  factory _ResolvedTool.mcp({
    required String tableId,
    required String toolIdentifier,
    required String mcpServerId,
  }) {
    return _ResolvedTool._(
      type: _ResolvedToolType.mcp,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      mcpServerId: mcpServerId,
    );
  }

  /// The type of tool (built-in or MCP)
  final _ResolvedToolType type;

  /// The database table ID for permission checks
  final String tableId;

  /// The tool identifier (e.g., "calculator" or original MCP tool name)
  final String toolIdentifier;

  /// The built-in tool implementation (only for built-in tools)
  final UserToolEntity<Object, Object, Object>? builtInTool;

  /// The MCP server ID (only for MCP tools)
  final String? mcpServerId;

  /// Whether this is a built-in tool
  bool get isBuiltIn => type == _ResolvedToolType.builtIn;

  /// Whether this is an MCP tool
  bool get isMcp => type == _ResolvedToolType.mcp;
}

/// Parsed components of a built-in tool composite ID.
///
/// The composite ID format is: `built_in_<table_id>_<tool_identifier>`
class _BuiltInToolIdComponents {
  const _BuiltInToolIdComponents({
    required this.tableId,
    required this.toolIdentifier,
  });

  /// The database table ID for permission checks
  final String tableId;

  /// The tool identifier (e.g., "calculator")
  final String toolIdentifier;
}

/// Internal class to hold tool resolution result.
class _ToolResolution {
  const _ToolResolution({
    required this.resolvedTool,
    required this.failureStatus,
  });

  final _ResolvedTool? resolvedTool;

  /// The status to use if tool resolution failed (null if resolved)
  final ToolCallResultStatus? failureStatus;
}

/// Internal class to hold categorized tools after permission check.
class _CategorizedTools {
  const _CategorizedTools({
    required this.grantedTools,
    required this.resolvedToolUpdates,
    required this.hasPendingConfirmation,
  });

  /// Granted tools ready for execution: (resolved tool, original tool call)
  final List<(_ResolvedTool, MessageToolCallEntity)> grantedTools;

  /// Tool updates for tools that were immediately resolved (skipped/disabled).
  final List<_ToolUpdate> resolvedToolUpdates;
  final bool hasPendingConfirmation;
}

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
    List<MessageToolCallEntity> toolCalling,
    String responseMessageId,
  ) async {
    final context = await _getMessageContext(responseMessageId);
    if (context == null) return;

    final conversationId = context.message.conversationId;
    final workspaceId = context.conversation.workspaceId;

    // Categorize tools by permission
    final categorized = await _categorizeToolsByPermission(
      toolCalling,
      conversationId: conversationId,
      workspaceId: workspaceId,
    );

    // Execute granted tools and get their updates
    final executedUpdates = await _executeToolsBatch(
      categorized.grantedTools,
      responseMessageId,
    );

    // Combine all resolved updates
    final allUpdates = [
      ...executedUpdates,
      ...categorized.resolvedToolUpdates,
    ];

    // Store updates in message metadata
    await _updateToolResults(responseMessageId, allUpdates);

    // Only continue AI loop if ALL tools were granted.
    // If any tool is not granted (needs confirmation, not found, disabled,
    // etc.) stop here and let the user handle via conversation UI.
    final allToolsGranted =
        categorized.grantedTools.length == toolCalling.length;
    if (!allToolsGranted) {
      return;
    }

    // All tools granted and executed - respond to AI
    await _sendAllResponsesToAI(responseMessageId);
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
    final context = await _getMessageContext(messageId);
    if (context == null) return;

    final conversationId = context.message.conversationId;
    final metadata = context.message.metadata ?? const MessageMetadataEntity();
    final toolCall = metadata.toolCalls
        .where((t) => t.id == toolCallId)
        .firstOrNull;
    if (toolCall == null) return;

    // If granting for conversation, persist the permission using the table ID
    if (level == ToolGrantLevel.conversation) {
      // Parse the composite ID to get the table ID for permission storage
      final resolution = _resolveTool(toolCall.name);
      final tableId = resolution.resolvedTool?.tableId;
      if (tableId != null) {
        await ref
            .read(conversationToolsRepositoryProvider)
            .setConversationToolPermission(
              conversationId,
              tableId,
              permissionMode: ToolPermissionMode.alwaysAllow,
            );
      }
    }

    // Execute the tool (bypasses permission check for "once" grants)
    final update = await _executeSingleTool(toolCall, messageId);
    await _updateToolResults(messageId, [update]);

    // Check if all tools are now resolved
    await _checkAndRespondToAI(messageId);
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

  // ============================================================
  // Helper: Context retrieval
  // ============================================================

  /// Retrieves message and its associated conversation.
  ///
  /// Returns null if either message or conversation is not found.
  Future<_MessageContext?> _getMessageContext(String messageId) async {
    final message = await ref
        .read(messageRepositoryProvider)
        .getMessageById(messageId);
    if (message == null) return null;

    final conversation = await ref
        .read(conversationRepositoryProvider)
        .getConversationById(message.conversationId);
    if (conversation == null) return null;

    return _MessageContext(message: message, conversation: conversation);
  }

  // ============================================================
  // Helper: Tool resolution
  // ============================================================

  /// Resolves a composite tool name to its implementation.
  ///
  /// Composite tool name formats:
  /// - Built-in: `built_in_<table_id>_<tool_identifier>`
  /// - MCP: `mcp_<mcp_id>_<slug_name>_<tool_identifier>`
  ///
  /// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
  /// so we use underscores as separators instead of colons.
  ///
  /// Returns the resolved tool and null failureStatus, or null tool with
  /// failureStatus.
  _ToolResolution _resolveTool(String compositeToolName) {
    // Check if it's an MCP tool
    if (compositeToolName.startsWith('mcp_')) {
      final components = McpToolIdComponents.fromComposite(
        compositeToolName,
      );
      if (components == null) {
        return const _ToolResolution(
          resolvedTool: null,
          failureStatus: ToolCallResultStatus.toolNotFound,
        );
      }

      // Verify MCP server is connected and has the tool
      final mcpManager = ref.read(mcpManagerProvider.notifier);
      final connection = mcpManager.getConnection(components.mcpServerId);
      if (connection == null || !connection.isReady) {
        return const _ToolResolution(
          resolvedTool: null,
          failureStatus: ToolCallResultStatus.toolNotFound,
        );
      }

      final toolExists = connection.tools.any(
        (t) => t.toolName == components.toolIdentifier,
      );
      if (!toolExists) {
        return const _ToolResolution(
          resolvedTool: null,
          failureStatus: ToolCallResultStatus.toolNotFound,
        );
      }

      return _ToolResolution(
        resolvedTool: _ResolvedTool.mcp(
          tableId: components.mcpServerId, // MCP server ID serves as table ID
          toolIdentifier: components.toolIdentifier,
          mcpServerId: components.mcpServerId,
        ),
        failureStatus: null,
      );
    }

    // Check if it's a built-in tool
    if (compositeToolName.startsWith('built_in_')) {
      final components = _parseBuiltInToolId(compositeToolName);
      if (components == null) {
        return const _ToolResolution(
          resolvedTool: null,
          failureStatus: ToolCallResultStatus.toolNotFound,
        );
      }

      final toolType = UserToolType.fromValue(components.toolIdentifier);
      if (toolType == null) {
        return const _ToolResolution(
          resolvedTool: null,
          failureStatus: ToolCallResultStatus.toolNotFound,
        );
      }

      final userTool = ToolService.getTool(toolType);
      if (userTool == null) {
        return const _ToolResolution(
          resolvedTool: null,
          failureStatus: ToolCallResultStatus.toolNotFound,
        );
      }

      return _ToolResolution(
        resolvedTool: _ResolvedTool.builtIn(
          tableId: components.tableId,
          toolIdentifier: components.toolIdentifier,
          tool: userTool,
        ),
        failureStatus: null,
      );
    }

    // Unknown format - tool not found
    return const _ToolResolution(
      resolvedTool: null,
      failureStatus: ToolCallResultStatus.toolNotFound,
    );
  }

  /// Parses a built-in tool composite ID.
  ///
  /// Format: `built_in_<table_id>_<tool_identifier>`
  /// Returns null if the format is invalid.
  ///
  /// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
  /// so we use underscores as separators instead of colons.
  static _BuiltInToolIdComponents? _parseBuiltInToolId(String compositeId) {
    if (!compositeId.startsWith('built_in_')) {
      return null;
    }

    // Remove 'built_in_' prefix
    final withoutPrefix = compositeId.substring(9);

    // Parse format: <table_id>_<tool_identifier>
    final firstUnderscoreIdx = withoutPrefix.indexOf('_');
    if (firstUnderscoreIdx <= 0) {
      return null;
    }

    final tableId = withoutPrefix.substring(0, firstUnderscoreIdx);
    final toolIdentifier = withoutPrefix.substring(firstUnderscoreIdx + 1);

    if (tableId.isEmpty || toolIdentifier.isEmpty) {
      return null;
    }

    return _BuiltInToolIdComponents(
      tableId: tableId,
      toolIdentifier: toolIdentifier,
    );
  }

  Future<ToolPermissionResult> _checkPermission({
    required String conversationId,
    required String workspaceId,
    required _ResolvedTool resolvedTool,
  }) async {
    final conversationToolsRepo = ref.read(conversationToolsRepositoryProvider);
    final toolsGroupsRepository = ref.read(toolsGroupsRepositoryProvider);
    final workspaceToolsRepository = ref.read(workspaceToolsRepositoryProvider);

    var toolId = resolvedTool.tableId;

    if (resolvedTool.mcpServerId != null) {
      final toolGroup = await toolsGroupsRepository.getToolsGroupByMcpServerId(
        resolvedTool.mcpServerId!,
      );

      if (toolGroup == null) {
        return ToolPermissionResult.notConfigured;
      }

      final workspaceTool = await workspaceToolsRepository
          .getWorkspaceToolByToolName(
            toolGroupId: toolGroup.id,
            toolName: resolvedTool.toolIdentifier,
          );

      if (workspaceTool == null) {
        return ToolPermissionResult.notConfigured;
      }
      toolId = workspaceTool.id;
    }

    // Check permission using the table ID for granular permissions
    return conversationToolsRepo.checkToolPermission(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolId: toolId,
    );
  }

  // ============================================================
  // Helper: Tool categorization by permission
  // ============================================================

  /// Categorizes tool calls by their permission status.
  ///
  /// Returns granted tools to execute, resolved tool updates, and
  /// whether any tools are pending confirmation.
  Future<_CategorizedTools> _categorizeToolsByPermission(
    List<MessageToolCallEntity> toolCalls, {
    required String conversationId,
    required String workspaceId,
  }) async {
    final grantedTools = <(_ResolvedTool, MessageToolCallEntity)>[];
    final resolvedToolUpdates = <_ToolUpdate>[];
    var hasPendingConfirmation = false;

    for (final tool in toolCalls) {
      // First resolve the tool implementation
      final resolution = _resolveTool(tool.name);
      if (resolution.resolvedTool == null) {
        resolvedToolUpdates.add(
          _ToolUpdate(
            toolCallId: tool.id,
            resultStatus: resolution.failureStatus!,
          ),
        );
        continue;
      }

      final permission = await _checkPermission(
        conversationId: conversationId,
        workspaceId: workspaceId,
        resolvedTool: resolution.resolvedTool!,
      );

      switch (permission) {
        case ToolPermissionResult.granted:
          grantedTools.add((resolution.resolvedTool!, tool));

        case ToolPermissionResult.needsConfirmation:
          hasPendingConfirmation = true;
        // Don't add to resolved - leave as pending

        case ToolPermissionResult.notConfigured:
          resolvedToolUpdates.add(
            _ToolUpdate(
              toolCallId: tool.id,
              resultStatus: ToolCallResultStatus.notConfigured,
            ),
          );

        case ToolPermissionResult.disabledInConversation:
          resolvedToolUpdates.add(
            _ToolUpdate(
              toolCallId: tool.id,
              resultStatus: ToolCallResultStatus.disabledInConversation,
            ),
          );

        case ToolPermissionResult.disabledInWorkspace:
          resolvedToolUpdates.add(
            _ToolUpdate(
              toolCallId: tool.id,
              resultStatus: ToolCallResultStatus.disabledInWorkspace,
            ),
          );
      }
    }

    return _CategorizedTools(
      grantedTools: grantedTools,
      resolvedToolUpdates: resolvedToolUpdates,
      hasPendingConfirmation: hasPendingConfirmation,
    );
  }

  // ============================================================
  // Helper: Tool execution
  // ============================================================

  /// Executes a batch of granted tools and returns their updates.
  Future<List<_ToolUpdate>> _executeToolsBatch(
    List<(_ResolvedTool, MessageToolCallEntity)> grantedTools,
    String messageId,
  ) async {
    if (grantedTools.isEmpty) return [];

    // Track running tools in state
    _addRunningTools(
      grantedTools.map(
        (t) => TrackedToolCall(
          id: t.$2.id,
          toolName: t.$2.name,
          messageId: messageId,
          isRunning: true,
        ),
      ),
    );

    // Execute all tools
    final updates = <_ToolUpdate>[];
    for (final (resolvedTool, toolCall) in grantedTools) {
      final update = await _runToolExecution(resolvedTool, toolCall);
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
    MessageToolCallEntity toolCall,
    String messageId,
  ) async {
    final resolution = _resolveTool(toolCall.name);
    if (resolution.resolvedTool == null) {
      return _ToolUpdate(
        toolCallId: toolCall.id,
        resultStatus: resolution.failureStatus!,
      );
    }

    // Track as running
    _addRunningTools([
      TrackedToolCall(
        id: toolCall.id,
        toolName: toolCall.name,
        messageId: messageId,
        isRunning: true,
      ),
    ]);

    // Execute the tool
    final update = await _runToolExecution(resolution.resolvedTool!, toolCall);

    // Remove from running state
    _removeRunningTool(toolCall.id);

    return update;
  }

  /// Runs a tool and returns its update (success or error).
  ///
  /// Handles both built-in tools and MCP tools.
  Future<_ToolUpdate> _runToolExecution(
    _ResolvedTool resolvedTool,
    MessageToolCallEntity toolCall,
  ) async {
    try {
      String result;

      if (resolvedTool.isBuiltIn) {
        // Execute built-in tool
        final userTool = resolvedTool.builtInTool!;
        final input = toolCall.arguments['input'] as Object;
        final toolResult = await userTool.runner(input).value;
        result = toolResult.toString();
      } else {
        // Execute MCP tool
        final mcpManager = ref.read(mcpManagerProvider.notifier);
        result = await mcpManager.callTool(
          mcpServerId: resolvedTool.mcpServerId!,
          toolIdentifier: resolvedTool.toolIdentifier,
          arguments: toolCall.arguments,
        );
      }

      return _ToolUpdate(
        toolCallId: toolCall.id,
        resultStatus: ToolCallResultStatus.success,
        responseRaw: result,
      );
    } on Exception {
      return _ToolUpdate(
        toolCallId: toolCall.id,
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
