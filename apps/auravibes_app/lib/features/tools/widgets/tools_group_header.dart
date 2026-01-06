import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/mcp_manager_provider.dart';
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
    return AuraRow(
      children: [
        // Group icon
        _GroupIcon(groupWithTools: groupWithTools),
        SizedBox(width: context.auraTheme.spacing.sm),

        // Group name and status
        Expanded(
          child: AuraColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AuraSpacing.xs,
            children: [
              // Name row with status badge
              AuraText(
                style: AuraTextStyle.heading6,
                child: Text(
                  groupWithTools.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (groupWithTools.isMcpGroup)
                _McpStatusBadge(
                  groupWithTools: groupWithTools,
                  onReconnect: onReconnect,
                  onViewError: onViewError,
                ),
              // Tool count
              AuraText(
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.onSurfaceVariant,
                child: Text(
                  LocaleKeys.tools_screen_tools_count.tr(
                    namedArgs: {
                      'enabled': groupWithTools.enabledToolsCount.toString(),
                      'total': groupWithTools.totalToolsCount.toString(),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Actions row
        AuraRow(
          spacing: AuraSpacing.xs,
          children: [
            // Delete button for MCP groups
            if (groupWithTools.isMcpGroup && onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: AuraIcon(
                  Icons.delete_outline,
                  size: AuraIconSize.small,
                  color: context.auraColors.error,
                ),
                tooltip: LocaleKeys.common_delete.tr(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

            // Master toggle (not for default group)
            if (!groupWithTools.isDefaultGroup && onToggleEnabled != null)
              AuraSwitch(
                value: groupWithTools.isEnabled,
                onChanged: onToggleEnabled,
                size: AuraSwitchSize.sm,
              ),

            // Expand/collapse chevron
            IconButton(
              onPressed: onToggleExpand,
              icon: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: AuraIcon(
                  Icons.keyboard_arrow_down,
                  color: context.auraColors.onSurfaceVariant,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isEnabled
            ? context.auraColors.primary.withValues(alpha: 0.1)
            : context.auraColors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.auraTheme.borderRadius.md,
        ),
      ),
      child: Center(
        child: AuraIcon(
          isMcp ? Icons.extension : Icons.build_circle_outlined,
          color: isEnabled
              ? context.auraColors.primary
              : context.auraColors.onSurfaceVariant,
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
        variant: AuraBadgeVariant.success,
        size: AuraBadgeSize.small,
        child: Text(LocaleKeys.tools_screen_mcp_connected.tr()),
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
      mainAxisSize: MainAxisSize.min,
      spacing: .xs,
      children: [
        // Error badge (compact)
        Tooltip(
          message: groupWithTools.mcpErrorMessage ?? '',
          child: AuraBadge.text(
            variant: .error,
            size: AuraBadgeSize.small,
            child: AuraRow(
              spacing: AuraSpacing.xs,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AuraIcon(
                  Icons.error_outline,
                  size: AuraIconSize.extraSmall,
                ),
                Text(LocaleKeys.tools_screen_mcp_error.tr()),
              ],
            ),
          ),
        ),

        // View details button (icon-only)
        if (onViewError != null && groupWithTools.mcpErrorMessage != null)
          AuraIconButton(
            onPressed: onViewError,
            icon: Icons.visibility_outlined,
            tooltip: LocaleKeys.tools_screen_mcp_view_error.tr(),
            size: .small,
          ),

        // Reconnect button (icon-only)
        if (onReconnect != null)
          AuraIconButton(
            onPressed: onReconnect,
            icon: Icons.refresh,
            tooltip: LocaleKeys.tools_screen_mcp_reconnect.tr(),
            size: .small,
            // padding: EdgeInsets.zero,
            // constraints: const BoxConstraints(),
          ),
      ],
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
      mainAxisSize: MainAxisSize.min,
      spacing: AuraSpacing.xs,
      children: [
        AuraBadge.text(
          variant: AuraBadgeVariant.warning,
          size: AuraBadgeSize.small,
          child: Text(LocaleKeys.tools_screen_mcp_disconnected.tr()),
        ),
        if (onReconnect != null)
          IconButton(
            onPressed: onReconnect,
            icon: const AuraIcon(
              Icons.refresh,
              size: AuraIconSize.small,
            ),
            tooltip: LocaleKeys.tools_screen_mcp_reconnect.tr(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}
