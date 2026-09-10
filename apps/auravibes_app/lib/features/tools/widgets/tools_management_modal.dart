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
class const ToolsManagementModal({
  required final String workspaceId,
  super.key,
  final String? conversationId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref
        .watch(workspaceSessionForRouteProvider(workspaceId))
        .requireValue
        .capabilities;
    return _ToolsManagementCapabilityView(
      workspaceId: workspaceId,
      conversationId: conversationId,
      supported: capabilities.conversationToolOverrides,
    );
  }
}

class const _ToolsManagementCapabilityView({
  required final String workspaceId,
  required final bool supported,
  final String? conversationId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!supported) return const _UnsupportedConversationTools();

    return _ToolsManagementDialog(
      workspaceId: workspaceId,
      groupedToolsAsync: ref.watch(
        groupedConversationToolsProvider(
          workspaceId: workspaceId,
          conversationId: conversationId,
        ),
      ),
      conversationId: conversationId,
    );
  }
}

class const _UnsupportedConversationTools() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: TextLocale(LocaleKeys.workspace_capabilities_unsupported_error),
      ),
    );
  }
}

class const _ToolsManagementDialog({
  required final String workspaceId,
  required final AsyncValue<List<ConversationToolsGroupWithTools>>
  groupedToolsAsync,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          .circular(context.auraTheme.fromBorderRadius(.xl)),
        ),
      ),
      child: _ToolsManagementDialogBody(
        groupedToolsAsync: groupedToolsAsync,
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    );
  }
}

class const _ToolsManagementDialogBody({
  required final AsyncValue<List<ConversationToolsGroupWithTools>>
  groupedToolsAsync,
  required final String workspaceId,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.9,
      constraints: .new(
        maxWidth: 500,
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: _ToolsManagementDialogColumn(
        groupedToolsAsync: groupedToolsAsync,
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    );
  }
}

class const _ToolsManagementDialogColumn({
  required final AsyncValue<List<ConversationToolsGroupWithTools>>
  groupedToolsAsync,
  required final String workspaceId,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        const _ToolsManagementHeader(),
        Flexible(
          child: _ToolsManagementContent(
            groupedToolsAsync: groupedToolsAsync,
            workspaceId: workspaceId,
            conversationId: conversationId,
          ),
        ),
        const AuraSizedBox(height: .md),
      ],
    );
  }
}

class const _ToolsManagementHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
      decoration: BoxDecoration(
        border: Border(
          bottom: .new(
            color: context.auraColors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: const _ToolsManagementHeaderRow(),
    );
  }
}

class const _ToolsManagementHeaderRow() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AuraText(
          child: TextLocale(LocaleKeys.tools_screen_manage_title),
          style: .heading6,
        ),
        Spacer(),
        _CloseToolsManagementButton(),
      ],
    );
  }
}

class const _CloseToolsManagementButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.close,
      onPressed: () => Navigator.of(context).pop(),
      semanticLabel: LocaleKeys.common_close_dialog.tr(),
    );
  }
}

class const _ToolsManagementContent({
  required final AsyncValue<List<ConversationToolsGroupWithTools>>
  groupedToolsAsync,
  required final String workspaceId,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (groupedToolsAsync) {
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncData(:final value) => _GroupedToolsList(
        groups: value,
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
      AsyncError(:final error) => Center(
        child: AuraText(
          child: TextLocale(CloudAppErrors.localizationKey(error)),
          tint: .error,
        ),
      ),
    };
  }
}

/// List of grouped conversation tools.
class const _GroupedToolsList({
  required final List<ConversationToolsGroupWithTools> groups,
  required final String workspaceId,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const ToolsEmptyState();
    }

    return _GroupedToolsListView(
      groups: groups,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
  }
}

class const _GroupedToolsListView({
  required final List<ConversationToolsGroupWithTools> groups,
  required final String workspaceId,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
      itemBuilder: _itemBuilder,
      itemCount: groups.length,
    );
  }

  Widget _itemBuilder(BuildContext context, int index) =>
      _ConversationToolsGroupItem(
        group: groups[index],
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
}

class const _ConversationToolsGroupItem({
  required final ConversationToolsGroupWithTools group,
  required final String workspaceId,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConversationToolsGroupCard(
      groupWithTools: group,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
  }
}
