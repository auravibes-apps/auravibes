// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_group_header.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tool_tile.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Locale key for no tools in group message.
const _kNoToolsInGroup = 'tools_screen.no_tools_in_group';
const _kMcpErrorTitle = 'tools_screen.mcp_error';

/// A collapsible card widget that displays a conversation tools group.
///
/// Shows:
/// - Group header with icon, name, MCP status, toggle, and expand chevron
/// - Expandable list of conversation tools belonging to this group
/// - MCP status indicators and reconnect actions for MCP groups
///
/// Groups are collapsed by default. The user can expand them to see and
/// configure individual tools.
class const ConversationToolsGroupCard({
  required final ConversationToolsGroupWithTools groupWithTools,
  required final String workspaceId,
  final String? conversationId,

  /// Whether the group should be initially expanded.
  /// Defaults to false (collapsed).
  final bool initiallyExpanded = false,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(initiallyExpanded);
    final callbacks = _ConversationToolsGroupCardCallbacks(
      groupWithTools: groupWithTools,
      workspaceId: workspaceId,
      conversationId: conversationId,
      ref: ref,
      context: context,
    );

    return _ConversationToolsGroupCardFrame(
      groupWithTools: groupWithTools,
      workspaceId: workspaceId,
      conversationId: conversationId,
      isExpanded: isExpanded.value,
      onToggleExpand: () => isExpanded.value = !isExpanded.value,
      callbacks: callbacks,
    );
  }
}

class _ConversationToolsGroupCardCallbacks {
  _ConversationToolsGroupCardCallbacks({
    required this.groupWithTools,
    required this.workspaceId,
    required this.conversationId,
    required this.ref,
    required this.context,
  });

  final ConversationToolsGroupWithTools groupWithTools;
  final String workspaceId;
  final String? conversationId;
  final WidgetRef ref;
  final BuildContext context;

  late final ValueChanged<bool>? onToggleAllTools =
      groupWithTools.tools.isNotEmpty ? _handleToggleAllTools : null;

  late final VoidCallback? onReconnect = _shouldShowReconnect
      ? _handleReconnect
      : null;

  late final VoidCallback? onViewError = groupWithTools.hasMcpError
      ? _showErrorDetails
      : null;

  late final bool _shouldShowReconnect =
      groupWithTools.isMcpGroup &&
      (groupWithTools.hasMcpError || groupWithTools.isMcpDisconnected);

  Future<void> _handleToggleAllTools(bool enabled) async {
    await ref
        .read(
          groupedConversationToolsProvider(
            workspaceId: workspaceId,
            conversationId: conversationId,
          ).notifier,
        )
        .toggleGroupTools(
          groupWithTools.group?.id,
          enabled: enabled,
          defaultGroupType: groupWithTools.defaultGroupType,
        );
  }

  Future<void> _handleReconnect() async {
    final mcpServerId = groupWithTools.mcpServerId;
    if (mcpServerId == null) return;

    await ref
        .read(
          groupedConversationToolsProvider(
            workspaceId: workspaceId,
            conversationId: conversationId,
          ).notifier,
        )
        .reconnectMcp(mcpServerId);
  }

  void _showErrorDetails() {
    AuraDialogs.alert(
      context: context,
      title: Text(_kMcpErrorTitle.tr()),
      message: AuraSelectableText(
        groupWithTools.mcpErrorMessage ?? 'Unknown error',
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_cancel),
    );
  }
}

class const _ConversationToolsGroupCardFrame({
  required final ConversationToolsGroupWithTools groupWithTools,
  required final String workspaceId,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
  required final _ConversationToolsGroupCardCallbacks callbacks,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.auraTheme.fromSpacing(.md)),
    child: AuraCard(
      child: _ConversationToolsGroupCardContent(
        groupWithTools: groupWithTools,
        workspaceId: workspaceId,
        conversationId: conversationId,
        isExpanded: isExpanded,
        onToggleExpand: onToggleExpand,
        callbacks: callbacks,
      ),
      style: .border,
    ),
  );
}

class const _ConversationToolsGroupCardContent({
  required final ConversationToolsGroupWithTools groupWithTools,
  required final String workspaceId,
  required final bool isExpanded,
  required final VoidCallback onToggleExpand,
  required final _ConversationToolsGroupCardCallbacks callbacks,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      ConversationGroupHeader(
        groupWithTools: groupWithTools,
        isExpanded: isExpanded,
        onToggleExpand: onToggleExpand,
        onToggleAllTools: callbacks.onToggleAllTools,
        onReconnect: callbacks.onReconnect,
        onViewError: callbacks.onViewError,
      ),
      if (isExpanded) ...[
        const AuraDivider(),
        _ToolsList(
          groupWithTools: groupWithTools,
          workspaceId: workspaceId,
          conversationId: conversationId,
        ),
      ],
    ],
    crossAxisAlignment: .start,
  );
}

/// List of conversation tools within a group.
class const _ToolsList({
  required final ConversationToolsGroupWithTools groupWithTools,
  required final String workspaceId,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (groupWithTools.tools.isEmpty) {
      return const _EmptyTools();
    }

    return _ToolRows(
      tools: groupWithTools.tools,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
  }
}

class const _EmptyTools() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      vertical: context.auraTheme.fromSpacing(.md),
      horizontal: context.auraTheme.fromSpacing(.sm),
    ),
    child: Center(
      child: AuraText(child: Text(_kNoToolsInGroup.tr()), style: .bodySmall),
    ),
  );
}

class const _ToolRows({
  required final List<ConversationToolState> tools,
  required final String workspaceId,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.sm)),
    child: AuraColumn(
      children: [
        for (final toolState in tools)
          ConversationToolTile(
            toolState: toolState,
            workspaceId: workspaceId,
            conversationId: conversationId,
          ),
      ],
      spacing: .sm,
    ),
  );
}
