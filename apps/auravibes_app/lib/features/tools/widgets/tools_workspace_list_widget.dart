// Required: Existing code repeats lookups where extraction adds noise.
import 'dart:async';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tools_empty_state.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search_empty_state.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search_input.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('tools_workspace_list');

enum _ToolsSort { name, enabled }

enum _ToolsDeleteTargetKind { group, tool }

typedef _ToolsDeleteTarget = ({
  _ToolsDeleteTargetKind kind,
  String id,
  String key,
  String label,
});

typedef _ToolSelectionChanged = void Function(
  String key,
  ({bool isSelected}) change,
);

typedef _ToolsWorkspaceHooks = ({
  ValueNotifier<String> searchQuery,
  ValueNotifier<_ToolsSort> sort,
  ValueNotifier<Set<String>> selectedKeys,
  ValueNotifier<bool> isDeleting,
});

typedef _ToolsFilterState = ({
  String searchQuery,
  _ToolsSort sort,
  ValueChanged<String> onSearchChanged,
  ValueChanged<_ToolsSort> onSortChanged,
});

typedef _ToolsSelectionData = ({
  Set<String> selectedKeys,
  int selectedCount,
  int selectableCount,
  bool allVisibleSelected,
  bool isDeleting,
});

typedef _ToolsSelectionCallbacks = ({
  VoidCallback onSelectAll,
  VoidCallback onClear,
  VoidCallback onDelete,
  _ToolSelectionChanged onSelectionChanged,
});

typedef _ToolsSelectionSnapshot = ({
  List<_ToolsDeleteTarget> visibleTargets,
  List<_ToolsDeleteTarget> selectedTargets,
  bool allVisibleSelected,
});

typedef _ToolsWorkspaceViewState = ({
  AsyncValue<List<ToolsGroupWithTools>> groupedToolsAsync,
  String workspaceId,
  _ToolsFilterState filter,
  _ToolsSelectionData selection,
  _ToolsSelectionCallbacks actions,
});

typedef _ToolsWorkspaceRuntime = ({
  AsyncValue<List<ToolsGroupWithTools>> groupedToolsAsync,
  _ToolsWorkspaceHooks hooks,
  _ToolsSelectionSnapshot snapshot,
});

/// Widget that displays workspace tools organized by groups.
///
/// Shows the Built-in Tools default group, MCP groups with connection status,
/// and custom tool groups. Groups and tools support deterministic name and
/// enabled-first sorting.
class const ToolsWorkspaceListWidget({
  required final String workspaceId,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _ToolsWorkspaceListState(
    state: _useToolsWorkspaceViewState(context, ref, workspaceId),
  );
}

_ToolsWorkspaceViewState _useToolsWorkspaceViewState(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) {
  final runtime = _useToolsWorkspaceRuntime(ref, workspaceId);

  return _toolsWorkspaceViewState((
    context: context,
    ref: ref,
    workspaceId: workspaceId,
    runtime: runtime,
  ));
}

_ToolsWorkspaceRuntime _useToolsWorkspaceRuntime(
  WidgetRef ref,
  String workspaceId,
) {
  final groupedToolsAsync = ref.watch(groupedToolsProvider(workspaceId));
  final hooks = _useToolsWorkspaceHooks();
  final groups = groupedToolsAsync.value ?? const <ToolsGroupWithTools>[];

  return (
    groupedToolsAsync: groupedToolsAsync,
    hooks: hooks,
    snapshot: _toolsSelectionSnapshot(groups, hooks),
  );
}

typedef _ToolsWorkspaceViewRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  _ToolsWorkspaceRuntime runtime,
});

_ToolsWorkspaceViewState _toolsWorkspaceViewState(
  _ToolsWorkspaceViewRequest request,
) {
  final runtime = request.runtime;

  return (
    groupedToolsAsync: runtime.groupedToolsAsync,
    workspaceId: request.workspaceId,
    filter: _toolsFilterState(runtime.hooks),
    selection: _toolsSelectionData(runtime.hooks, runtime.snapshot),
    actions: _toolsSelectionActions(_toolsSelectionActionsRequest(request)),
  );
}

_ToolsSelectionActionsRequest _toolsSelectionActionsRequest(
  _ToolsWorkspaceViewRequest request,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  hooks: request.runtime.hooks,
  snapshot: request.runtime.snapshot,
);

_ToolsWorkspaceHooks _useToolsWorkspaceHooks() => (
  searchQuery: useState(''),
  sort: useState(_ToolsSort.name),
  selectedKeys: useState(<String>{}),
  isDeleting: useState(false),
);

_ToolsFilterState _toolsFilterState(_ToolsWorkspaceHooks hooks) => (
  searchQuery: hooks.searchQuery.value,
  sort: hooks.sort.value,
  onSearchChanged: (value) => hooks.searchQuery.value = value,
  onSortChanged: (value) => hooks.sort.value = value,
);

_ToolsSelectionSnapshot _toolsSelectionSnapshot(
  List<ToolsGroupWithTools> groups,
  _ToolsWorkspaceHooks hooks,
) {
  final visibleTargets = _visibleToolsDeleteTargets(groups, hooks);
  final selectedKeys = hooks.selectedKeys.value;

  return (
    visibleTargets: visibleTargets,
    selectedTargets: _selectedToolsDeleteTargets(groups, selectedKeys),
    allVisibleSelected: _allToolsTargetsSelected(visibleTargets, selectedKeys),
  );
}

List<_ToolsDeleteTarget> _visibleToolsDeleteTargets(
  List<ToolsGroupWithTools> groups,
  _ToolsWorkspaceHooks hooks,
) => _toolsDeleteTargets(
  _sortWorkspaceGroups(
    _filterWorkspaceGroups(groups, hooks.searchQuery.value),
    hooks.sort.value,
  ),
);

List<_ToolsDeleteTarget> _selectedToolsDeleteTargets(
  List<ToolsGroupWithTools> groups,
  Set<String> selectedKeys,
) =>
    _toolsDeleteTargets(_filterWorkspaceGroups(groups, ''))
        .where((target) => selectedKeys.contains(target.key))
        .toList();

bool _allToolsTargetsSelected(
  List<_ToolsDeleteTarget> targets,
  Set<String> selectedKeys,
) {
  return targets.isNotEmpty &&
      targets.every((target) => selectedKeys.contains(target.key));
}

_ToolsSelectionData _toolsSelectionData(
  _ToolsWorkspaceHooks hooks,
  _ToolsSelectionSnapshot snapshot,
) => (
  selectedKeys: hooks.selectedKeys.value,
  selectedCount: snapshot.selectedTargets.length,
  selectableCount: snapshot.visibleTargets.length,
  allVisibleSelected: snapshot.allVisibleSelected,
  isDeleting: hooks.isDeleting.value,
);

typedef _ToolsSelectionActionsRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  _ToolsWorkspaceHooks hooks,
  _ToolsSelectionSnapshot snapshot,
});

_ToolsSelectionCallbacks _toolsSelectionActions(
  _ToolsSelectionActionsRequest request,
) => (
  onSelectAll: _toolsSelectAllCallback(request),
  onClear: _toolsClearSelectionCallback(request),
  onDelete: _toolsDeleteSelectedCallback(request),
  onSelectionChanged: _toolsSelectionChangedCallback(request),
);

VoidCallback _toolsSelectAllCallback(_ToolsSelectionActionsRequest request) =>
    () => _toggleAllVisibleTools(
      request.hooks.selectedKeys,
      request.snapshot.visibleTargets,
      request.snapshot.allVisibleSelected,
    );

VoidCallback _toolsClearSelectionCallback(
  _ToolsSelectionActionsRequest request,
) =>
    () => request.hooks.selectedKeys.value = <String>{};

VoidCallback _toolsDeleteSelectedCallback(
  _ToolsSelectionActionsRequest request,
) =>
    () => unawaited(
      _confirmDeleteSelectedTools(_toolsBulkDeleteRequest(request)),
    );

_ToolsBulkDeleteRequest _toolsBulkDeleteRequest(
  _ToolsSelectionActionsRequest request,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  selectedTargets: request.snapshot.selectedTargets,
  selectedKeys: request.hooks.selectedKeys,
  isDeleting: request.hooks.isDeleting,
);

_ToolSelectionChanged _toolsSelectionChangedCallback(
  _ToolsSelectionActionsRequest request,
) =>
    (key, change) => _setToolTargetSelected(
      request.hooks.selectedKeys,
      key,
      change.isSelected,
    );

class const _ToolsWorkspaceListState({
  required final _ToolsWorkspaceViewState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ToolsListControls(state: state),
      _OptionalToolsSelectionActions(state: state),
      Expanded(child: _ToolsListResult(state: state)),
    ],
  );
}

class const _ToolsListControls({required final _ToolsWorkspaceViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ToolsSearchInput(onChanged: state.filter.onSearchChanged),
      _ToolsManagementRow(
        filter: state.filter,
        selection: state.selection,
        actions: state.actions,
      ),
    ],
  );
}

class const _OptionalToolsSelectionActions({
  required final _ToolsWorkspaceViewState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selection = state.selection;
    final actions = state.actions;
    if (selection.selectedCount == 0) return const SizedBox.shrink();

    return _ToolsSelectionActions(
      count: selection.selectedCount,
      isDeleting: selection.isDeleting,
      onDelete: actions.onDelete,
      onClear: actions.onClear,
    );
  }
}

class const _ToolsListResult({required final _ToolsWorkspaceViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state.groupedToolsAsync) {
    AsyncLoading() => const _ToolsLoading(),
    AsyncData(value: final groups) => _ToolsGroupListOrEmpty(
      groups: groups,
      state: state,
    ),
    AsyncError(:final error, :final stackTrace) => _ToolsError(
      error: error,
      stackTrace: stackTrace,
    ),
  };
}

class const _ToolsManagementRow({
  required final _ToolsFilterState filter,
  required final _ToolsSelectionData selection,
  required final _ToolsSelectionCallbacks actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.sm);

    return Padding(
      padding: EdgeInsets.only(left: spacing, top: spacing, right: spacing),
      child: _ToolsManagementControls(
        filter: filter,
        selection: selection,
        onSelectAll: actions.onSelectAll,
        spacing: spacing,
      ),
    );
  }
}

class const _ToolsManagementControls({
  required final _ToolsFilterState filter,
  required final _ToolsSelectionData selection,
  required final VoidCallback onSelectAll,
  required final double spacing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ToolsSortSelector(
          filter: filter,
          isDeleting: selection.isDeleting,
        ),
      ),
      SizedBox(width: spacing),
      _ToolsSelectAllButton(selection: selection, onPressed: onSelectAll),
    ],
  );
}

class const _ToolsSortSelector({
  required final _ToolsFilterState filter,
  required final bool isDeleting,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<_ToolsSort>(
    options: _toolsSortOptions,
    key: const ValueKey('tools-sort'),
    value: filter.sort,
    onChanged: _toolsSortChanged(filter),
    label: const TextLocale(LocaleKeys.common_sort_by),
    isEnabled: !isDeleting,
    semanticLabel: LocaleKeys.common_sort_by.tr(context: context),
  );
}

ValueChanged<_ToolsSort?> _toolsSortChanged(_ToolsFilterState filter) =>
    (value) {
      if (value != null) filter.onSortChanged(value);
    };

class const _ToolsSelectAllButton({
  required final _ToolsSelectionData selection,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: TextLocale(
      selection.allVisibleSelected
          ? LocaleKeys.common_deselect_all
          : LocaleKeys.common_select_all,
    ),
    key: const ValueKey('tools-select-all'),
    size: .small,
    disabled: selection.selectableCount == 0 || selection.isDeleting,
  );
}

const _toolsSortOptions = <AuraDropdownOption<_ToolsSort>>[
  AuraDropdownOption(
    value: _ToolsSort.name,
    child: TextLocale(LocaleKeys.common_sort_name_ascending),
  ),
  AuraDropdownOption(
    value: _ToolsSort.enabled,
    child: TextLocale(LocaleKeys.common_sort_enabled_first),
  ),
];

class const _ToolsSelectionActions({
  required final int count,
  required final bool isDeleting,
  required final VoidCallback onDelete,
  required final VoidCallback onClear,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.sm);

    return Padding(
      padding: EdgeInsets.only(left: spacing, top: spacing, right: spacing),
      child: _ToolsSelectionActionRow(
        count: count,
        isDeleting: isDeleting,
        onDelete: onDelete,
        onClear: onClear,
        spacing: spacing,
      ),
    );
  }
}

class const _ToolsSelectionActionRow({
  required final int count,
  required final bool isDeleting,
  required final VoidCallback onDelete,
  required final VoidCallback onClear,
  required final double spacing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _ToolsSelectedCount(count: count)),
      _ToolsDeleteSelectedButton(isDeleting: isDeleting, onPressed: onDelete),
      SizedBox(width: spacing),
      _ToolsClearSelectionButton(isDeleting: isDeleting, onPressed: onClear),
    ],
  );
}

class const _ToolsSelectedCount({required final int count})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(context.plural(LocaleKeys.common_selected_count, count)),
    style: .bodySmall,
  );
}

class const _ToolsDeleteSelectedButton({
  required final bool isDeleting,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.common_delete_selected),
    key: const ValueKey('tools-delete-selected'),
    size: .small,
    isLoading: isDeleting,
  );
}

class const _ToolsClearSelectionButton({
  required final bool isDeleting,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.close,
    onPressed: isDeleting ? null : onPressed,
    size: .small,
    tooltip: LocaleKeys.common_clear_selection.tr(context: context),
  );
}

class const _ToolsLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(child: AuraSpinner());
}

class const _ToolsGroupListOrEmpty({
  required final List<ToolsGroupWithTools> groups,
  required final _ToolsWorkspaceViewState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty && state.filter.searchQuery.trim().isEmpty) {
      return ToolsEmptyState(
        padding: EdgeInsets.all(context.auraTheme.fromSpacing(.xl)),
      );
    }

    return _FilteredToolsGroupList(
      groups: _visibleWorkspaceGroups(groups, state.filter),
      state: state,
    );
  }
}

List<_WorkspaceToolsGroupResult> _visibleWorkspaceGroups(
  List<ToolsGroupWithTools> groups,
  _ToolsFilterState filter,
) => _sortWorkspaceGroups(
  _filterWorkspaceGroups(groups, filter.searchQuery),
  filter.sort,
);

class const _FilteredToolsGroupList({
  required final List<_WorkspaceToolsGroupResult> groups,
  required final _ToolsWorkspaceViewState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const ToolsSearchEmptyState();

    return _ToolsGroupList(
      groups: groups,
      workspaceId: state.workspaceId,
      selectedKeys: state.selection.selectedKeys,
      isDeleting: state.selection.isDeleting,
      onSelectionChanged: state.actions.onSelectionChanged,
    );
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
  required final Set<String> selectedKeys,
  required final bool isDeleting,
  required final void Function(String key, ({bool isSelected}) change)
  onSelectionChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.sm),
      ),
      itemBuilder: _itemBuilder,
      findChildIndexCallback: _findChildIndex,
      itemCount: groups.length,
    );
  }

  int? _findChildIndex(Key key) {
    for (var index = 0; index < groups.length; index++) {
      if (key == _toolsGroupKey(groups[index].group)) return index;
    }

    return null;
  }

  Widget _itemBuilder(BuildContext _, int index) {
    final result = groups[index];

    return ToolsGroupCard(
      groupWithTools: result.group,
      workspaceId: workspaceId,
      selectedTargetKeys: selectedKeys,
      isDeleting: isDeleting,
      onSelectionChanged: onSelectionChanged,
      visibleTools: result.tools,
      key: _toolsGroupKey(result.group),
    );
  }
}

Key _toolsGroupKey(ToolsGroupWithTools group) =>
    ValueKey('tools-group-${_workspaceGroupId(group)}');

typedef _WorkspaceToolsGroupResult = ({
  ToolsGroupWithTools group,
  List<WorkspaceToolEntity> tools,
});

List<_WorkspaceToolsGroupResult> _sortWorkspaceGroups(
  List<_WorkspaceToolsGroupResult> groups,
  _ToolsSort sort,
) => groups.map((result) => _sortWorkspaceGroupTools(result, sort)).toList()
  ..sort((left, right) => _compareToolGroups(left.group, right.group, sort));

_WorkspaceToolsGroupResult _sortWorkspaceGroupTools(
  _WorkspaceToolsGroupResult result,
  _ToolsSort sort,
) => (
  group: result.group,
  tools: List<WorkspaceToolEntity>.of(result.tools)
    ..sort((left, right) => _compareTools(left, right, sort)),
);

int _compareToolGroups(
  ToolsGroupWithTools left,
  ToolsGroupWithTools right,
  _ToolsSort sort,
) {
  if (sort == _ToolsSort.enabled && left.isEnabled != right.isEnabled) {
    return left.isEnabled ? -1 : 1;
  }
  final nameComparison = _workspaceGroupDisplayName(left)
      .toLowerCase()
      .compareTo(_workspaceGroupDisplayName(right).toLowerCase());
  if (nameComparison != 0) return nameComparison;

  return _workspaceGroupId(left).compareTo(_workspaceGroupId(right));
}

int _compareTools(
  WorkspaceToolEntity left,
  WorkspaceToolEntity right,
  _ToolsSort sort,
) {
  if (sort == _ToolsSort.enabled && left.isEnabled != right.isEnabled) {
    return left.isEnabled ? -1 : 1;
  }
  final nameComparison = _workspaceToolDisplayName(left)
      .toLowerCase()
      .compareTo(_workspaceToolDisplayName(right).toLowerCase());
  if (nameComparison != 0) return nameComparison;

  return left.id.compareTo(right.id);
}

String _workspaceGroupDisplayName(ToolsGroupWithTools group) =>
    group.localizedDisplayNameKey?.tr() ?? group.group?.name ?? '';

String _workspaceGroupId(ToolsGroupWithTools group) =>
    group.group?.id ?? 'default:${group.defaultGroupType?.name ?? 'builtIn'}';

String _workspaceToolDisplayName(WorkspaceToolEntity tool) =>
    tool.toolId.toHumanReadable();

List<_ToolsDeleteTarget> _toolsDeleteTargets(
  List<_WorkspaceToolsGroupResult> groups,
) => groups.expand(_toolsDeleteTargetsForGroup).toList();

Iterable<_ToolsDeleteTarget> _toolsDeleteTargetsForGroup(
  _WorkspaceToolsGroupResult result,
) sync* {
  final group = result.group;
  final entity = group.group;
  if (group.isMcpGroup && entity != null) {
    yield _toolsGroupDeleteTarget(group, entity.id);

    return;
  }

  yield* result.tools.where((tool) => !tool.isNative).map(_toolDeleteTarget);
}

_ToolsDeleteTarget _toolsGroupDeleteTarget(
  ToolsGroupWithTools group,
  String id,
) => (
  kind: _ToolsDeleteTargetKind.group,
  id: id,
  key: 'group:$id',
  label: _workspaceGroupDisplayName(group),
);

_ToolsDeleteTarget _toolDeleteTarget(WorkspaceToolEntity tool) => (
  kind: _ToolsDeleteTargetKind.tool,
  id: tool.id,
  key: 'tool:${tool.id}',
  label: _workspaceToolDisplayName(tool),
);

void _setToolTargetSelected(
  ValueNotifier<Set<String>> selectedKeys,
  String key,
  bool isSelected,
) {
  final next = Set<String>.of(selectedKeys.value);
  final _ = isSelected ? next.add(key) : next.remove(key);
  selectedKeys.value = next;
}

void _toggleAllVisibleTools(
  ValueNotifier<Set<String>> selectedKeys,
  List<_ToolsDeleteTarget> visibleTargets,
  bool allVisibleSelected,
) {
  final next = Set<String>.of(selectedKeys.value);
  final visibleKeys = visibleTargets.map((target) => target.key);
  if (allVisibleSelected) {
    next.removeAll(visibleKeys);
  } else {
    next.addAll(visibleKeys);
  }
  selectedKeys.value = next;
}

typedef _ToolsBulkDeleteRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  List<_ToolsDeleteTarget> selectedTargets,
  ValueNotifier<Set<String>> selectedKeys,
  ValueNotifier<bool> isDeleting,
});

Future<void> _confirmDeleteSelectedTools(
  _ToolsBulkDeleteRequest request,
) async {
  if (request.selectedTargets.isEmpty || request.isDeleting.value) return;
  final confirmed = await _confirmToolsBulkDelete(request.context);
  if (confirmed != true || !request.context.mounted) return;

  await _runToolsBulkDelete(request);
}

Future<bool?> _confirmToolsBulkDelete(BuildContext context) =>
    AuraDialogs.confirm(
      context: context,
      title: const TextLocale(LocaleKeys.tools_screen_bulk_delete_title),
      message: const TextLocale(LocaleKeys.tools_screen_bulk_delete_confirm),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.common_delete),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
      isDestructive: true,
    );

Future<void> _runToolsBulkDelete(_ToolsBulkDeleteRequest request) async {
  request.isDeleting.value = true;
  final failed = await _deleteSelectedTools(
    request.ref,
    request.workspaceId,
    request.selectedTargets,
  );
  if (!request.context.mounted) return;

  _applyToolsBulkDeleteResult(request, failed);
}

void _applyToolsBulkDeleteResult(
  _ToolsBulkDeleteRequest request,
  List<_ToolsDeleteTarget> failed,
) {
  request.isDeleting.value = false;
  request.selectedKeys.value = failed.map((target) => target.key).toSet();
  if (failed.isEmpty) return;

  _showToolsDeleteFailures(request.context, failed);
}

void _showToolsDeleteFailures(
  BuildContext context,
  List<_ToolsDeleteTarget> failed,
) {
  final _ = AuraSnackBars.show(
    context: context,
    content: Text(
      LocaleKeys.tools_screen_bulk_delete_failures.tr(
        args: [failed.map((target) => target.label).join(', ')],
      ),
    ),
    variant: .error,
  );
}

Future<List<_ToolsDeleteTarget>> _deleteSelectedTools(
  WidgetRef ref,
  String workspaceId,
  List<_ToolsDeleteTarget> targets,
) async {
  final runtime = _toolsDeleteRuntime(ref, workspaceId);
  final failed = await _deleteToolsTargets(
    runtime,
    _orderedToolsDeleteTargets(targets),
  );
  _invalidateToolsProviders(ref, workspaceId);

  return failed;
}

_ToolsDeleteRuntime _toolsDeleteRuntime(WidgetRef ref, String workspaceId) => (
  groupedTools: ref.read(groupedToolsProvider(workspaceId).notifier),
  workspaceTools: ref.read(workspaceToolsProvider(workspaceId).notifier),
);

List<_ToolsDeleteTarget> _orderedToolsDeleteTargets(
  List<_ToolsDeleteTarget> targets,
) => [
  ...targets.where((target) => target.kind == _ToolsDeleteTargetKind.group),
  ...targets.where((target) => target.kind == _ToolsDeleteTargetKind.tool),
];

Future<List<_ToolsDeleteTarget>> _deleteToolsTargets(
  _ToolsDeleteRuntime runtime,
  List<_ToolsDeleteTarget> targets,
) async {
  final failed = <_ToolsDeleteTarget>[];
  for (final target in targets) {
    if (!await _deleteToolsTarget(runtime, target)) failed.add(target);
  }

  return failed;
}

void _invalidateToolsProviders(WidgetRef ref, String workspaceId) {
  ref
    ..invalidate(groupedToolsProvider(workspaceId))
    ..invalidate(workspaceToolsProvider(workspaceId));
}

typedef _ToolsDeleteRuntime = ({
  GroupedToolsNotifier groupedTools,
  WorkspaceToolsNotifier workspaceTools,
});

Future<bool> _deleteToolsTarget(
  _ToolsDeleteRuntime runtime,
  _ToolsDeleteTarget target,
) async {
  try {
    return switch (target.kind) {
      .group => await runtime.groupedTools.deleteMcpGroup(
        target.id,
        invalidate: false,
      ),
      .tool => await runtime.workspaceTools.removeToolById(target.id),
    };
  } on Object catch (error, stackTrace) {
    _logger.warning(
      'Failed to remove ${target.kind.name} ${target.id}',
      error,
      stackTrace,
    );

    return false;
  }
}

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
