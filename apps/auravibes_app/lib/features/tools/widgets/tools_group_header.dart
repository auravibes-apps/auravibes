// Required: Existing thresholds and limits use numeric values.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
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
    return AuraRow(
      children: [
        // Group icon.
        _GroupIcon(groupWithTools: groupWithTools),
        const AuraSizedBox(width: .sm),

        // Group name and status.
        _GroupDetails(
          groupWithTools: groupWithTools,
          onReconnect: onReconnect,
          onViewError: onViewError,
        ),

        // Actions row.
        _GroupActions(
          groupWithTools: groupWithTools,
          isExpanded: isExpanded,
          onToggleEnabled: onToggleEnabled,
          onDelete: onDelete,
          onToggleExpand: onToggleExpand,
        ),
      ],
    );
  }
}

class const _GroupDetails({
  required final ToolsGroupWithTools groupWithTools,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: _GroupDetailsContent(
      groupWithTools: groupWithTools,
      fallbackName: groupWithTools.group?.name,
      onReconnect: onReconnect,
      onViewError: onViewError,
    ),
  );
}

class const _GroupDetailsContent({
  required final ToolsGroupWithTools groupWithTools,
  required final String? fallbackName,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _GroupName(groupWithTools: groupWithTools, fallbackName: fallbackName),
      if (groupWithTools.isMcpGroup)
        _McpStatusBadge(
          groupWithTools: groupWithTools,
          onReconnect: onReconnect,
          onViewError: onViewError,
        ),
      _GroupToolCount(groupWithTools: groupWithTools),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _GroupName({
  required final ToolsGroupWithTools groupWithTools,
  required final String? fallbackName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      groupWithTools.localizedDisplayNameKey?.tr() ?? fallbackName ?? '',
      overflow: .ellipsis,
    ),
    style: .heading6,
  );
}

class const _GroupToolCount({required final ToolsGroupWithTools groupWithTools})
    extends StatelessWidget {
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

class const _GroupActions({
  required final ToolsGroupWithTools groupWithTools,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
  final ValueChanged<bool>? onToggleEnabled,
  final VoidCallback? onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      _GroupDeleteButton(groupWithTools: groupWithTools, onDelete: onDelete),
      _GroupEnabledToggle(
        groupWithTools: groupWithTools,
        onToggleEnabled: onToggleEnabled,
      ),
      _GroupExpandButton(
        isExpanded: isExpanded,
        onToggleExpand: onToggleExpand,
      ),
    ],
    spacing: .xs,
  );
}

class const _GroupDeleteButton({
  required final ToolsGroupWithTools groupWithTools,
  required final VoidCallback? onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!groupWithTools.isMcpGroup || onDelete == null) {
      return const SizedBox.shrink();
    }

    return AuraIconButton(
      icon: Icons.delete_outline,
      onPressed: onDelete,
      size: .small,
      tint: .error,
      tooltip: LocaleKeys.common_delete.tr(),
    );
  }
}

class const _GroupEnabledToggle({
  required final ToolsGroupWithTools groupWithTools,
  required final ValueChanged<bool>? onToggleEnabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (groupWithTools.isDefaultGroup || onToggleEnabled == null) {
      return const SizedBox.shrink();
    }

    return AuraSwitch(
      value: groupWithTools.isEnabled,
      onChanged: onToggleEnabled,
      size: .sm,
    );
  }
}

class const _GroupExpandButton({
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton.custom(
    child: AnimatedRotation(
      child: const AuraIcon(Icons.keyboard_arrow_down),
      turns: isExpanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
    ),
    onPressed: onToggleExpand,
  );
}

/// Icon widget for the group.
class const _GroupIcon({required final ToolsGroupWithTools groupWithTools})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const iconSize = 40.0;
    final isEnabled = groupWithTools.isEnabled;
    final isMcp = groupWithTools.isMcpGroup;

    return _GroupIconSurface(
      iconSize: iconSize,
      isEnabled: isEnabled,
      isMcp: isMcp,
    );
  }
}

class const _GroupIconSurface({
  required final double iconSize,
  required final bool isEnabled,
  required final bool isMcp,
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
  required final ToolsGroupWithTools groupWithTools,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = groupWithTools.mcpStatus();
    if (status == null) return const SizedBox.shrink();

    return _McpStatusBadgeState(
      groupWithTools: groupWithTools,
      status: status,
      onReconnect: onReconnect,
      onViewError: onViewError,
    );
  }
}

class const _McpStatusBadgeState({
  required final ToolsGroupWithTools groupWithTools,
  required final McpConnectionStatus status,
  final VoidCallback? onReconnect,
  final VoidCallback? onViewError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (status) {
    .connecting => const _ConnectingBadge(),
    .connected => const _ConnectedBadge(),
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
  required final ToolsGroupWithTools groupWithTools,
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
      spacing: .xs,
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
  required final ToolsGroupWithTools groupWithTools,
  final VoidCallback? onViewError,
  final VoidCallback? onReconnect,
}) extends StatelessWidget {
  bool get _canViewError =>
      onViewError != null && groupWithTools.mcpErrorMessage != null;

  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      if (_canViewError)
        _ErrorBadgeAction(
          icon: Icons.visibility_outlined,
          onPressed: onViewError,
          tooltip: LocaleKeys.tools_screen_mcp_view_error.tr(),
        ),
      if (onReconnect != null)
        _ErrorBadgeAction(
          icon: Icons.refresh,
          onPressed: onReconnect,
          tooltip: LocaleKeys.tools_screen_mcp_reconnect.tr(),
        ),
    ],
    spacing: .xs,
    mainAxisSize: .min,
  );
}

class const _ConnectingBadge() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 16, height: 16, child: AuraSpinner(size: .small));
}

class const _ConnectedBadge() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraBadge.text(
    child: Text(LocaleKeys.tools_screen_mcp_connected.tr()),
    variant: .success,
    size: .small,
  );
}

class const _ErrorBadgeAction({
  required final IconData icon,
  required final VoidCallback? onPressed,
  required final String tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: icon,
    onPressed: onPressed,
    size: .small,
    tooltip: tooltip,
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
