// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';

enum McpConnectionViewStatus { disconnected, connecting, connected, error }

enum DefaultToolGroupType { builtIn, native }

class McpConnectionView {
  const McpConnectionView({
    required this.serverId,
    required this.status,
    this.errorMessage,
  });

  final String serverId;
  final McpConnectionViewStatus status;
  final String? errorMessage;
}

class GroupedToolsViewItem {
  const GroupedToolsViewItem({
    required this.group,
    required this.tools,
    this.defaultGroupType,
    this.mcpConnection,
  });

  final ToolsGroupEntity? group;
  final List<WorkspaceToolEntity> tools;
  final DefaultToolGroupType? defaultGroupType;
  final McpConnectionView? mcpConnection;

  bool get isMcpGroup => group?.isMcpGroup ?? false;
  String? get mcpServerId => group?.mcpServerId;

  int get sortPriority {
    if (group == null) {
      return switch (defaultGroupType) {
        DefaultToolGroupType.builtIn => 0,
        DefaultToolGroupType.native => 1,
        null => 0,
      };
    }

    if (mcpConnection?.status == McpConnectionViewStatus.error) {
      return 2;
    }
    if (mcpConnection?.status == McpConnectionViewStatus.disconnected) {
      return 3;
    }
    if (mcpConnection?.status == McpConnectionViewStatus.connecting) {
      return 4;
    }
    return 5;
  }
}
