// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/usecases/build_grouped_tools_view_use_case.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'grouped_tools_notifier.g.dart';

typedef _McpGroupOperation = ({
  ToolsGroupsRepositoryContract repository,
  ToolsGroupEntity group,
  bool isCloud,
});

/// Provider for the tools groups repository.
@riverpod
ToolsGroupsRepositoryContract toolsGroupsRepository(
  Ref ref,
  WorkspaceSession session,
) {
  if (session.cloud != null) {
    return CloudToolsRepository(
      ref.read(cloudWorkspaceStateGatewayProvider(session).future),
    );
  }
  final appDatabase = ref.watch(appDatabaseProvider);

  return ToolsGroupsRepository(appDatabase);
}

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider fetches tool groups for the current workspace, groups tools
/// by workspaceToolsGroupId, creates a Built-in Tools group for ungrouped
/// tools, enriches MCP groups with connection state, and sorts default, error,
/// and newest groups first.
@riverpod
class GroupedToolsNotifier extends _$GroupedToolsNotifier {
  String _workspaceId = '';
  WorkspaceSession? _session;

  WorkspaceSession get _requiredSession {
    final session = _session;
    if (session == null) {
      throw StateError('GroupedToolsNotifier is not initialized');
    }

    return session;
  }

  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async {
    _workspaceId = workspaceId;
    final session = await ref.watch(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    _session = session;

    return await _loadGroupedTools(ref, workspaceId, session);
  }

  /// Toggle an MCP group's enabled status.
  ///
  /// When disabled, this hides tools from AI and disconnects the MCP server.
  /// When enabled, this shows tools to AI and reconnects to the MCP server.
  Future<void> setMcpGroupEnabled(
    String groupId, {
    required bool isEnabled,
  }) async {
    final operation = await _groupOperation(groupId);
    if (operation == null) return;

    final didUpdate = await _updateMcpGroup(ref, (
      groupId: groupId,
      operation: operation,
      isEnabled: isEnabled,
    ));
    if (!didUpdate) return;

    ref.invalidateSelf();
  }

  /// Delete an MCP group and its server.
  ///
  /// This disconnects from the MCP server and deletes it, cascading to its
  /// tools group and tools.
  Future<void> deleteMcpGroup(String groupId) async {
    final operation = await _groupOperation(groupId);
    if (operation == null) return;
    final didDelete = await _deleteMcpGroup(operation);
    if (!didDelete) return;

    ref
      ..invalidateSelf()
      ..invalidate(workspaceToolsProvider(_workspaceId));
  }

  /// Reconnect to an MCP server.
  Future<void> reconnectMcp(String mcpServerId) async {
    final repository = ref.read(
      toolsGroupsRepositoryProvider(_requiredSession),
    );
    if (repository case final CloudToolsRepository cloudRepository) {
      final _ = await cloudRepository.discoverMcpServer(mcpServerId);
      ref.invalidateSelf();

      return;
    }
    await ref
        .read(mcpConnectionProvider.notifier)
        .reconnectMcpServer(mcpServerId);
  }

  Future<_McpGroupOperation?> _groupOperation(String groupId) async {
    final repository = ref.read(
      toolsGroupsRepositoryProvider(_requiredSession),
    );
    final isCloud = repository is CloudToolsRepository;
    final group = await _findWorkspaceGroup(repository, groupId, (
      workspaceId: _workspaceId,
      isCloud: isCloud,
    ));

    return group == null
        ? null
        : (repository: repository, group: group, isCloud: isCloud);
  }

  Future<bool> _deleteMcpGroup(
    ({
      ToolsGroupsRepositoryContract repository,
      ToolsGroupEntity group,
      bool isCloud,
    })
    operation,
  ) async {
    final mcpServerId = operation.group.mcpServerId;
    if (!operation.group.isMcpGroup || mcpServerId == null) return false;

    await _deleteMcpServer(ref, mcpServerId, (
      isCloud: operation.isCloud,
      session: _requiredSession,
    ));

    return true;
  }
}

Future<bool> _updateMcpGroup(
  Ref ref,
  ({String groupId, _McpGroupOperation operation, bool isEnabled}) request,
) async {
  final operation = request.operation;
  final didUpdate = await operation.repository.setToolsGroupEnabled(
    request.groupId,
    isEnabled: request.isEnabled,
  );
  if (!didUpdate) return false;

  await _syncMcpGroup(ref, operation.group, (
    isEnabled: request.isEnabled,
    isCloud: operation.isCloud,
  ));
  return true;
}

Future<List<ToolsGroupWithTools>> _loadGroupedTools(
  Ref ref,
  String workspaceId,
  WorkspaceSession session,
) async {
  final groupedTools = await _loadGroupedToolItems(ref, workspaceId, session);
  final connectionsByServerId = _connectionsByServerId(
    ref.watch(mcpConnectionProvider),
  );

  return groupedTools
      .map(
        (item) => _toToolsGroupWithTools(
          item,
          connectionsByServerId[item.mcpServerId],
        ),
      )
      .toList();
}

Future<List<GroupedToolsViewItem>> _loadGroupedToolItems(
  Ref ref,
  String workspaceId,
  WorkspaceSession session,
) async {
  final repository = ref.watch(toolsGroupsRepositoryProvider(session));
  final groups = await repository.getToolsGroupsForWorkspace(workspaceId);
  final workspaceTools = await ref.watch(
    workspaceToolsProvider(workspaceId).future,
  );
  final connections = ref.watch(mcpConnectionProvider);

  return _buildGroupedTools(workspaceTools, groups, connections);
}

Map<String, McpConnectionState> _connectionsByServerId(
  List<McpConnectionState> connections,
) => {for (final connection in connections) connection.server.id: connection};

McpConnectionView _toMcpConnectionView(McpConnectionState connection) =>
    McpConnectionView(
      serverId: connection.server.id,
      status: _toMcpConnectionViewStatus(connection.status),
      errorMessage: connection.errorMessage,
    );

Future<ToolsGroupEntity?> _findWorkspaceGroup(
  ToolsGroupsRepositoryContract repository,
  String groupId,
  ({String workspaceId, bool isCloud}) context,
) async {
  final group = await repository.getToolsGroupById(groupId);
  if (group == null ||
      (!context.isCloud && group.workspaceId != context.workspaceId)) {
    return null;
  }

  return group;
}

Future<void> _syncMcpGroup(
  Ref ref,
  ToolsGroupEntity group,
  ({bool isEnabled, bool isCloud}) options,
) async {
  final mcpServerId = group.mcpServerId;
  if (options.isCloud || !group.isMcpGroup || mcpServerId == null) return;
  final notifier = ref.read(mcpConnectionProvider.notifier);
  if (options.isEnabled) {
    await notifier.reconnectMcpServer(mcpServerId);
  } else {
    notifier.disconnectMcpServer(mcpServerId);
  }
}

Future<void> _deleteMcpServer(
  Ref ref,
  String mcpServerId,
  ({bool isCloud, WorkspaceSession session}) options,
) async {
  if (options.isCloud) {
    final _ = await ref
        .read(mcpServersRepositoryProvider(options.session))
        .deleteMcpServer(mcpServerId);

    return;
  }

  await ref.read(mcpConnectionProvider.notifier).deleteMcpServer(mcpServerId);
}

List<GroupedToolsViewItem> _buildGroupedTools(
  List<WorkspaceToolEntity> workspaceTools,
  List<ToolsGroupEntity> groups,
  List<McpConnectionState> connections,
) => const BuildGroupedToolsViewUseCase().call(
  workspaceTools: workspaceTools,
  groups: groups,
  mcpConnections: connections.map(_toMcpConnectionView).toList(),
);

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
    .disconnected => McpConnectionViewStatus.disconnected,
    .connecting => McpConnectionViewStatus.connecting,
    .connected => McpConnectionViewStatus.connected,
    .error => McpConnectionViewStatus.error,
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

  return groupedTools.fold<int>(0, (sum, group) => sum + group.totalToolsCount);
}
