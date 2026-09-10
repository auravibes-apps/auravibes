// Required: Existing thresholds and limits use numeric values.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
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
  Widget build(BuildContext context) => _ConversationGroupHeaderContent(
    groupWithTools: groupWithTools,
    isExpanded: isExpanded,
    onToggleExpand: onToggleExpand,
    onToggleAllTools: onToggleAllTools,
    onReconnect: onReconnect,
    onViewError: onViewError,
  );
}

class const _ConversationGroupHeaderContent({
  required final ConversationToolsGroupWithTools groupWithTools,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
  final ValueChanged<bool>? onToggleAllTools,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ConversationGroupTitleRow(
        groupWithTools: groupWithTools,
        isExpanded: isExpanded,
        onToggleExpand: onToggleExpand,
      ),
      _ConversationGroupSummaryRow(
        groupWithTools: groupWithTools,
        onToggleAllTools: onToggleAllTools,
        onReconnect: onReconnect,
        onViewError: onViewError,
      ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _ConversationGroupTitleRow({
  required final ConversationToolsGroupWithTools groupWithTools,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      Expanded(
        child: AuraText(
          child: Text(
            groupWithTools.localizedDisplayNameKey?.tr() ??
                groupWithTools.group?.name ??
                '',
            overflow: .ellipsis,
            maxLines: 2,
          ),
          style: .heading6,
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
  );
}

class const _ConversationGroupSummaryRow({
  required final ConversationToolsGroupWithTools groupWithTools,
  final ValueChanged<bool>? onToggleAllTools,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
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
            _ToolCount(groupWithTools: groupWithTools),
          ],
          spacing: .xs,
          crossAxisAlignment: .start,
        ),
      ),
      _ToggleAllTools(
        groupWithTools: groupWithTools,
        onToggleAllTools: onToggleAllTools,
      ),
    ],
  );
}

class const _ToolCount({
  required final ConversationToolsGroupWithTools groupWithTools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      LocaleKeys.tools_screen_tools_count.tr(
        namedArgs: {
          'enabled': groupWithTools.enabledToolsCount.toString(),
          'total': groupWithTools.totalToolsCount.toString(),
        },
      ),
    ),
    style: .bodySmall,
  );
}

class const _ToggleAllTools({
  required final ConversationToolsGroupWithTools groupWithTools,
  required final ValueChanged<bool>? onToggleAllTools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (onToggleAllTools == null) return const SizedBox.shrink();

    return AuraSwitch(
      value: groupWithTools.areAllToolsEnabled,
      onChanged: onToggleAllTools,
      size: .sm,
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

    return _GroupIconSurface(
      isEnabled: hasEnabledTools,
      isMcp: isMcp,
      iconSize: ConversationGroupHeader._iconSize,
    );
  }
}

class const _GroupIconSurface({
  required final bool isEnabled,
  required final bool isMcp,
  required final double iconSize,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: _groupIconDecoration(context, isEnabled),
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

BoxDecoration _groupIconDecoration(BuildContext context, bool isEnabled) =>
    BoxDecoration(
      color: isEnabled
          ? context.auraColors.primary.withValues(alpha: 0.1)
          : context.auraColors.surfaceVariant,
      borderRadius: BorderRadius.all(
        .circular(context.auraTheme.fromBorderRadius(.md)),
      ),
    );

/// MCP status badge widget.
class const _McpStatusBadge({
  required final ConversationToolsGroupWithTools groupWithTools,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (groupWithTools.mcpStatus) {
    null => const SizedBox.shrink(),
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

/// Error badge with reconnect and view error options.
class const _ErrorBadge({
  required final ConversationToolsGroupWithTools groupWithTools,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        _ErrorBadgeLabel(message: groupWithTools.mcpErrorMessage ?? ''),
        _ErrorBadgeActions(
          groupWithTools: groupWithTools,
          onViewError: onViewError,
          onReconnect: onReconnect,
        ),
      ],
      spacing: .sm,
      mainAxisSize: .min,
    );
  }
}

class const _ErrorBadgeLabel({required final String message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTooltip(
    message: message,
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
  );
}

class const _ErrorBadgeActions({
  required final ConversationToolsGroupWithTools groupWithTools,
  final VoidCallback? onViewError,
  final VoidCallback? onReconnect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
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
    spacing: .sm,
    mainAxisSize: .min,
  );
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
