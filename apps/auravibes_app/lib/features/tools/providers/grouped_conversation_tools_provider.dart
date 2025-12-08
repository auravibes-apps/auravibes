import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/providers/grouped_tools_provider.dart';
import 'package:auravibes_app/providers/mcp_manager_provider.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'grouped_conversation_tools_provider.g.dart';

/// Provider that groups conversation tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all conversation tool states for the workspace/conversation
/// - Fetches all tools groups for the workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Filters out empty groups
/// - Sorts groups: Default first, then MCP errors, then by creation date
@riverpod
class GroupedConversationToolsNotifier
    extends _$GroupedConversationToolsNotifier {
  @override
  Future<List<ConversationToolsGroupWithTools>> build({
    required String workspaceId,
    String? conversationId,
  }) async {
    // Get all conversation tool states
    final conversationTools = await ref.watch(
      conversationToolsProvider(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ).future,
    );

    // Get all tools groups for the workspace
    final toolsGroupsRepo = ref.watch(toolsGroupsRepositoryProvider);
    final groups = await toolsGroupsRepo.getToolsGroupsForWorkspace(
      workspaceId,
    );

    // Watch MCP connections for status enrichment
    final mcpConnections = ref.watch(mcpManagerProvider);

    // Group tools by their workspaceToolsGroupId
    final toolsByGroupId = <String?, List<ConversationToolState>>{};
    for (final toolState in conversationTools) {
      final groupId = toolState.tool.workspaceToolsGroupId;
      toolsByGroupId.putIfAbsent(groupId, () => []).add(toolState);
    }

    // Build result list
    final result = <ConversationToolsGroupWithTools>[];

    // 1. Default group (tools with null groupId) - "Built-in Tools"
    final defaultTools = toolsByGroupId[null] ?? [];
    if (defaultTools.isNotEmpty) {
      result.add(
        ConversationToolsGroupWithTools(
          group: null,
          tools: defaultTools,
        ),
      );
    }

    // 2. MCP and custom groups (only include non-empty groups)
    for (final group in groups) {
      final tools = toolsByGroupId[group.id] ?? [];

      // Skip empty groups
      if (tools.isEmpty) continue;

      // Find MCP connection state if this is an MCP group
      McpConnectionState? mcpState;
      if (group.isMcpGroup && group.mcpServerId != null) {
        mcpState = mcpConnections
            .where((c) => c.server.id == group.mcpServerId)
            .firstOrNull;
      }

      result.add(
        ConversationToolsGroupWithTools(
          group: group,
          tools: tools,
          mcpConnectionState: mcpState,
        ),
      );
    }

    // Sort: Default first, then by priority (errors first), then by
    // createdAt desc
    result.sort((a, b) {
      final priorityCompare = a.sortPriority.compareTo(b.sortPriority);
      if (priorityCompare != 0) return priorityCompare;

      // Same priority: sort by createdAt desc (newest first)
      // Default group has no createdAt, use a far-future date to keep it first
      final aDate = a.group?.createdAt ?? DateTime(2099);
      final bDate = b.group?.createdAt ?? DateTime(2099);
      return bDate.compareTo(aDate);
    });

    return result;
  }

  /// Toggle all tools in a group at once.
  ///
  /// When [enabled] is true, enables all tools in the group.
  /// When [enabled] is false, disables all tools in the group.
  /// Preserves the permission mode of each tool.
  Future<void> toggleGroupTools(
    String? groupId, {
    required bool enabled,
  }) async {
    final conversationNotifier = ref.read(
      conversationToolsProvider(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ).notifier,
    );

    final currentGroups = state.value ?? [];
    final group = currentGroups.firstWhereOrNull(
      (g) => g.group?.id == groupId || (groupId == null && g.isDefaultGroup),
    );
    if (group == null) return;

    // Toggle each tool in the group
    for (final toolState in group.tools) {
      await conversationNotifier.setToolEnabled(
        toolState.tool.id,
        isEnabled: enabled,
      );
    }

    // The state will be automatically refreshed via the watch on
    // conversationToolsProvider
  }

  /// Reconnect to an MCP server.
  Future<void> reconnectMcp(String mcpServerId) async {
    await ref.read(mcpManagerProvider.notifier).reconnectMcpServer(mcpServerId);
  }
}
