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

  int get sortPriority {
    if (group == null) {
      return switch (defaultGroupType) {
        DefaultToolGroupType.builtIn => 0,
        DefaultToolGroupType.native => 1,
        null => 0,
      };
    }

    const errorIndex = 2;
    const disconnectedIndex = 3;
    const connectingIndex = 4;
    const connectedIndex = 5;

    return switch (mcpConnection?.status) {
      McpConnectionViewStatus.error => errorIndex,
      McpConnectionViewStatus.disconnected => disconnectedIndex,
      McpConnectionViewStatus.connecting => connectingIndex,
      McpConnectionViewStatus.connected => connectedIndex,
      null => connectedIndex,
    };
  }
}
