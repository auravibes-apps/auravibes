import 'package:auravibes_app/data/repositories/tools_groups_repository_impl.dart';
import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/groups/build_grouped_tools_view_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/groups/delete_mcp_group_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/groups/set_mcp_group_enabled_usecase.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/mcp_connection_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'grouped_tools_controller.g.dart';

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
class GroupedToolsController extends _$GroupedToolsController {
  @override
  Future<List<ToolsGroupWithTools>> build() async {
    final workspaceId = await ref.watch(
      selectedWorkspaceProvider.selectAsync((w) => w.id),
    );

    final toolsGroupsRepo = ref.watch(toolsGroupsRepositoryProvider);
    final groups = await toolsGroupsRepo.getToolsGroupsForWorkspace(
      workspaceId,
    );

    final workspaceTools = await ref.watch(workspaceToolsProvider.future);
    final mcpConnections = ref.watch(mcpConnectionControllerProvider);
    final mcpConnectionsByServerId = {
      for (final connection in mcpConnections) connection.server.id: connection,
    };

    final groupedTools = const BuildGroupedToolsViewUseCase().call(
      workspaceTools: workspaceTools,
      groups: groups,
      mcpConnections: mcpConnections
          .map(
            (connection) => McpConnectionView(
              serverId: connection.server.id,
              status: _toMcpConnectionViewStatus(connection.status),
              errorMessage: connection.errorMessage,
            ),
          )
          .toList(),
    );

    return groupedTools
        .map(
          (item) => _toToolsGroupWithTools(
            item,
            mcpConnectionsByServerId[item.mcpServerId],
          ),
        )
        .toList();
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
    final useCase = SetMcpGroupEnabledUseCase(
      setToolsGroupEnabled: ref
          .read(toolsGroupsRepositoryProvider)
          .setToolsGroupEnabled,
    );

    await useCase.call(
      groupId: groupId,
      isEnabled: isEnabled,
      groups: (state.value ?? const <ToolsGroupWithTools>[])
          .map(_toGroupedToolsViewItem)
          .toList(),
      disconnectMcpServer: ref
          .read(mcpConnectionControllerProvider.notifier)
          .disconnectMcpServer,
      reconnectMcpServer: ref
          .read(mcpConnectionControllerProvider.notifier)
          .reconnectMcpServer,
    );

    ref.invalidateSelf();
  }

  /// Delete an MCP group and its server.
  ///
  /// This will:
  /// - Disconnect from the MCP server
  /// - Delete the MCP server (cascades to tools group and tools)
  Future<void> deleteMcpGroup(String groupId) async {
    await const DeleteMcpGroupUseCase().call(
      groupId: groupId,
      groups: (state.value ?? const <ToolsGroupWithTools>[])
          .map(_toGroupedToolsViewItem)
          .toList(),
      deleteMcpServer: ref
          .read(mcpConnectionControllerProvider.notifier)
          .deleteMcpServer,
    );

    ref
      ..invalidateSelf()
      ..invalidate(workspaceToolsProvider);
  }

  /// Reconnect to an MCP server.
  Future<void> reconnectMcp(String mcpServerId) async {
    await ref
        .read(mcpConnectionControllerProvider.notifier)
        .reconnectMcpServer(mcpServerId);
  }
}

ToolsGroupWithTools _toToolsGroupWithTools(
  GroupedToolsViewItem item,
  McpConnectionState? mcpConnectionState,
) {
  return ToolsGroupWithTools(
    group: item.group,
    tools: item.tools,
    mcpConnectionState: mcpConnectionState,
  );
}

GroupedToolsViewItem _toGroupedToolsViewItem(ToolsGroupWithTools item) {
  return GroupedToolsViewItem(
    group: item.group,
    tools: item.tools,
    mcpConnection: switch (item.mcpConnectionState) {
      null => null,
      final state => McpConnectionView(
        serverId: state.server.id,
        status: _toMcpConnectionViewStatus(state.status),
        errorMessage: state.errorMessage,
      ),
    },
  );
}

McpConnectionViewStatus _toMcpConnectionViewStatus(McpConnectionStatus status) {
  return switch (status) {
    McpConnectionStatus.disconnected => McpConnectionViewStatus.disconnected,
    McpConnectionStatus.connecting => McpConnectionViewStatus.connecting,
    McpConnectionStatus.connected => McpConnectionViewStatus.connected,
    McpConnectionStatus.error => McpConnectionViewStatus.error,
  };
}

/// Provider that returns the count of enabled tools across all groups.
@riverpod
Future<int> enabledToolsCount(Ref ref) async {
  final groupedTools = await ref.watch(groupedToolsControllerProvider.future);
  return groupedTools.fold<int>(
    0,
    (sum, group) => sum + group.enabledToolsCount,
  );
}

/// Provider that returns the total count of tools across all groups.
@riverpod
Future<int> totalToolsCount(Ref ref) async {
  final groupedTools = await ref.watch(groupedToolsControllerProvider.future);
  return groupedTools.fold<int>(
    0,
    (sum, group) => sum + group.totalToolsCount,
  );
}
