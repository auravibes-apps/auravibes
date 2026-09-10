// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/skills/constants/skill_tool_permission_constants.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:easy_localization/easy_localization.dart';

mixin ToolsGroupMixin {
  ToolsGroupEntity? get group;
  DefaultToolGroupType? get defaultGroupType;
  McpConnectionState? get mcpConnectionState;

  late final bool isDefaultGroup = group == null;

  late final bool isNativeDefaultGroup =
      isDefaultGroup && defaultGroupType == DefaultToolGroupType.native;

  late final bool isMcpGroup = group?.isMcpGroup ?? false;

  late final String? localizedDisplayNameKey = switch (defaultGroupType) {
    .native when isDefaultGroup => LocaleKeys.tools_screen_native_group,
    .builtIn ||
    null when isDefaultGroup => LocaleKeys.tools_screen_default_group,
    _ when group?.name == SkillToolPermissionConstants.skillToolsGroupName =>
      LocaleKeys.more_screen_skills_title,
    _ => null,
  };

  late final McpConnectionStatus? mcpStatus = mcpConnectionState?.status;

  late final String? mcpServerId = group?.mcpServerId;

  late final bool hasMcpError = mcpStatus == McpConnectionStatus.error;

  late final bool isMcpDisconnected =
      mcpStatus == McpConnectionStatus.disconnected;

  late final bool isMcpConnecting = mcpStatus == McpConnectionStatus.connecting;

  late final bool isMcpConnected = mcpStatus == McpConnectionStatus.connected;

  late final bool needsAttention = hasMcpError || isMcpDisconnected;

  String? get mcpErrorMessage {
    final message = mcpConnectionState?.errorMessage;
    if (message == null) return null;

    return message == LocaleKeys.tools_screen_mcp_error
        ? message.tr()
        : message;
  }

  String? get truncatedErrorMessage {
    final message = mcpErrorMessage;
    if (message == null) return null;

    return message.truncateCharacters(50);
  }

  late final bool isEnabled = group?.isEnabled ?? true;

  late final int sortPriority = _sortPriority();

  int computeDefaultSortPriority() {
    return switch (defaultGroupType) {
      .native => 1,
      .builtIn || null => 0,
    };
  }

  bool isSameGroup(ToolsGroupMixin other) => group == other.group;

  bool hasErrorMessage() => mcpErrorMessage != null;

  int _sortPriority() {
    if (isDefaultGroup) return computeDefaultSortPriority();
    if (hasMcpError) return 2;
    if (isMcpDisconnected) return 3;
    if (isMcpConnecting) return 4;

    return 5;
  }
}
