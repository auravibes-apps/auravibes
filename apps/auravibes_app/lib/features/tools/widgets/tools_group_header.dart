// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: prefer-single-widget-per-file
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Header widget for a tools group card.
///
/// Displays:
/// - Group icon (extension for MCP, build_circle for default)
/// - Group name
/// - MCP status badge (spinner/success/error/disconnected)
/// - Tool count: "X of Y enabled"
/// - Master toggle (hidden for default group)
/// - Delete button (for MCP groups only)
/// - Expand/collapse chevron
class ToolsGroupHeader extends StatelessWidget {
  const ToolsGroupHeader({
    required this.groupWithTools,
    required this.isExpanded,
    required this.onToggleExpand,
    this.onToggleEnabled,
    this.onReconnect,
    this.onDelete,
    this.onViewError,
    super.key,
  });

  final ToolsGroupWithTools groupWithTools;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  /// Callback when the group is toggled on/off.
  /// Null for default group (which has no toggle).
  final ValueChanged<bool>? onToggleEnabled;

  /// Callback to reconnect an MCP server.
  /// Null for non-MCP groups or connected MCPs.
  final VoidCallback? onReconnect;

  /// Callback to delete an MCP group.
  /// Null for non-MCP groups.
  final VoidCallback? onDelete;

  /// Callback to view error details.
  final VoidCallback? onViewError;

  @override
  Widget build(BuildContext context) {
    final group = groupWithTools.group;

    return AuraRow(
      children: [
        // Group icon
        _GroupIcon(groupWithTools: groupWithTools),
        SizedBox(width: context.auraTheme.spacing.sm),

        // Group name and status
        Expanded(
          child: AuraColumn(
            children: [
              // Name row with status badge
              AuraText(
                child: Text(
                  groupWithTools.localizedDisplayNameKey?.tr() ??
                      group?.name ??
                      '',
                  overflow: TextOverflow.ellipsis,
                ),
                style: AuraTextStyle.heading6,
              ),

              if (groupWithTools.isMcpGroup)
                _McpStatusBadge(
                  groupWithTools: groupWithTools,
                  onReconnect: onReconnect,
                  onViewError: onViewError,
                ),
              // Tool count
              AuraText(
                child: Text(
                  LocaleKeys.tools_screen_tools_count.tr(
                    namedArgs: {
                      'enabled': groupWithTools.enabledToolsCount.toString(),
                      'total': groupWithTools.totalToolsCount.toString(),
                    },
                  ),
                ),
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.onSurfaceVariant,
              ),
            ],
            spacing: AuraSpacing.xs,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),

        // Actions row
        AuraRow(
          children: [
            if (groupWithTools.isMcpGroup && onDelete != null)
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: onDelete,
                tooltip: LocaleKeys.common_delete.tr(),
                constraints: const BoxConstraints(),
                icon: const AuraIcon(
                  Icons.delete_outline,
                  size: AuraIconSize.small,
                  color: AuraColorVariant.error,
                ),
              ),
            if (!groupWithTools.isDefaultGroup && onToggleEnabled != null)
              AuraSwitch(
                value: groupWithTools.isEnabled,
                onChanged: onToggleEnabled,
                size: AuraSwitchSize.sm,
              ),
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: onToggleExpand,
              constraints: const BoxConstraints(),
              icon: AnimatedRotation(
                child: const AuraIcon(
                  Icons.keyboard_arrow_down,
                  color: AuraColorVariant.onSurfaceVariant,
                ),
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
              ),
            ),
          ],
          spacing: AuraSpacing.xs,
        ),
      ],
    );
  }
}

/// Icon widget for the group.
class _GroupIcon extends StatelessWidget {
  const _GroupIcon({required this.groupWithTools});

  final ToolsGroupWithTools groupWithTools;

  @override
  Widget build(BuildContext context) {
    final isEnabled = groupWithTools.isEnabled;
    final isMcp = groupWithTools.isMcpGroup;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? context.auraColors.primary.withValues(alpha: 0.1)
            : context.auraColors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.auraTheme.borderRadius.md,
        ),
      ),
      width: 40,
      height: 40,
      child: Center(
        child: AuraIcon(
          isMcp ? Icons.extension : Icons.build_circle_outlined,
          color: isEnabled
              ? AuraColorVariant.primary
              : AuraColorVariant.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// MCP status badge widget.
class _McpStatusBadge extends StatelessWidget {
  const _McpStatusBadge({
    required this.groupWithTools,
    this.onReconnect,
    this.onViewError,
  });

  final ToolsGroupWithTools groupWithTools;
  final VoidCallback? onReconnect;
  final VoidCallback? onViewError;

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
class _ErrorBadge extends StatelessWidget {
  const _ErrorBadge({
    required this.groupWithTools,
    this.onReconnect,
    this.onViewError,
  });

  final ToolsGroupWithTools groupWithTools;
  final VoidCallback? onReconnect;
  final VoidCallback? onViewError;

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
              spacing: AuraSpacing.xs,
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
      spacing: .xs,
      mainAxisSize: MainAxisSize.min,
    );
  }
}

/// Disconnected badge with reconnect button.
class _DisconnectedBadge extends StatelessWidget {
  const _DisconnectedBadge({this.onReconnect});

  final VoidCallback? onReconnect;

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
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: onReconnect,
            tooltip: LocaleKeys.tools_screen_mcp_reconnect.tr(),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const AuraIcon(
              Icons.refresh,
              size: AuraIconSize.small,
            ),
          ),
      ],
      spacing: AuraSpacing.xs,
      mainAxisSize: MainAxisSize.min,
    );
  }
}
