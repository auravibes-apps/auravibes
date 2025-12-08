import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/mcp_manager_provider.dart';
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
    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuraSpacing.sm,
      children: [
        // Title row (name + expand chevron)
        AuraRow(
          children: [
            Expanded(
              child: AuraText(
                style: AuraTextStyle.heading6,
                child: Text(
                  groupWithTools.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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

        // Content row (icon + status/count + toggle)
        AuraRow(
          children: [
            // Group icon
            _GroupIcon(groupWithTools: groupWithTools),
            SizedBox(width: context.auraTheme.spacing.sm),

            // Status and tool count
            Expanded(
              child: AuraColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AuraSpacing.xs,
                children: [
                  // MCP status badge
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
                          'enabled': groupWithTools.enabledToolsCount
                              .toString(),
                          'total': groupWithTools.totalToolsCount.toString(),
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Group toggle (enables/disables all tools)
            if (onToggleAllTools != null)
              AuraSwitch(
                value: groupWithTools.areAllToolsEnabled,
                onChanged: onToggleAllTools,
                size: AuraSwitchSize.sm,
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

  final ConversationToolsGroupWithTools groupWithTools;

  @override
  Widget build(BuildContext context) {
    final hasEnabledTools = groupWithTools.areAnyToolsEnabled;
    final isMcp = groupWithTools.isMcpGroup;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: hasEnabledTools
            ? context.auraColors.primary.withValues(alpha: 0.1)
            : context.auraColors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.auraTheme.borderRadius.md,
        ),
      ),
      child: Center(
        child: AuraIcon(
          isMcp ? Icons.extension : Icons.build_circle_outlined,
          color: hasEnabledTools
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

  final ConversationToolsGroupWithTools groupWithTools;
  final VoidCallback? onReconnect;
  final VoidCallback? onViewError;

  @override
  Widget build(BuildContext context) {
    return AuraRow(
      spacing: AuraSpacing.xs,
      children: [
        // Error badge with truncated message
        Tooltip(
          message: groupWithTools.mcpErrorMessage ?? '',
          child: AuraBadge.text(
            variant: AuraBadgeVariant.error,
            size: AuraBadgeSize.small,
            child: AuraRow(
              spacing: AuraSpacing.xs,
              children: [
                const AuraIcon(
                  Icons.error_outline,
                  size: AuraIconSize.extraSmall,
                ),
                Text(
                  groupWithTools.truncatedErrorMessage ??
                      LocaleKeys.tools_screen_mcp_error.tr(),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Reconnect button
        if (onReconnect != null)
          TextButton.icon(
            onPressed: onReconnect,
            icon: const AuraIcon(
              Icons.refresh,
              size: AuraIconSize.extraSmall,
            ),
            label: Text(LocaleKeys.tools_screen_mcp_reconnect.tr()),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
      spacing: AuraSpacing.xs,
      children: [
        AuraBadge.text(
          variant: AuraBadgeVariant.warning,
          size: AuraBadgeSize.small,
          child: Text(LocaleKeys.tools_screen_mcp_disconnected.tr()),
        ),
        if (onReconnect != null)
          TextButton.icon(
            onPressed: onReconnect,
            icon: const AuraIcon(
              Icons.refresh,
              size: AuraIconSize.extraSmall,
            ),
            label: Text(LocaleKeys.tools_screen_mcp_reconnect.tr()),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}
