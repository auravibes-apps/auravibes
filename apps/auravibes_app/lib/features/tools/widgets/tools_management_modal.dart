import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_empty_state.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal for managing conversation tools
///
/// Shows ALL workspace tools organized by group (Built-in Tools, MCP servers).
/// Each group is collapsible (collapsed by default) with:
/// - MCP status indicators for MCP groups
/// - Group-level toggle to enable/disable all tools at once
/// - Reconnect button for MCP groups with connection issues
class ToolsManagementModal extends ConsumerWidget {
  const ToolsManagementModal({
    required this.workspaceId,
    super.key,
    this.conversationId,
  });

  final String? conversationId;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedToolsAsync = ref.watch(
      groupedConversationToolsProvider(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignBorderRadius.xl),
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(DesignSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.auraColors.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const AuraText(
                    child: Text('Manage Tools'),
                    style: AuraTextStyle.heading6,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: context.auraColors.onSurfaceVariant,
                    ),
                    icon: const AuraIcon(Icons.close),
                  ),
                ],
              ),
            ),

            // Tools groups list
            Flexible(
              child: switch (groupedToolsAsync) {
                AsyncLoading() => const Center(child: AuraSpinner()),
                AsyncData(:final value) => _GroupedToolsList(
                  groups: value,
                  workspaceId: workspaceId,
                  conversationId: conversationId,
                ),
                AsyncError(:final error) => Center(
                  child: AuraText(
                    child: Text('Error loading tools: $error'),
                    color: AuraColorVariant.error,
                  ),
                ),
              },
            ),

            // Bottom padding
            const SizedBox(height: DesignSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// List of grouped conversation tools.
class _GroupedToolsList extends StatelessWidget {
  const _GroupedToolsList({
    required this.groups,
    required this.workspaceId,
    this.conversationId,
  });

  final List<ConversationToolsGroupWithTools> groups;
  final String? conversationId;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const ToolsEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(DesignSpacing.md),
      itemBuilder: (context, index) {
        final group = groups[index];

        return ConversationToolsGroupCard(
          groupWithTools: group,
          workspaceId: workspaceId,
          conversationId: conversationId,
        );
      },
      itemCount: groups.length,
    );
  }
}
