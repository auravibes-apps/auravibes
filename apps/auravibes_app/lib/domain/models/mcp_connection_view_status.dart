// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';

enum McpConnectionViewStatus { disconnected, connecting, connected, error }

enum DefaultToolGroupType { builtIn, native }

class const McpConnectionView({
  required final String serverId,
  required final McpConnectionViewStatus status,
  final String? errorMessage,
});

class const GroupedToolsViewItem({
  required final ToolsGroupEntity? group,
  required final List<WorkspaceToolEntity> tools,
  final DefaultToolGroupType? defaultGroupType,
  final McpConnectionView? mcpConnection,
}) {
  bool get isMcpGroup => group?.isMcpGroup ?? false;
  String? get mcpServerId => group?.mcpServerId;

  int get sortPriority => group == null
      ? _defaultGroupSortPriorities[defaultGroupType]!
      : _mcpConnectionSortPriorities[mcpConnection?.status]!;

  /// Returns true if this item represents a default group.
  bool get isDefaultGroup => group == null;

  /// Returns true if this group contains a tool with [toolId].
  bool containsTool(String toolId) =>
      tools.any((tool) => tool.toolId == toolId);

  /// Returns true if this group contains at least one tool.
  bool hasTools() => tools.isNotEmpty;
}

const _defaultGroupSortPriorities = <DefaultToolGroupType?, int>{
  .builtIn: 0,
  .native: 1,
  null: 0,
};

const _mcpConnectionSortPriorities = <McpConnectionViewStatus?, int>{
  .error: 2,
  .disconnected: 3,
  .connecting: 4,
  .connected: 5,
  null: 5,
};
