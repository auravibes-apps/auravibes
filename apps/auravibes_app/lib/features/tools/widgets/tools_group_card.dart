import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/providers/grouped_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/tool_item_row.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_header.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Locale keys for MCP group deletion
const _kDeleteMcpTitle = 'tools_screen.delete_mcp_title';
const _kDeleteMcpConfirm = 'tools_screen.delete_mcp_confirm';
const _kNoToolsInGroup = 'tools_screen.no_tools_in_group';

/// A collapsible card widget that displays a tools group.
///
/// Shows:
/// - Group header with icon, name, status, toggle, and expand chevron
/// - Expandable list of tools belonging to this group
/// - MCP status indicators and reconnect/delete actions for MCP groups
class ToolsGroupCard extends HookConsumerWidget {
  const ToolsGroupCard({
    required this.groupWithTools,
    super.key,
  });

  final ToolsGroupWithTools groupWithTools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);

    return Padding(
      padding: EdgeInsets.only(bottom: context.auraTheme.spacing.md),
      child: AuraCard(
        child: AuraColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ToolsGroupHeader(
              groupWithTools: groupWithTools,
              isExpanded: isExpanded.value,
              onToggleExpand: () => isExpanded.value = !isExpanded.value,
              onToggleEnabled: groupWithTools.isDefaultGroup
                  ? null
                  : (enabled) => _handleToggleEnabled(ref, enabled),
              onReconnect: _shouldShowReconnect()
                  ? () => _handleReconnect(ref)
                  : null,
              onDelete: groupWithTools.isMcpGroup
                  ? () => _handleDelete(context, ref)
                  : null,
              onViewError: groupWithTools.hasMcpError
                  ? () => _showErrorDetails(context)
                  : null,
            ),

            // Expanded content
            if (isExpanded.value) ...[
              const AuraDivider(),
              _ToolsList(groupWithTools: groupWithTools),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowReconnect() {
    return groupWithTools.isMcpGroup &&
        (groupWithTools.hasMcpError || groupWithTools.isMcpDisconnected);
  }

  void _handleToggleEnabled(WidgetRef ref, bool enabled) {
    if (groupWithTools.group == null) return;

    ref
        .read(groupedToolsProvider.notifier)
        .setMcpGroupEnabled(
          groupWithTools.group!.id,
          isEnabled: enabled,
        );
  }

  Future<void> _handleReconnect(WidgetRef ref) async {
    if (groupWithTools.mcpServerId == null) return;

    await ref
        .read(groupedToolsProvider.notifier)
        .reconnectMcp(groupWithTools.mcpServerId!);
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    if (groupWithTools.group == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_kDeleteMcpTitle.tr()),
        content: Text(_kDeleteMcpConfirm.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TextLocale(LocaleKeys.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const TextLocale(LocaleKeys.common_delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref
          .read(groupedToolsProvider.notifier)
          .deleteMcpGroup(groupWithTools.group!.id);
    }
  }

  void _showErrorDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_kDeleteMcpTitle.tr()),
        content: SingleChildScrollView(
          child: SelectableText(
            groupWithTools.mcpErrorMessage ?? 'Unknown error',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// List of tools within a group.
class _ToolsList extends StatelessWidget {
  const _ToolsList({required this.groupWithTools});

  final ToolsGroupWithTools groupWithTools;

  @override
  Widget build(BuildContext context) {
    if (groupWithTools.tools.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.auraTheme.spacing.md,
          horizontal: context.auraTheme.spacing.sm,
        ),
        child: Center(
          child: AuraText(
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurfaceVariant,
            child: Text(_kNoToolsInGroup.tr()),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.spacing.sm,
      ),
      child: Column(
        children: groupWithTools.tools
            .map(
              (tool) => ToolItemRow(
                tool: tool,
                // MCP tools cannot be individually deleted
                showDeleteButton: !groupWithTools.isMcpGroup,
              ),
            )
            .toList(),
      ),
    );
  }
}
