import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';

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
