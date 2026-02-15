import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:collection/collection.dart';

class BuildGroupedToolsViewUseCase {
  const BuildGroupedToolsViewUseCase();

  List<GroupedToolsViewItem> call({
    required List<WorkspaceToolEntity> workspaceTools,
    required List<ToolsGroupEntity> groups,
    required List<McpConnectionView> mcpConnections,
  }) {
    final toolsByGroupId = <String?, List<WorkspaceToolEntity>>{};
    for (final tool in workspaceTools) {
      final groupId = tool.workspaceToolsGroupId;
      toolsByGroupId.putIfAbsent(groupId, () => []).add(tool);
    }

    final result = <GroupedToolsViewItem>[];
    final defaultTools = toolsByGroupId[null] ?? [];
    if (defaultTools.isNotEmpty) {
      result.add(GroupedToolsViewItem(group: null, tools: defaultTools));
    }

    for (final group in groups) {
      McpConnectionView? mcpState;
      if (group.isMcpGroup && group.mcpServerId != null) {
        mcpState = mcpConnections
            .where((connection) => connection.serverId == group.mcpServerId)
            .firstOrNull;
      }

      result.add(
        GroupedToolsViewItem(
          group: group,
          tools: toolsByGroupId[group.id] ?? [],
          mcpConnection: mcpState,
        ),
      );
    }

    result.sort((a, b) {
      final priorityCompare = a.sortPriority.compareTo(b.sortPriority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      final aDate = a.group?.createdAt ?? DateTime(2099);
      final bDate = b.group?.createdAt ?? DateTime(2099);
      return bDate.compareTo(aDate);
    });

    return result;
  }
}
