// Required: Existing thresholds and limits use numeric values.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/features/tools/models/tools_group_mixin.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// MCP status badge shared by workspace and conversation groups.
class const McpStatusBadge({
  required final ToolsGroupMixin groupWithTools,
  final AuraSpacing errorSpacing = .xs,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = groupWithTools.mcpStatus;

    if (status == null) return const SizedBox.shrink();

    return switch (status) {
      McpConnectionStatus.connecting => const SizedBox(
        width: 16,
        height: 16,
        child: AuraSpinner(size: AuraSpinnerSize.small),
      ),
      McpConnectionStatus.connected => AuraBadge.text(
        child: Text(LocaleKeys.tools_screen_mcp_connected.tr()),
        variant: AuraBadgeVariant.success,
        size: AuraBadgeSize.small,
      ),
      McpConnectionStatus.error => _ErrorBadge(
        spacing: errorSpacing,
        groupWithTools: groupWithTools,
        onReconnect: onReconnect,
        onViewError: onViewError,
      ),
      McpConnectionStatus.disconnected => _DisconnectedBadge(
        onReconnect: onReconnect,
      ),
    };
  }
}

/// Error badge with reconnect and view error options.
class const _ErrorBadge({
  required final AuraSpacing spacing,
  required final ToolsGroupMixin groupWithTools,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraTooltip(
          message: groupWithTools.mcpErrorMessage ?? '',
          child: AuraBadge.text(
            child: AuraRow(
              children: [
                const AuraIcon(
                  Icons.error_outline,
                  size: AuraIconSize.extraSmall,
                ),
                Text(LocaleKeys.tools_screen_mcp_error.tr()),
              ],
              spacing: .xs,
              mainAxisSize: MainAxisSize.min,
            ),
            variant: .error,
            size: AuraBadgeSize.small,
          ),
        ),
        if (onViewError != null && groupWithTools.mcpErrorMessage != null)
          AuraIconButton(
            icon: Icons.visibility_outlined,
            onPressed: onViewError,
            size: .small,
            tooltip: LocaleKeys.tools_screen_mcp_view_error.tr(),
          ),
        if (onReconnect != null)
          AuraIconButton(
            icon: Icons.refresh,
            onPressed: onReconnect,
            size: .small,
            tooltip: LocaleKeys.tools_screen_mcp_reconnect.tr(),
          ),
      ],
      spacing: spacing,
      mainAxisSize: MainAxisSize.min,
    );
  }
}

/// Disconnected badge with reconnect button.
class const _DisconnectedBadge({final VoidCallback? onReconnect})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraBadge.text(
          child: Text(LocaleKeys.tools_screen_mcp_disconnected.tr()),
          variant: AuraBadgeVariant.warning,
          size: AuraBadgeSize.small,
        ),
        if (onReconnect != null)
          AuraIconButton(
            icon: Icons.refresh,
            onPressed: onReconnect,
            size: AuraIconSize.small,
            tooltip: LocaleKeys.tools_screen_mcp_reconnect.tr(),
          ),
      ],
      spacing: .xs,
      mainAxisSize: MainAxisSize.min,
    );
  }
}
