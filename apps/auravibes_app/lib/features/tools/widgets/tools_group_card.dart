// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/mcp_error_details.dart';
import 'package:auravibes_app/features/tools/widgets/tool_item_row.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_header.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
  final Set<String> selectedTargetKeys = const {},
  final bool isDeleting = false,
  final void Function(String key, ({bool isSelected}) change)?
  onSelectionChanged,
  final List<WorkspaceToolEntity>? visibleTools,
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
      card: this,
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
  }) : onOpenConnection = groupWithTools.mcpServerId == null
           ? null
           : (() => unawaited(
               _openConnection(groupWithTools, workspaceId, ref, context),
             )),
       onToggleEnabled = groupWithTools.isDefaultGroup
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
           ? (() => unawaited(
               McpErrorDetails.show(
                 context,
                 groupName: groupWithTools.group?.name,
                 errorMessage: groupWithTools.mcpErrorMessage,
               ),
             ))
           : null;

  final VoidCallback? onOpenConnection;
  final ValueChanged<bool>? onToggleEnabled;
  final VoidCallback? onReconnect;
  final VoidCallback? onDelete;
  final VoidCallback? onViewError;
}

Future<void> _openConnection(
  ToolsGroupWithTools groupWithTools,
  String workspaceId,
  WidgetRef ref,
  BuildContext context,
) async {
  final serverId = groupWithTools.mcpServerId;
  if (serverId == null) return;

  final saved = await ServiceConnectionEditRoute(
    workspaceId: workspaceId,
    connectionId: serverId,
  ).push<bool>(context);
  if (saved != true || !context.mounted) return;

  ref
    ..invalidate(workspaceToolsProvider(workspaceId))
    ..invalidate(groupedToolsProvider(workspaceId));
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

  final _ = await ref
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

class const _ToolsGroupCardLayout({
  required final ToolsGroupCard card,
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
          card: card,
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
  required final ToolsGroupCard card,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
  required final _ToolsGroupCardCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ToolsGroupCardHeader(
        card: card,
        isExpanded: isExpanded,
        onToggleExpand: onToggleExpand,
        callbacks: callbacks,
      ),
      if (callbacks.onOpenConnection case final onOpenConnection?)
        AuraButton(
          onPressed: onOpenConnection,
          child: const TextLocale(LocaleKeys.related_lists_open_connection),
          key: ValueKey(
            'tools-open-connection-${card.groupWithTools.mcpServerId}',
          ),
          variant: .text,
          size: .small,
          disabled: card.isDeleting,
        ),
      _ExpandedToolsGroup(card: card, isExpanded: isExpanded),
    ],
    crossAxisAlignment: .start,
  );
}

class const _ToolsGroupCardHeader({
  required final ToolsGroupCard card,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
  required final _ToolsGroupCardCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ToolsGroupHeader.managed(
      groupWithTools: card.groupWithTools,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
      selection: _toolsGroupSelection(card),
      actions: _toolsGroupActions(card, callbacks),
    );
  }
}

ToolsGroupHeaderSelection _toolsGroupSelection(ToolsGroupCard card) {
  final selectionKey = _groupSelectionKey(card);

  return (
    isSelected:
        selectionKey != null && card.selectedTargetKeys.contains(selectionKey),
    isWorking: card.isDeleting,
    onChanged: _groupSelectionChanged(card, selectionKey),
  );
}

String? _groupSelectionKey(ToolsGroupCard card) {
  final groupId = card.groupWithTools.group?.id;

  return groupId == null ? null : 'group:$groupId';
}

ToolsGroupHeaderActions _toolsGroupActions(
  ToolsGroupCard card,
  _ToolsGroupCardCallbacks callbacks,
) => (
  onToggleEnabled: _unlessDeleting(card, callbacks.onToggleEnabled),
  onReconnect: _unlessDeleting(card, callbacks.onReconnect),
  onDelete: _unlessDeleting(card, callbacks.onDelete),
  onViewError: _unlessDeleting(card, callbacks.onViewError),
);

T? _unlessDeleting<T>(ToolsGroupCard card, T? callback) =>
    card.isDeleting ? null : callback;

ValueChanged<bool>? _groupSelectionChanged(
  ToolsGroupCard card,
  String? selectionKey,
) {
  final onSelectionChanged = card.onSelectionChanged;
  if (!card.groupWithTools.isMcpGroup ||
      selectionKey == null ||
      onSelectionChanged == null) {
    return null;
  }

  return (value) => onSelectionChanged(selectionKey, (isSelected: value));
}

class const _ExpandedToolsGroup({
  required final ToolsGroupCard card,
  required final bool isExpanded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!isExpanded) return const SizedBox.shrink();

    return Column(
      children: [
        const AuraDivider(),
        _ToolsList(card: card),
      ],
    );
  }
}

/// List of tools within a group.
class const _ToolsList({required final ToolsGroupCard card})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tools = card.visibleTools ?? card.groupWithTools.tools;
    if (tools.isEmpty) return const _EmptyToolsGroup();

    return _ToolsGroupRows(card: card, tools: tools);
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
  required final ToolsGroupCard card,
  required final List<WorkspaceToolEntity> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.fromSpacing(.sm),
      ),
      child: _ToolRows(card: card, tools: tools),
    );
  }
}

class const _ToolRows({
  required final ToolsGroupCard card,
  required final List<WorkspaceToolEntity> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final tool in tools)
          _SelectableToolRow(
            card: card,
            tool: tool,
            key: ValueKey('tool-row-${tool.id}'),
          ),
      ],
    );
  }
}

class const _SelectableToolRow({
  required final ToolsGroupCard card,
  required final WorkspaceToolEntity tool,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolItemRowForSelection(
    card: card,
    tool: tool,
    selection: _toolItemSelection(
      card,
      tool,
      'tool:${tool.id}',
      !card.groupWithTools.isMcpGroup,
    ),
  );
}

class const _ToolItemRowForSelection({
  required final ToolsGroupCard card,
  required final WorkspaceToolEntity tool,
  required final ToolItemSelection? selection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final showDeleteButton = !card.groupWithTools.isMcpGroup;
    final currentSelection = selection;
    if (currentSelection == null) {
      return ToolItemRow(
        tool: tool,
        workspaceId: card.workspaceId,
        showDeleteButton: showDeleteButton,
        isWorking: card.isDeleting,
      );
    }

    return ToolItemRow.selectable(
      tool: tool,
      workspaceId: card.workspaceId,
      selection: currentSelection,
      showDeleteButton: showDeleteButton,
    );
  }
}

ToolItemSelection? _toolItemSelection(
  ToolsGroupCard card,
  WorkspaceToolEntity tool,
  String selectionKey,
  bool showDeleteButton,
) {
  final onSelectionChanged = card.onSelectionChanged;
  if (onSelectionChanged == null || !showDeleteButton || tool.isNative) {
    return null;
  }

  return (
    isSelected: card.selectedTargetKeys.contains(selectionKey),
    isWorking: card.isDeleting,
    onChanged: (value) => onSelectionChanged(selectionKey, (isSelected: value)),
  );
}
