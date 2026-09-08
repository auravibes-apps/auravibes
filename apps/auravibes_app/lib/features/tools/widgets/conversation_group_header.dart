// Required: Existing thresholds and limits use numeric values.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/widgets/mcp_status_badge.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Header widget for a conversation tools group.
///
/// Displays:
/// - Group icon (extension for MCP, build_circle for default).
/// - Group name.
/// - MCP status badge (spinner/success/error/disconnected).
/// - Tool count: "X of Y enabled".
/// - Group toggle (enables/disables all tools in this group).
/// - Reconnect button (for MCP error/disconnected states).
/// - Expand/collapse chevron.
class const ConversationGroupHeader({
  required final ConversationToolsGroupWithTools groupWithTools,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,

  /// Callback when all tools are toggled on/off.
  final ValueChanged<bool>? onToggleAllTools,

  /// Callback to reconnect an MCP server.
  /// Null for non-MCP groups or connected MCPs.
  final VoidCallback? onReconnect,

  /// Callback to view error details.
  final VoidCallback? onViewError,
  super.key,
}) extends StatelessWidget {
  static const _iconSize = 40.0;
  @override
  Widget build(BuildContext context) {
    final group = groupWithTools.group;

    return AuraColumn(
      children: [
        AuraRow(
          children: [
            Expanded(
              child: AuraText(
                child: Text(
                  groupWithTools.localizedDisplayNameKey?.tr() ??
                      group?.name ??
                      '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                style: AuraTextStyle.heading6,
              ),
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
        ),
        AuraRow(
          children: [
            _GroupIcon(groupWithTools: groupWithTools),
            const AuraSizedBox(width: .sm),
            Expanded(
              child: AuraColumn(
                children: [
                  if (groupWithTools.isMcpGroup)
                    McpStatusBadge(
                      groupWithTools: groupWithTools,
                      errorSpacing: .sm,
                      onReconnect: onReconnect,
                      onViewError: onViewError,
                    ),
                  AuraText(
                    child: Text(
                      LocaleKeys.tools_screen_tools_count.tr(
                        namedArgs: {
                          'enabled': groupWithTools.enabledToolsCount
                              .toString(),
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
            if (onToggleAllTools != null)
              AuraSwitch(
                value: groupWithTools.areAllToolsEnabled,
                onChanged: onToggleAllTools,
                size: AuraSwitchSize.sm,
              ),
          ],
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

/// Icon widget for the group.
class const _GroupIcon({
  required final ConversationToolsGroupWithTools groupWithTools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hasEnabledTools = groupWithTools.areAnyToolsEnabled;
    final isMcp = groupWithTools.isMcpGroup;

    return Container(
      decoration: BoxDecoration(
        color: hasEnabledTools
            ? context.auraColors.primary.withValues(alpha: 0.1)
            : context.auraColors.surfaceVariant,
        borderRadius: BorderRadius.all(
          Radius.circular(context.auraTheme.fromBorderRadius(.md)),
        ),
      ),
      width: ConversationGroupHeader._iconSize,
      height: ConversationGroupHeader._iconSize,
      child: Center(
        child: AuraIcon(
          isMcp ? Icons.extension : Icons.build_circle_outlined,
          tint: hasEnabledTools ? AuraTint.primary : null,
        ),
      ),
    );
  }
}
