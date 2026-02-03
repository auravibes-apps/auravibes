import 'package:auravibes_app/data/repositories/tools_groups_repository_impl.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/mcp_manager_provider.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'grouped_tools_provider.g.dart';

/// Provider for the tools groups repository.
@Riverpod(keepAlive: true)
ToolsGroupsRepository toolsGroupsRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  return ToolsGroupsRepositoryImpl(appDatabase);
}

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all tools groups for the current workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Sorts groups: Default first, then MCP errors, then by creation date
@riverpod
class GroupedToolsNotifier extends _$GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build() async {
    // Get workspace ID
    final workspaceId = await ref.watch(
      selectedWorkspaceProvider.selectAsync((w) => w.id),
    );

    // Get all tools groups for the workspace
    final toolsGroupsRepo = ref.watch(toolsGroupsRepositoryProvider);
    final groups = await toolsGroupsRepo.getToolsGroupsForWorkspace(
      workspaceId,
    );

    // Get all workspace tools
    final workspaceTools = await ref.watch(workspaceToolsProvider.future);

    // Watch MCP connections for status enrichment
    final mcpConnections = ref.watch(mcpManagerProvider);

    // Group tools by their workspaceToolsGroupId
    final toolsByGroupId = <String?, List<WorkspaceToolEntity>>{};
    for (final tool in workspaceTools) {
      final groupId = tool.workspaceToolsGroupId;
      toolsByGroupId.putIfAbsent(groupId, () => []).add(tool);
    }

    // Build result list
    final result = <ToolsGroupWithTools>[];

    // 1. Default group (tools with null groupId) - "Built-in Tools"
    final defaultTools = toolsByGroupId[null] ?? [];
    if (defaultTools.isNotEmpty) {
      result.add(
        ToolsGroupWithTools(
          group: null,
          tools: defaultTools,
        ),
      );
    }

    // 2. MCP and custom groups
    for (final group in groups) {
      final tools = toolsByGroupId[group.id] ?? [];

      // Find MCP connection state if this is an MCP group
      McpConnectionState? mcpState;
      if (group.isMcpGroup && group.mcpServerId != null) {
        mcpState = mcpConnections
            .where((c) => c.server.id == group.mcpServerId)
            .firstOrNull;
      }

      result.add(
        ToolsGroupWithTools(
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

  /// Toggle an MCP group's enabled status.
  ///
  /// When disabled:
  /// - Hides tools from AI
  /// - Disconnects the MCP server
  ///
  /// When enabled:
  /// - Shows tools to AI
  /// - Reconnects to the MCP server
  Future<void> setMcpGroupEnabled(
    String groupId, {
    required bool isEnabled,
  }) async {
    final toolsGroupsRepo = ref.read(toolsGroupsRepositoryProvider);

    // Update the group's enabled status in the database
    await toolsGroupsRepo.setToolsGroupEnabled(groupId, isEnabled: isEnabled);

    // Find the group to get MCP server ID
    final groups = state.value ?? <ToolsGroupWithTools>[];
    final group = groups.where((g) => g.group?.id == groupId).firstOrNull;

    final mcpServerId = group?.mcpServerId;
    if ((group?.isMcpGroup ?? false) && mcpServerId != null) {
      if (!isEnabled) {
        // Disconnect MCP when disabled
        ref.read(mcpManagerProvider.notifier).disconnectMcpServer(mcpServerId);
      } else {
        // Reconnect MCP when enabled
        await ref
            .read(mcpManagerProvider.notifier)
            .reconnectMcpServer(mcpServerId);
      }
    }

    // Refresh the state
    ref.invalidateSelf();
  }

  /// Delete an MCP group and its server.
  ///
  /// This will:
  /// - Disconnect from the MCP server
  /// - Delete the MCP server (cascades to tools group and tools)
  Future<void> deleteMcpGroup(String groupId) async {
    final groups = state.value ?? <ToolsGroupWithTools>[];
    final group = groups.firstWhereOrNull((g) => g.group?.id == groupId);

    final mcpServerId = group?.mcpServerId;
    if ((group?.isMcpGroup ?? false) && mcpServerId != null) {
      // deleteMcpServer handles disconnect and database cascade
      await ref.read(mcpManagerProvider.notifier).deleteMcpServer(mcpServerId);
    }

    // Refresh the state
    ref
      ..invalidateSelf()
      // Also refresh workspace tools as they've changed
      ..invalidate(workspaceToolsProvider);
  }

  /// Reconnect to an MCP server.
  Future<void> reconnectMcp(String mcpServerId) async {
    await ref.read(mcpManagerProvider.notifier).reconnectMcpServer(mcpServerId);
  }
}

/// Provider that returns the count of enabled tools across all groups.
@riverpod
Future<int> enabledToolsCount(Ref ref) async {
  final groupedTools = await ref.watch(groupedToolsProvider.future);
  return groupedTools.fold<int>(
    0,
    (sum, group) => sum + group.enabledToolsCount,
  );
}

/// Provider that returns the total count of tools across all groups.
@riverpod
Future<int> totalToolsCount(Ref ref) async {
  final groupedTools = await ref.watch(groupedToolsProvider.future);
  return groupedTools.fold<int>(
    0,
    (sum, group) => sum + group.totalToolsCount,
  );
}
