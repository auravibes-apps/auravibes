// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
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
    final builtInTools = defaultTools.where((tool) => !tool.isNative).toList();
    final nativeTools = defaultTools.where((tool) => tool.isNative).toList();

    if (builtInTools.isNotEmpty) {
      result.add(
        GroupedToolsViewItem(
          group: null,
          tools: builtInTools,
          defaultGroupType: DefaultToolGroupType.builtIn,
        ),
      );
    }
    if (nativeTools.isNotEmpty) {
      result.add(
        GroupedToolsViewItem(
          group: null,
          tools: nativeTools,
          defaultGroupType: DefaultToolGroupType.native,
        ),
      );
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
