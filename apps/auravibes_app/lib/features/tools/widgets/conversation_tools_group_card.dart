import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/providers/grouped_conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_group_header.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tool_tile.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Locale key for no tools in group message
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
class ConversationToolsGroupCard extends HookConsumerWidget {
  const ConversationToolsGroupCard({
    required this.groupWithTools,
    required this.workspaceId,
    this.conversationId,
    this.initiallyExpanded = false,
    super.key,
  });

  final ConversationToolsGroupWithTools groupWithTools;
  final String workspaceId;
  final String? conversationId;

  /// Whether the group should be initially expanded.
  /// Defaults to false (collapsed).
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(initiallyExpanded);

    return Padding(
      padding: EdgeInsets.only(bottom: context.auraTheme.spacing.md),
      child: AuraCard(
        child: AuraColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ConversationGroupHeader(
              groupWithTools: groupWithTools,
              isExpanded: isExpanded.value,
              onToggleExpand: () => isExpanded.value = !isExpanded.value,
              onToggleAllTools: groupWithTools.tools.isNotEmpty
                  ? (enabled) => _handleToggleAllTools(ref, enabled)
                  : null,
              onReconnect: _shouldShowReconnect()
                  ? () => _handleReconnect(ref)
                  : null,
              onViewError: groupWithTools.hasMcpError
                  ? () => _showErrorDetails(context)
                  : null,
            ),

            // Expanded content
            if (isExpanded.value) ...[
              const AuraDivider(),
              _ToolsList(
                groupWithTools: groupWithTools,
                workspaceId: workspaceId,
                conversationId: conversationId,
              ),
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

  Future<void> _handleToggleAllTools(WidgetRef ref, bool enabled) async {
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
        );
  }

  Future<void> _handleReconnect(WidgetRef ref) async {
    if (groupWithTools.mcpServerId == null) return;

    await ref
        .read(
          groupedConversationToolsProvider(
            workspaceId: workspaceId,
            conversationId: conversationId,
          ).notifier,
        )
        .reconnectMcp(groupWithTools.mcpServerId!);
  }

  void _showErrorDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_kMcpErrorTitle.tr()),
        content: SingleChildScrollView(
          child: SelectableText(
            groupWithTools.mcpErrorMessage ?? 'Unknown error',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.common_cancel.tr()),
          ),
        ],
      ),
    );
  }
}

/// List of conversation tools within a group.
class _ToolsList extends StatelessWidget {
  const _ToolsList({
    required this.groupWithTools,
    required this.workspaceId,
    this.conversationId,
  });

  final ConversationToolsGroupWithTools groupWithTools;
  final String workspaceId;
  final String? conversationId;

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
      padding: EdgeInsets.all(context.auraTheme.spacing.sm),
      child: AuraColumn(
        spacing: AuraSpacing.sm,
        children: groupWithTools.tools.map((toolState) {
          return ConversationToolTile(
            toolState: toolState,
            workspaceId: workspaceId,
            conversationId: conversationId,
          );
        }).toList(),
      ),
    );
  }
}
