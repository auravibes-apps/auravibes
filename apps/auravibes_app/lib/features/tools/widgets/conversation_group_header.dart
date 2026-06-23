// Required: Existing thresholds and limits use numeric values.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Header widget for a conversation tools group.
///
/// Displays:
/// - Group icon (extension for MCP, build_circle for default)
/// - Group name
/// - MCP status badge (spinner/success/error/disconnected)
/// - Tool count: "X of Y enabled"
/// - Group toggle (enables/disables all tools in this group)
/// - Reconnect button (for MCP error/disconnected states)
/// - Expand/collapse chevron
class ConversationGroupHeader extends StatelessWidget {
  const ConversationGroupHeader({
    required this.groupWithTools,
    required this.isExpanded,
    required this.onToggleExpand,
    this.onToggleAllTools,
    this.onReconnect,
    this.onViewError,
    super.key,
  });

  final ConversationToolsGroupWithTools groupWithTools;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  /// Callback when all tools are toggled on/off.
  final ValueChanged<bool>? onToggleAllTools;

  /// Callback to reconnect an MCP server.
  /// Null for non-MCP groups or connected MCPs.
  final VoidCallback? onReconnect;

  /// Callback to view error details.
  final VoidCallback? onViewError;

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
                child: const AuraIcon(
                  Icons.keyboard_arrow_down,
                  color: AuraColorVariant.onSurfaceVariant,
                ),
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
                    _McpStatusBadge(
                      groupWithTools: groupWithTools,
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
                    color: AuraColorVariant.onSurfaceVariant,
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
class _GroupIcon extends StatelessWidget {
  const _GroupIcon({required this.groupWithTools});

  final ConversationToolsGroupWithTools groupWithTools;

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
          Radius.circular(
            context.auraTheme.fromBorderRadius(.md),
          ),
        ),
      ),
      width: 40,
      height: 40,
      child: Center(
        child: AuraIcon(
          isMcp ? Icons.extension : Icons.build_circle_outlined,
          color: hasEnabledTools
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

  final ConversationToolsGroupWithTools groupWithTools;
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

  final ConversationToolsGroupWithTools groupWithTools;
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
              spacing: .xs,
              mainAxisSize: MainAxisSize.min,
            ),
            variant: AuraBadgeVariant.error,
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
            size: AuraIconSize.small,
            tooltip: LocaleKeys.tools_screen_mcp_reconnect.tr(),
          ),
      ],
      spacing: .sm,
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
