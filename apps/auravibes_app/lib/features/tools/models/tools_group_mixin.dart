// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/utils/string_extensions.dart';

mixin ToolsGroupMixin {
  ToolsGroupEntity? get group;
  DefaultToolGroupType? get defaultGroupType;
  McpConnectionState? get mcpConnectionState;

  bool get isDefaultGroup => group == null;

  bool get isNativeDefaultGroup =>
      isDefaultGroup && defaultGroupType == DefaultToolGroupType.native;

  bool get isMcpGroup => group?.isMcpGroup ?? false;

  String? get localizedDisplayNameKey {
    if (!isDefaultGroup) return null;
    return switch (defaultGroupType) {
      .native => LocaleKeys.tools_screen_native_group,
      .builtIn || null => LocaleKeys.tools_screen_default_group,
    };
  }

  McpConnectionStatus? get mcpStatus => mcpConnectionState?.status;

  String? get mcpServerId => group?.mcpServerId;

  bool get hasMcpError => mcpStatus == McpConnectionStatus.error;

  bool get isMcpDisconnected => mcpStatus == McpConnectionStatus.disconnected;

  bool get isMcpConnecting => mcpStatus == McpConnectionStatus.connecting;

  bool get isMcpConnected => mcpStatus == McpConnectionStatus.connected;

  bool get needsAttention => hasMcpError || isMcpDisconnected;

  String? get mcpErrorMessage => mcpConnectionState?.errorMessage;

  String? get truncatedErrorMessage {
    final message = mcpErrorMessage;
    if (message == null) return null;
    return message.truncateCharacters(50);
  }

  bool get isEnabled => group?.isEnabled ?? true;

  int computeDefaultSortPriority() {
    return switch (defaultGroupType) {
      .native => 1,
      .builtIn || null => 0,
    };
  }

  int get sortPriority {
    if (isDefaultGroup) return computeDefaultSortPriority();
    if (hasMcpError) return 2;
    if (isMcpDisconnected) return 3;
    if (isMcpConnecting) return 4;
    return 5;
  }
}
