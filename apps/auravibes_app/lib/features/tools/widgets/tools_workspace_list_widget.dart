// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tools_empty_state.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search_empty_state.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search_input.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Widget that displays workspace tools organized by groups.
///
/// Shows the Built-in Tools default group, MCP groups with connection status,
/// and custom tool groups. Groups are sorted with the default group first,
/// MCP groups with errors next, and remaining groups by newest creation date.
class const ToolsWorkspaceListWidget({
  required final String workspaceId,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedToolsAsync = ref.watch(groupedToolsProvider(workspaceId));
    final searchQuery = useState('');

    return _ToolsWorkspaceListState(
      groupedToolsAsync: groupedToolsAsync,
      workspaceId: workspaceId,
      searchQuery: searchQuery.value,
      onSearchChanged: (value) => searchQuery.value = value,
    );
  }
}

class const _ToolsWorkspaceListState({
  required final AsyncValue<List<ToolsGroupWithTools>> groupedToolsAsync,
  required final String workspaceId,
  required final String searchQuery,
  required final ValueChanged<String> onSearchChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToolsSearchInput(onChanged: onSearchChanged),
        Expanded(
          child: switch (groupedToolsAsync) {
            AsyncLoading() => const _ToolsLoading(),
            AsyncData(value: final groups) => _ToolsGroupListOrEmpty(
              groups: groups,
              workspaceId: workspaceId,
              searchQuery: searchQuery,
            ),
            AsyncError(:final error, :final stackTrace) => _ToolsError(
              error: error,
              stackTrace: stackTrace,
            ),
          },
        ),
      ],
    );
  }
}

class const _ToolsLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(child: AuraSpinner());
}

class const _ToolsGroupListOrEmpty({
  required final List<ToolsGroupWithTools> groups,
  required final String workspaceId,
  required final String searchQuery,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty && searchQuery.trim().isEmpty) {
      return ToolsEmptyState(
        padding: EdgeInsets.all(context.auraTheme.fromSpacing(.xl)),
      );
    }

    final filteredGroups = _filterWorkspaceGroups(groups, searchQuery);
    if (filteredGroups.isEmpty) return const ToolsSearchEmptyState();

    return _ToolsGroupList(groups: filteredGroups, workspaceId: workspaceId);
  }
}

class const _ToolsError({
  required final Object error,
  required final StackTrace stackTrace,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AppErrorWidget(error: error, stackTrace: stackTrace);
}

class const _ToolsGroupList({
  required final List<_WorkspaceToolsGroupResult> groups,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.sm),
      ),
      itemBuilder: _itemBuilder,
      itemCount: groups.length,
    );
  }

  Widget _itemBuilder(BuildContext _, int index) {
    final result = groups[index];

    return ToolsGroupCard(
      groupWithTools: result.group,
      workspaceId: workspaceId,
      visibleTools: result.tools,
    );
  }
}

typedef _WorkspaceToolsGroupResult = ({
  ToolsGroupWithTools group,
  List<WorkspaceToolEntity> tools,
});

List<_WorkspaceToolsGroupResult> _filterWorkspaceGroups(
  List<ToolsGroupWithTools> groups,
  String query,
) => groups
    .map((group) => _matchingWorkspaceGroup(group, query))
    .whereType<_WorkspaceToolsGroupResult>()
    .toList();

_WorkspaceToolsGroupResult? _matchingWorkspaceGroup(
  ToolsGroupWithTools group,
  String query,
) {
  if (ToolsSearch.matches(query, _workspaceGroupSearchValues(group))) {
    return (group: group, tools: group.tools);
  }

  final matchingTools = _matchingWorkspaceTools(group.tools, query);
  if (matchingTools.isEmpty) return null;

  return (group: group, tools: matchingTools);
}

List<WorkspaceToolEntity> _matchingWorkspaceTools(
  List<WorkspaceToolEntity> tools,
  String query,
) => tools
    .where((tool) => ToolsSearch.matches(query, _toolSearchValues(tool)))
    .toList();

Iterable<String?> _workspaceGroupSearchValues(ToolsGroupWithTools group) => [
  group.group?.name,
  group.group?.id,
  group.mcpServerId,
  group.mcpConnectionState?.server.name,
  group.defaultGroupType?.name,
  group.localizedDisplayNameKey?.tr(),
  if (group.isMcpGroup) 'mcp',
];

Iterable<String?> _toolSearchValues(WorkspaceToolEntity tool) => [
  tool.id,
  tool.toolId,
  tool.toolId.toHumanReadable(),
  tool.description,
  tool.workspaceToolsGroupId,
];
