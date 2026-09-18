// Required: Existing thresholds and limits use numeric values.
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_empty_state.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search_empty_state.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search_input.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
      supported: capabilities.conversationToolOverrides,
      conversationId: conversationId,
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
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(_ToolsManagementController.new);
    useEffect(() => controller.dispose, [controller]);
    final _ = useListenable(controller);

    return _ToolsManagementColumn(
      groupedToolsAsync: groupedToolsAsync,
      workspaceId: workspaceId,
      controller: controller,
      conversationId: conversationId,
    );
  }
}

class _ToolsManagementController extends ChangeNotifier {
  String searchQuery = '';
  bool initiallyExpanded = false;
  int expansionCommand = 0;

  void setSearchQuery(String value) {
    if (value == searchQuery) return;

    searchQuery = value;
    notifyListeners();
  }

  void setAllGroupsExpanded({required bool expanded}) {
    initiallyExpanded = expanded;
    expansionCommand++;
    notifyListeners();
  }

  void expandAll() => setAllGroupsExpanded(expanded: true);

  void collapseAll() => setAllGroupsExpanded(expanded: false);
}

class const _ToolsManagementColumn({
  required final AsyncValue<List<ConversationToolsGroupWithTools>>
  groupedToolsAsync,
  required final String workspaceId,
  required final _ToolsManagementController controller,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        _ToolsManagementHeader(controller: controller),
        ToolsSearchInput(onChanged: controller.setSearchQuery),
        Flexible(
          child: _ToolsManagementContent(
            groupedToolsAsync: groupedToolsAsync,
            workspaceId: workspaceId,
            controller: controller,
            conversationId: conversationId,
          ),
        ),
        const AuraSizedBox(height: .md),
      ],
    );
  }
}

class const _ToolsManagementHeader({
  required final _ToolsManagementController controller,
}) extends StatelessWidget {
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
      child: _ToolsManagementHeaderRow(controller: controller),
    );
  }
}

class const _ToolsManagementHeaderRow({
  required final _ToolsManagementController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.tools_screen_manage_title),
          style: .heading6,
        ),
        const Spacer(),
        _ExpandAllGroupsButton(controller: controller),
        _CollapseAllGroupsButton(controller: controller),
        const _CloseToolsManagementButton(),
      ],
    );
  }
}

class const _ExpandAllGroupsButton({
  required final _ToolsManagementController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.unfold_more,
    onPressed: controller.expandAll,
    key: const ValueKey('tools_expand_all_groups'),
    semanticLabel: LocaleKeys.tools_screen_expand_all_groups,
    tooltip: LocaleKeys.tools_screen_expand_all_groups.tr(),
  );
}

class const _CollapseAllGroupsButton({
  required final _ToolsManagementController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.unfold_less,
    onPressed: controller.collapseAll,
    key: const ValueKey('tools_collapse_all_groups'),
    semanticLabel: LocaleKeys.tools_screen_collapse_all_groups,
    tooltip: LocaleKeys.tools_screen_collapse_all_groups.tr(),
  );
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
  required final _ToolsManagementController controller,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (groupedToolsAsync) {
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncData(:final value) => _ToolsManagementData(
      groups: value,
      workspaceId: workspaceId,
      searchQuery: controller.searchQuery,
      initiallyExpanded: controller.initiallyExpanded,
      expansionCommand: controller.expansionCommand,
      conversationId: conversationId,
    ),
    AsyncError(:final error) => _ToolsManagementError(error: error),
  };
}

class const _ToolsManagementData({
  required final List<ConversationToolsGroupWithTools> groups,
  required final String workspaceId,
  required final String searchQuery,
  required final bool initiallyExpanded,
  required final int expansionCommand,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(expansionCommand),
      child: _GroupedToolsList(
        groups: groups,
        workspaceId: workspaceId,
        searchQuery: searchQuery,
        initiallyExpanded: initiallyExpanded,
        conversationId: conversationId,
      ),
    );
  }
}

class const _ToolsManagementError({required final Object error})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: AuraText(
      child: TextLocale(CloudAppErrors.localizationKey(error)),
      tint: .error,
    ),
  );
}

/// List of grouped conversation tools.
class const _GroupedToolsList({
  required final List<ConversationToolsGroupWithTools> groups,
  required final String workspaceId,
  required final String searchQuery,
  required final bool initiallyExpanded,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty && searchQuery.trim().isEmpty) {
      return const ToolsEmptyState();
    }

    final filteredGroups = _filterConversationGroups(groups, searchQuery);
    if (filteredGroups.isEmpty) return const ToolsSearchEmptyState();

    return _GroupedToolsListView(
      groups: filteredGroups,
      workspaceId: workspaceId,
      initiallyExpanded: initiallyExpanded,
      conversationId: conversationId,
    );
  }
}

class const _GroupedToolsListView({
  required final List<_ConversationToolsGroupResult> groups,
  required final String workspaceId,
  required final bool initiallyExpanded,
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

  Widget _itemBuilder(BuildContext _, int index) => _ConversationToolsGroupItem(
    result: groups[index],
    workspaceId: workspaceId,
    initiallyExpanded: initiallyExpanded,
    conversationId: conversationId,
  );
}

class const _ConversationToolsGroupItem({
  required final _ConversationToolsGroupResult result,
  required final String workspaceId,
  required final bool initiallyExpanded,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConversationToolsGroupCard(
      groupWithTools: result.group,
      workspaceId: workspaceId,
      visibleTools: result.tools,
      conversationId: conversationId,
      initiallyExpanded: initiallyExpanded,
    );
  }
}

typedef _ConversationToolsGroupResult = ({
  ConversationToolsGroupWithTools group,
  List<ConversationToolState> tools,
});

List<_ConversationToolsGroupResult> _filterConversationGroups(
  List<ConversationToolsGroupWithTools> groups,
  String query,
) => groups
    .map((group) => _matchingConversationGroup(group, query))
    .whereType<_ConversationToolsGroupResult>()
    .toList();

_ConversationToolsGroupResult? _matchingConversationGroup(
  ConversationToolsGroupWithTools group,
  String query,
) {
  if (ToolsSearch.matches(query, _conversationGroupSearchValues(group))) {
    return (group: group, tools: group.tools);
  }

  final matchingTools = _matchingConversationTools(group.tools, query);
  if (matchingTools.isEmpty) return null;

  return (group: group, tools: matchingTools);
}

List<ConversationToolState> _matchingConversationTools(
  List<ConversationToolState> tools,
  String query,
) => tools
    .where(
      (toolState) =>
          ToolsSearch.matches(query, _conversationToolSearchValues(toolState)),
    )
    .toList();

Iterable<String?> _conversationGroupSearchValues(
  ConversationToolsGroupWithTools group,
) => [
  group.group?.name,
  group.group?.id,
  group.mcpServerId,
  group.mcpConnectionState?.server.name,
  group.defaultGroupType?.name,
  group.localizedDisplayNameKey?.tr(),
  if (group.isMcpGroup) 'mcp',
];

Iterable<String?> _conversationToolSearchValues(
  ConversationToolState toolState,
) => [
  toolState.tool.id,
  toolState.tool.toolId,
  toolState.tool.toolId.toHumanReadable(),
  toolState.tool.description,
  toolState.tool.workspaceToolsGroupId,
];
