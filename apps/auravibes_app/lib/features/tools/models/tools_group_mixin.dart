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

  bool isSameGroup(ToolsGroupMixin other) => group == other.group;

  int computeDefaultSortPriority() => switch (defaultGroupType) {
    .native => 1,
    .builtIn || null => 0,
  };
}

extension ToolsGroupMixinDisplay on ToolsGroupMixin {
  bool get isDefaultGroup => group == null;

  bool get isNativeDefaultGroup =>
      isDefaultGroup && defaultGroupType == DefaultToolGroupType.native;

  bool get isMcpGroup => group?.isMcpGroup ?? false;

  String? get localizedDisplayNameKey => switch (defaultGroupType) {
    .native when isDefaultGroup => LocaleKeys.tools_screen_native_group,
    .builtIn ||
    null when isDefaultGroup => LocaleKeys.tools_screen_default_group,
    _ when group?.name == SkillToolPermissionConstants.skillToolsGroupName =>
      LocaleKeys.more_screen_skills_title,
    _ => null,
  };

  McpConnectionStatus? mcpStatus() => mcpConnectionState?.status;

  String? get mcpServerId => group?.mcpServerId;

  bool hasMcpError() => mcpStatus() == McpConnectionStatus.error;

  String? get mcpErrorMessage {
    final message = mcpConnectionState?.errorMessage;
    if (message == null) return null;

    return message == LocaleKeys.tools_screen_mcp_error
        ? message.tr()
        : message;
  }

  bool hasErrorMessage() => mcpErrorMessage != null;
}

extension ToolsGroupMixinStatusDisplay on ToolsGroupMixin {
  bool isMcpDisconnected() => mcpStatus() == McpConnectionStatus.disconnected;

  bool isMcpConnecting() => mcpStatus() == McpConnectionStatus.connecting;

  bool isMcpConnected() => mcpStatus() == McpConnectionStatus.connected;

  bool get needsAttention => hasMcpError() || isMcpDisconnected();

  String? get truncatedErrorMessage {
    final message = mcpErrorMessage;
    if (message == null) return null;

    return message.truncateCharacters(50);
  }

  bool get isEnabled => group?.isEnabled ?? true;

  bool hasErrorMessage() => mcpErrorMessage != null;

  int get sortPriority {
    if (isDefaultGroup) return computeDefaultSortPriority();
    if (hasMcpError()) return 2;
    if (isMcpDisconnected()) return 3;
    if (isMcpConnecting()) return 4;

    return 5;
  }
}
