// Required: Existing thresholds and limits use numeric values.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/widgets/mcp_status_badge.dart';
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

    return AuraFlex.row(
      children: [
        // Group icon.
        _GroupIcon(groupWithTools: groupWithTools),
        const AuraSizedBox(width: .sm),

        // Group name and status.
        Expanded(
          child: AuraFlex.column(
            children: [
              // Name row with status badge.
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
                McpStatusBadge(
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
                style: AuraTextStyle.bodySmall,
              ),
            ],
            spacing: .xs,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),

        // Actions row.
        AuraFlex.row(
          children: [
            if (groupWithTools.isMcpGroup && onDelete != null)
              AuraIconButton(
                icon: Icons.delete_outline,
                onPressed: onDelete,
                size: AuraIconSize.small,
                tint: AuraTint.error,
                tooltip: LocaleKeys.common_delete.tr(),
              ),
            if (!groupWithTools.isDefaultGroup && onToggleEnabled != null)
              AuraSwitch(
                value: groupWithTools.isEnabled,
                onChanged: onToggleEnabled,
                size: AuraSwitchSize.sm,
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
          Radius.circular(context.auraTheme.fromBorderRadius(.md)),
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
