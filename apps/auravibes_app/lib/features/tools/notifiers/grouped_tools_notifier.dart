// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/usecases/build_grouped_tools_view_use_case.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'grouped_tools_notifier.g.dart';

/// Provider for the tools groups repository.
@Dependencies([workspaceSession, cloudWorkspaceStateGateway])
@riverpod
ToolsGroupsRepositoryContract toolsGroupsRepository(Ref ref) {
  if (ref.watch(workspaceSessionProvider).cloud != null) {
    return CloudToolsRepository(
      ref.read(cloudWorkspaceStateGatewayProvider.future),
    );
  }
  final appDatabase = ref.watch(appDatabaseProvider);

  return ToolsGroupsRepository(appDatabase);
}

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all tools groups for the current workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Sorts groups: Default first, then MCP errors, then by creation date
@Dependencies([
  mcpServersRepository,
  workspaceSession,
  cloudWorkspaceStateGateway,
])
@riverpod
class GroupedToolsNotifier extends _$GroupedToolsNotifier {
  String _workspaceId = '';

  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async {
    _workspaceId = workspaceId;
    final toolsGroupsRepo = ref.watch(toolsGroupsRepositoryProvider);
    final groups = await toolsGroupsRepo.getToolsGroupsForWorkspace(
      workspaceId,
    );

    final workspaceTools = await ref.watch(
      workspaceToolsProvider(workspaceId).future,
    );
    final mcpConnections = ref.watch(mcpConnectionProvider);
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
    final repository = ref.read(toolsGroupsRepositoryProvider);
    final isCloud = repository is CloudToolsRepository;
    final group = await repository.getToolsGroupById(groupId);
    if (group == null || (!isCloud && group.workspaceId != _workspaceId)) {
      return;
    }

    final didUpdate = await repository.setToolsGroupEnabled(
      groupId,
      isEnabled: isEnabled,
    );
    if (!didUpdate) {
      return;
    }

    final mcpServerId = group.mcpServerId;
    if (!isCloud && group.isMcpGroup && mcpServerId != null) {
      if (!isEnabled) {
        ref
            .read(mcpConnectionProvider.notifier)
            .disconnectMcpServer(mcpServerId);
      } else {
        await ref
            .read(mcpConnectionProvider.notifier)
            .reconnectMcpServer(mcpServerId);
      }
    }

    ref.invalidateSelf();
  }

  /// Delete an MCP group and its server.
  ///
  /// This will:
  /// - Disconnect from the MCP server
  /// - Delete the MCP server (cascades to tools group and tools)
  Future<void> deleteMcpGroup(String groupId) async {
    final repository = ref.read(toolsGroupsRepositoryProvider);
    final isCloud = repository is CloudToolsRepository;
    final group = await repository.getToolsGroupById(groupId);
    if (group == null || (!isCloud && group.workspaceId != _workspaceId)) {
      return;
    }
    final mcpServerId = group.mcpServerId;
    if (!group.isMcpGroup || mcpServerId == null) {
      return;
    }

    if (isCloud) {
      final _ = await ref
          .read(mcpServersRepositoryProvider)
          .deleteMcpServer(mcpServerId);
    } else {
      await ref
          .read(mcpConnectionProvider.notifier)
          .deleteMcpServer(mcpServerId);
    }

    ref
      ..invalidateSelf()
      ..invalidate(workspaceToolsProvider(_workspaceId));
  }

  /// Reconnect to an MCP server.
  Future<void> reconnectMcp(String mcpServerId) async {
    final repository = ref.read(mcpServersRepositoryProvider);
    if (repository case final CloudToolsRepository cloudRepository) {
      final _ = await cloudRepository.discoverMcpServer(mcpServerId);
      ref.invalidateSelf();

      return;
    }
    await ref
        .read(mcpConnectionProvider.notifier)
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
    defaultGroupType: item.defaultGroupType,
    mcpConnectionState: mcpConnectionState,
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
Future<int> enabledToolsCount(Ref ref, String workspaceId) async {
  final groupedTools = await ref.watch(
    groupedToolsProvider(workspaceId).future,
  );

  return groupedTools.fold<int>(
    0,
    (sum, group) => sum + group.enabledToolsCount,
  );
}

/// Provider that returns the total count of tools across all groups.
@riverpod
Future<int> totalToolsCount(Ref ref, String workspaceId) async {
  final groupedTools = await ref.watch(
    groupedToolsProvider(workspaceId).future,
  );

  return groupedTools.fold<int>(
    0,
    (sum, group) => sum + group.totalToolsCount,
  );
}
