import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tools_group_with_tools.freezed.dart';

/// A tools group combined with its tools and MCP connection state.
///
/// This model is used to display tools organized by their group
/// in the tools management UI.
@freezed
abstract class ToolsGroupWithTools with _$ToolsGroupWithTools {
  @Assert('group != null || defaultGroupType != null')
  const factory ToolsGroupWithTools({
    /// The tools group entity, or null for a virtual default tools group.
    required ToolsGroupEntity? group,

    /// The list of tools belonging to this group.
    required List<WorkspaceToolEntity> tools,

    /// The virtual default group type when [group] is null.
    DefaultToolGroupType? defaultGroupType,

    /// The MCP connection state for MCP groups, null for non-MCP groups.
    McpConnectionState? mcpConnectionState,
  }) = _ToolsGroupWithTools;

  const ToolsGroupWithTools._();

  /// Returns true if this is a virtual default group.
  bool get isDefaultGroup => group == null;

  bool get isNativeDefaultGroup =>
      isDefaultGroup && defaultGroupType == DefaultToolGroupType.native;

  /// Returns true if this group is linked to an MCP server.
  bool get isMcpGroup => group?.isMcpGroup ?? false;

  String? get localizedDisplayNameKey {
    if (!isDefaultGroup) return null;
    return switch (defaultGroupType) {
      .native => LocaleKeys.tools_screen_native_group,
      _ => LocaleKeys.tools_screen_default_group,
    };
  }

  /// Returns the number of enabled tools in this group.
  int get enabledToolsCount => tools.where((t) => t.isEnabled).length;

  /// Returns the total number of tools in this group.
  int get totalToolsCount => tools.length;

  /// Returns true if this group is enabled.
  ///
  /// Default group is always enabled.
  bool get isEnabled => group?.isEnabled ?? true;

  /// Returns the MCP connection status, or null for non-MCP groups.
  McpConnectionStatus? get mcpStatus => mcpConnectionState?.status;

  /// Returns the MCP server ID if this is an MCP group.
  String? get mcpServerId => group?.mcpServerId;

  /// Returns true if the MCP connection has an error.
  bool get hasMcpError => mcpStatus == McpConnectionStatus.error;

  /// Returns true if the MCP connection is disconnected.
  bool get isMcpDisconnected => mcpStatus == McpConnectionStatus.disconnected;

  /// Returns true if the MCP connection is currently connecting.
  bool get isMcpConnecting => mcpStatus == McpConnectionStatus.connecting;

  /// Returns true if the MCP connection is connected.
  bool get isMcpConnected => mcpStatus == McpConnectionStatus.connected;

  /// Returns true if this MCP group needs attention (error or disconnected).
  bool get needsAttention => hasMcpError || isMcpDisconnected;

  /// Returns the MCP error message, or null if no error.
  String? get mcpErrorMessage => mcpConnectionState?.errorMessage;

  /// Returns a truncated error message (max 50 chars).
  String? get truncatedErrorMessage {
    final message = mcpErrorMessage;
    if (message == null) return null;
    if (message.length <= 50) return message;
    return '${message.substring(0, 47)}...';
  }

  /// Sort priority for ordering groups in the list.
  ///
  /// Lower values appear first:
  /// 0 = Built-in default group
  /// 1 = Native default group
  /// 2 = MCP with error (needs immediate attention)
  /// 3 = MCP disconnected (needs attention)
  /// 4 = MCP connecting
  /// 5 = MCP connected or non-MCP groups
  int get sortPriority {
    if (isDefaultGroup) {
      return switch (defaultGroupType) {
        .native => 1,
        _ => 0,
      };
    }
    if (hasMcpError) return 2;
    if (isMcpDisconnected) return 3;
    if (isMcpConnecting) return 4;
    return 5;
  }
}
