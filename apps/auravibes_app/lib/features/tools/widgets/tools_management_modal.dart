import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/providers/grouped_conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tools_group_card.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
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
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 500,
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
                    style: AuraTextStyle.heading6,
                    child: Text('Manage Tools'),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const AuraIcon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: context.auraColors.onSurfaceVariant,
                    ),
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
                  conversationId: conversationId,
                  workspaceId: workspaceId,
                ),
                AsyncError(:final error) => Center(
                  child: AuraText(
                    color: AuraColorVariant.error,
                    child: Text('Error loading tools: $error'),
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
      return Padding(
        padding: const EdgeInsets.all(DesignSpacing.lg),
        child: Center(
          child: AuraColumn(
            mainAxisSize: MainAxisSize.min,
            spacing: AuraSpacing.md,
            children: [
              AuraIcon(
                Icons.build_circle_outlined,
                size: AuraIconSize.extraLarge,
                color: context.auraColors.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const AuraText(
                style: AuraTextStyle.heading6,
                color: AuraColorVariant.onSurfaceVariant,
                textAlign: TextAlign.center,
                child: TextLocale(LocaleKeys.tools_screen_no_tools_added),
              ),
              const AuraText(
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.onSurfaceVariant,
                textAlign: TextAlign.center,
                child: TextLocale(LocaleKeys.tools_screen_add_tools_hint),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(DesignSpacing.md),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];

        return ConversationToolsGroupCard(
          groupWithTools: group,
          workspaceId: workspaceId,
          conversationId: conversationId,
        );
      },
    );
  }
}
