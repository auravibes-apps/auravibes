// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
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

typedef _McpDeleteInput = ({
  ToolsGroupWithTools groupWithTools,
  String workspaceId,
  WidgetRef ref,
  BuildContext context,
});

/// A collapsible card widget that displays a tools group.
///
/// Shows a group header with icon, name, status, toggle, and expand chevron;
/// an expandable list of tools; and MCP status indicators with reconnect and
/// delete actions for MCP groups.
class const ToolsGroupCard({
  required final ToolsGroupWithTools groupWithTools,
  required final String workspaceId,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final callbacks = _ToolsGroupCardCallbacks(
      groupWithTools: groupWithTools,
      workspaceId: workspaceId,
      ref: ref,
      context: context,
    );

    return _ToolsGroupCardLayout(
      groupWithTools: groupWithTools,
      workspaceId: workspaceId,
      isExpanded: isExpanded.value,
      onToggleExpand: () => isExpanded.value = !isExpanded.value,
      callbacks: callbacks,
    );
  }
}

class _ToolsGroupCardCallbacks {
  new({
    required ToolsGroupWithTools groupWithTools,
    required String workspaceId,
    required WidgetRef ref,
    required BuildContext context,
  }) : onToggleEnabled = groupWithTools.isDefaultGroup
           ? null
           : ((enabled) =>
                 _toggleMcpGroup(groupWithTools, workspaceId, ref, enabled)),
       onReconnect = _shouldShowReconnect(groupWithTools)
           ? (() => _reconnectMcp(groupWithTools, workspaceId, ref))
           : null,
       onDelete = groupWithTools.isMcpGroup
           ? (() => _deleteMcpGroup((
               groupWithTools: groupWithTools,
               workspaceId: workspaceId,
               ref: ref,
               context: context,
             )))
           : null,
       onViewError = groupWithTools.hasMcpError()
           ? (() => _showMcpError(groupWithTools, context))
           : null;

  final ValueChanged<bool>? onToggleEnabled;
  final VoidCallback? onReconnect;
  final VoidCallback? onDelete;
  final VoidCallback? onViewError;
}

bool _shouldShowReconnect(ToolsGroupWithTools groupWithTools) =>
    groupWithTools.isMcpGroup &&
    (groupWithTools.hasMcpError() || groupWithTools.isMcpDisconnected());

void _toggleMcpGroup(
  ToolsGroupWithTools groupWithTools,
  String workspaceId,
  WidgetRef ref,
  bool enabled,
) {
  final group = groupWithTools.group;
  if (group == null) return;

  ref
      .read(groupedToolsProvider(workspaceId).notifier)
      .setMcpGroupEnabled(group.id, isEnabled: enabled);
}

Future<void> _reconnectMcp(
  ToolsGroupWithTools groupWithTools,
  String workspaceId,
  WidgetRef ref,
) async {
  final mcpServerId = groupWithTools.mcpServerId;
  if (mcpServerId == null) return;

  await ref
      .read(groupedToolsProvider(workspaceId).notifier)
      .reconnectMcp(mcpServerId);
}

Future<void> _deleteMcpGroup(_McpDeleteInput input) async {
  final (:groupWithTools, :workspaceId, :ref, :context) = input;
  final group = groupWithTools.group;
  if (group == null) return;

  if (!await _confirmMcpDelete(context)) return;

  await ref
      .read(groupedToolsProvider(workspaceId).notifier)
      .deleteMcpGroup(group.id);
}

Future<bool> _confirmMcpDelete(BuildContext context) async {
  final confirmed = await AuraDialogs.confirm(
    context: context,
    title: Text(_kDeleteMcpTitle.tr()),
    message: Text(_kDeleteMcpConfirm.tr()),
    actions: const AuraConfirmDialogActions(
      confirmLabel: TextLocale(LocaleKeys.common_delete),
      cancelLabel: TextLocale(LocaleKeys.common_cancel),
    ),
    isDestructive: true,
  );

  return confirmed ?? false;
}

void _showMcpError(ToolsGroupWithTools groupWithTools, BuildContext context) {
  AuraDialogs.alert(
    context: context,
    title: Text(_kDeleteMcpTitle.tr()),
    message: AuraSelectableText(
      groupWithTools.mcpErrorMessage ?? 'Unknown error',
    ),
    dismissLabel: const TextLocale(LocaleKeys.common_cancel),
  );
}

class const _ToolsGroupCardLayout({
  required final ToolsGroupWithTools groupWithTools,
  required final String workspaceId,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
  required final _ToolsGroupCardCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.auraTheme.fromSpacing(.md)),
      child: AuraCard(
        child: _ToolsGroupCardContent(
          groupWithTools: groupWithTools,
          workspaceId: workspaceId,
          isExpanded: isExpanded,
          onToggleExpand: onToggleExpand,
          callbacks: callbacks,
        ),
        style: .border,
      ),
    );
  }
}

class const _ToolsGroupCardContent({
  required final ToolsGroupWithTools groupWithTools,
  required final String workspaceId,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
  required final _ToolsGroupCardCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: isExpanded,
          onToggleExpand: onToggleExpand,
          onToggleEnabled: callbacks.onToggleEnabled,
          onReconnect: callbacks.onReconnect,
          onDelete: callbacks.onDelete,
          onViewError: callbacks.onViewError,
        ),
        if (isExpanded) ...[
          const AuraDivider(),
          _ToolsList(groupWithTools: groupWithTools, workspaceId: workspaceId),
        ],
      ],
      crossAxisAlignment: .start,
    );
  }
}

/// List of tools within a group.
class const _ToolsList({
  required final ToolsGroupWithTools groupWithTools,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (groupWithTools.tools.isEmpty) return const _EmptyToolsGroup();

    return _ToolsGroupRows(
      groupWithTools: groupWithTools,
      workspaceId: workspaceId,
    );
  }
}

class const _EmptyToolsGroup() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.md),
        horizontal: context.auraTheme.fromSpacing(.sm),
      ),
      child: const _EmptyToolsMessage(),
    );
  }
}

class const _EmptyToolsMessage() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AuraText(child: Text(_kNoToolsInGroup.tr()), style: .bodySmall),
    );
  }
}

class const _ToolsGroupRows({
  required final ToolsGroupWithTools groupWithTools,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.fromSpacing(.sm),
      ),
      child: _ToolRows(
        tools: groupWithTools.tools,
        workspaceId: workspaceId,
        showDeleteButton: !groupWithTools.isMcpGroup,
      ),
    );
  }
}

class const _ToolRows({
  required final List<WorkspaceToolEntity> tools,
  required final String workspaceId,
  required final bool showDeleteButton,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final tool in tools)
          ToolItemRow(
            tool: tool,
            workspaceId: workspaceId,
            showDeleteButton: showDeleteButton,
          ),
      ],
    );
  }
}
