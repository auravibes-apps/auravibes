// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_item_row.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_header.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Locale keys for MCP group deletion.
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
    required this.workspaceId,
    super.key,
  });

  final ToolsGroupWithTools groupWithTools;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: context.auraTheme.fromSpacing(.md),
      ),
      child: AuraCard(
        child: AuraColumn(
          children: [
            // Header.
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

            // Expanded content.
            if (isExpanded.value) ...[
              const AuraDivider(),
              _ToolsList(
                groupWithTools: groupWithTools,
                workspaceId: workspaceId,
              ),
            ],
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        style: AuraCardStyle.border,
      ),
    );
  }

  bool _shouldShowReconnect() {
    return groupWithTools.isMcpGroup &&
        (groupWithTools.hasMcpError || groupWithTools.isMcpDisconnected);
  }

  void _handleToggleEnabled(WidgetRef ref, bool enabled) {
    final group = groupWithTools.group;
    if (group == null) return;

    ref
        .read(groupedToolsProvider(workspaceId).notifier)
        .setMcpGroupEnabled(
          group.id,
          isEnabled: enabled,
        );
  }

  Future<void> _handleReconnect(WidgetRef ref) async {
    final mcpServerId = groupWithTools.mcpServerId;
    if (mcpServerId == null) return;

    await ref
        .read(groupedToolsProvider(workspaceId).notifier)
        .reconnectMcp(
          mcpServerId,
        );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final group = groupWithTools.group;
    if (group == null) return;

    final confirmed = await showAuraConfirmDialog(
      context: context,
      title: Text(_kDeleteMcpTitle.tr()),
      message: Text(_kDeleteMcpConfirm.tr()),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.common_delete),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
      isDestructive: true,
    );

    if (confirmed ?? false) {
      await ref
          .read(groupedToolsProvider(workspaceId).notifier)
          .deleteMcpGroup(
            group.id,
          );
    }
  }

  void _showErrorDetails(BuildContext context) {
    showAuraAlertDialog(
      context: context,
      title: Text(_kDeleteMcpTitle.tr()),
      message: AuraSelectableText(
        groupWithTools.mcpErrorMessage ?? 'Unknown error',
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_cancel),
    );
  }
}

/// List of tools within a group.
class _ToolsList extends StatelessWidget {
  const _ToolsList({required this.groupWithTools, required this.workspaceId});

  final ToolsGroupWithTools groupWithTools;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    if (groupWithTools.tools.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.auraTheme.fromSpacing(.md),
          horizontal: context.auraTheme.fromSpacing(.sm),
        ),
        child: Center(
          child: AuraText(
            child: Text(_kNoToolsInGroup.tr()),
            style: AuraTextStyle.bodySmall,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.fromSpacing(.sm),
      ),
      child: Column(
        children: groupWithTools.tools
            .map(
              (tool) => ToolItemRow(
                tool: tool,
                workspaceId: workspaceId,
                // MCP tools cannot be individually deleted.
                showDeleteButton: !groupWithTools.isMcpGroup,
              ),
            )
            .toList(),
      ),
    );
  }
}
