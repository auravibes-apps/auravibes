// Required: Existing thresholds and limits use numeric values.
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_empty_state.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal for managing conversation tools.
///
/// Shows all workspace tools organized by group, with each group collapsed by
/// default. MCP groups include status indicators, group-level toggles, and a
/// reconnect button for connection issues.
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
    if (!ref
        .watch(workspaceSessionForRouteProvider(workspaceId))
        .requireValue
        .capabilities
        .conversationToolOverrides) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: TextLocale(
            LocaleKeys.workspace_capabilities_unsupported_error,
          ),
        ),
      );
    }
    final groupedToolsAsync = ref.watch(
      groupedConversationToolsProvider(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(context.auraTheme.fromBorderRadius(.xl)),
        ),
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
            // Header with close button.
            Container(
              padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
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
                    child: TextLocale(LocaleKeys.tools_screen_manage_title),
                    style: AuraTextStyle.heading6,
                  ),
                  const Spacer(),
                  AuraIconButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    semanticLabel: LocaleKeys.common_close_dialog.tr(),
                  ),
                ],
              ),
            ),

            // Tools groups list.
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
                    child: TextLocale(CloudAppErrors.localizationKey(error)),
                    tint: AuraTint.error,
                  ),
                ),
              },
            ),

            // Bottom padding.
            const AuraSizedBox(height: .md),
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
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
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
