// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:collection/collection.dart';

class const BuildGroupedToolsViewUseCase() {
  List<GroupedToolsViewItem> call({
    required List<WorkspaceToolEntity> workspaceTools,
    required List<ToolsGroupEntity> groups,
    required List<McpConnectionView> mcpConnections,
  }) {
    final toolsByGroupId = _indexTools(workspaceTools);

    return _defaultToolGroups(toolsByGroupId)
      ..addAll(
        _configuredToolGroups(
          groups: groups,
          mcpConnections: mcpConnections,
          toolsByGroupId: toolsByGroupId,
        ),
      )
      ..sort(_compareToolGroups);
  }
}

Map<String?, List<WorkspaceToolEntity>> _indexTools(
  List<WorkspaceToolEntity> tools,
) {
  final toolsByGroupId = <String?, List<WorkspaceToolEntity>>{};
  for (final tool in tools) {
    toolsByGroupId.putIfAbsent(tool.workspaceToolsGroupId, () => []).add(tool);
  }

  return toolsByGroupId;
}

List<GroupedToolsViewItem> _defaultToolGroups(
  Map<String?, List<WorkspaceToolEntity>> toolsByGroupId,
) {
  final defaultTools = toolsByGroupId[null] ?? [];
  final builtInTools = defaultTools.where((tool) => !tool.isNative).toList();
  final nativeTools = defaultTools.where((tool) => tool.isNative).toList();

  return [
    if (builtInTools.isNotEmpty)
      GroupedToolsViewItem(
        group: null,
        tools: builtInTools,
        defaultGroupType: .builtIn,
      ),
    if (nativeTools.isNotEmpty)
      GroupedToolsViewItem(
        group: null,
        tools: nativeTools,
        defaultGroupType: .native,
      ),
  ];
}

List<GroupedToolsViewItem> _configuredToolGroups({
  required List<ToolsGroupEntity> groups,
  required List<McpConnectionView> mcpConnections,
  required Map<String?, List<WorkspaceToolEntity>> toolsByGroupId,
}) => [
  for (final group in groups)
    GroupedToolsViewItem(
      group: group,
      tools: toolsByGroupId[group.id] ?? [],
      mcpConnection: _mcpConnectionFor(group, mcpConnections),
    ),
];

McpConnectionView? _mcpConnectionFor(
  ToolsGroupEntity group,
  List<McpConnectionView> mcpConnections,
) {
  if (!group.isMcpGroup || group.mcpServerId == null) return null;

  return mcpConnections
      .where((connection) => connection.serverId == group.mcpServerId)
      .firstOrNull;
}

int _compareToolGroups(GroupedToolsViewItem a, GroupedToolsViewItem b) {
  final priorityCompare = a.sortPriority.compareTo(b.sortPriority);
  if (priorityCompare != 0) return priorityCompare;

  final aDate = a.group?.createdAt ?? DateTime(2099);
  final bDate = b.group?.createdAt ?? DateTime(2099);

  return bDate.compareTo(aDate);
}
