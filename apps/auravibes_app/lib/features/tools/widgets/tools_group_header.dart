// Required: Existing thresholds and limits use numeric values.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Header widget for a tools group card.
///
/// Displays:
/// - Group icon (extension for MCP, build_circle for default).
/// - Group name.
/// - MCP status badge (spinner/success/error/disconnected).
/// - Tool count: "X of Y enabled".
/// - Master toggle (hidden for default group).
/// - Delete button (for MCP groups only).
/// - Expand/collapse chevron.
class const ToolsGroupHeader({
  required final ToolsGroupWithTools groupWithTools,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,

  /// Callback when the group is toggled on/off.
  /// Null for default group (which has no toggle).
  final ValueChanged<bool>? onToggleEnabled,

  /// Callback to reconnect an MCP server.
  /// Null for non-MCP groups or connected MCPs.
  final VoidCallback? onReconnect,

  /// Callback to delete an MCP group.
  /// Null for non-MCP groups.
  final VoidCallback? onDelete,

  /// Callback to view error details.
  final VoidCallback? onViewError,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final group = groupWithTools.group;

    return AuraRow(
      children: [
        // Group icon.
        _GroupIcon(groupWithTools: groupWithTools),
        const AuraSizedBox(width: .sm),

        // Group name and status.
        Expanded(
          child: AuraColumn(
            children: [
              // Name row with status badge.
              AuraText(
                child: Text(
                  groupWithTools.localizedDisplayNameKey?.tr() ??
                      group?.name ??
                      '',
                  overflow: .ellipsis,
                ),
                style: .heading6,
              ),

              if (groupWithTools.isMcpGroup)
                _McpStatusBadge(
                  groupWithTools: groupWithTools,
                  onReconnect: onReconnect,
                  onViewError: onViewError,
                ),
              // Tool count.
              AuraText(
                child: Text(
                  LocaleKeys.tools_screen_tools_count.tr(
                    namedArgs: {
                      'enabled': groupWithTools.enabledToolsCount.toString(),
                      'total': groupWithTools.totalToolsCount.toString(),
                    },
                  ),
                ),
                style: .bodySmall,
              ),
            ],
            spacing: .xs,
            crossAxisAlignment: .start,
          ),
        ),

        // Actions row.
        AuraRow(
          children: [
            if (groupWithTools.isMcpGroup && onDelete != null)
              AuraIconButton(
                icon: Icons.delete_outline,
                onPressed: onDelete,
                size: .small,
                tint: .error,
                tooltip: LocaleKeys.common_delete.tr(),
              ),
            if (!groupWithTools.isDefaultGroup && onToggleEnabled != null)
              AuraSwitch(
                value: groupWithTools.isEnabled,
                onChanged: onToggleEnabled,
                size: .sm,
              ),
            AuraIconButton.custom(
              child: AnimatedRotation(
                child: const AuraIcon(Icons.keyboard_arrow_down),
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
              ),
              onPressed: onToggleExpand,
            ),
          ],
          spacing: .xs,
        ),
      ],
    );
  }
}

/// Icon widget for the group.
class const _GroupIcon({required final ToolsGroupWithTools groupWithTools})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const iconSize = 40.0;
    final isEnabled = groupWithTools.isEnabled;
    final isMcp = groupWithTools.isMcpGroup;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? context.auraColors.primary.withValues(alpha: 0.1)
            : context.auraColors.surfaceVariant,
        borderRadius: BorderRadius.all(
          .circular(context.auraTheme.fromBorderRadius(.md)),
        ),
      ),
      width: iconSize,
      height: iconSize,
      child: Center(
        child: AuraIcon(
          isMcp ? Icons.extension : Icons.build_circle_outlined,
          tint: isEnabled ? AuraTint.primary : null,
        ),
      ),
    );
  }
}

/// MCP status badge widget.
class const _McpStatusBadge({
  required final ToolsGroupWithTools groupWithTools,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = groupWithTools.mcpStatus;

    if (status == null) return const SizedBox.shrink();

    return switch (status) {
      .connecting => const SizedBox(
        width: 16,
        height: 16,
        child: AuraSpinner(size: .small),
      ),
      .connected => AuraBadge.text(
        child: Text(LocaleKeys.tools_screen_mcp_connected.tr()),
        variant: .success,
        size: .small,
      ),
      .error => _ErrorBadge(
        groupWithTools: groupWithTools,
        onReconnect: onReconnect,
        onViewError: onViewError,
      ),
      .disconnected => _DisconnectedBadge(onReconnect: onReconnect),
    };
  }
}

/// Error badge with reconnect and view error options.
class const _ErrorBadge({
  required final ToolsGroupWithTools groupWithTools,
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
                const AuraIcon(Icons.error_outline, size: .extraSmall),
                Text(LocaleKeys.tools_screen_mcp_error.tr()),
              ],
              spacing: .xs,
              mainAxisSize: .min,
            ),
            variant: .error,
            size: .small,
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
      mainAxisSize: .min,
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
          variant: .warning,
          size: .small,
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
      mainAxisSize: .min,
    );
  }
}
