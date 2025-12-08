import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/providers/mcp_manager_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_tools_group_with_tools.freezed.dart';

/// A tools group combined with its conversation tool states and MCP connection.
///
/// This model is used to display tools organized by their group
/// in the conversation tools management modal.
@freezed
abstract class ConversationToolsGroupWithTools
    with _$ConversationToolsGroupWithTools {
  const factory ConversationToolsGroupWithTools({
    /// The tools group entity, or null for the "Built-in Tools" default group.
    required ToolsGroupEntity? group,

    /// The list of tools belonging to this group with conversation state.
    required List<ConversationToolState> tools,

    /// The MCP connection state for MCP groups, null for non-MCP groups.
    McpConnectionState? mcpConnectionState,
  }) = _ConversationToolsGroupWithTools;

  const ConversationToolsGroupWithTools._();

  /// Returns true if this is the default "Built-in Tools" group.
  bool get isDefaultGroup => group == null;

  /// Returns true if this group is linked to an MCP server.
  bool get isMcpGroup => group?.isMcpGroup ?? false;

  /// Returns the display name for this group.
  String get displayName => group?.name ?? 'Built-in Tools';

  /// Returns the number of enabled tools in this group.
  int get enabledToolsCount => tools.where((t) => t.isEnabled).length;

  /// Returns the total number of tools in this group.
  int get totalToolsCount => tools.length;

  /// Returns true if all tools in this group are enabled.
  bool get areAllToolsEnabled =>
      tools.isNotEmpty && tools.every((t) => t.isEnabled);

  /// Returns true if any tools in this group are enabled.
  bool get areAnyToolsEnabled => tools.any((t) => t.isEnabled);

  /// Returns true if this group is enabled at workspace level.
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
  /// 0 = Default group (always first)
  /// 1 = MCP with error (needs immediate attention)
  /// 2 = MCP disconnected (needs attention)
  /// 3 = MCP connecting
  /// 4 = MCP connected or non-MCP groups
  int get sortPriority {
    if (isDefaultGroup) return 0;
    if (hasMcpError) return 1;
    if (isMcpDisconnected) return 2;
    if (isMcpConnecting) return 3;
    return 4;
  }
}
