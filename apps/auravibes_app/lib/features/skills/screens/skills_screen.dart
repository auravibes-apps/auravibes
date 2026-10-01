// Required: Existing UI spacing uses small numeric values.
// Required: Local builders keep this small screen readable.
// Required: Feature widgets keep closely related private widgets together.

import 'dart:async';
import 'dart:math' as math;

import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/agents/widgets/agents_skills_tabs.dart';
import 'package:auravibes_app/features/skills/models/skill_sort.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/notifiers/skills_list_view_notifier.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/skills/usecases/disable_skill_usecase.dart';
import 'package:auravibes_app/features/skills/widgets/skill_access_status_view.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/management_list_feedback.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

const _skillScreenIconSize = 48.0;
const _skillScreenListPadding = 8.0;
const _skillScreenRunSpacing = 4.0;
const _skillScreenSpacing = 8.0;
const _skillDescriptionMaxLines = 2;
const _searchEmptyTokenLength = 0;
const _searchSingleCharacterTokenLength = 1;
const _searchShortTokenLength = 2;
const _searchMediumTokenMinLength = 3;
const _searchMediumTokenMaxLength = 4;
const _searchNoEditDistance = 0;
const _searchSingleEditDistance = 1;
const _searchMultipleEditDistance = 2;

final _logger = Logger('skills_screen');

typedef _DeleteSkills = Future<List<WorkspaceSkill>> Function(
  List<WorkspaceSkill> skills,
);

typedef _DeleteSkillById = Future<void> Function(String skillId);

typedef _SkillSelectionChanged = void Function(
  WorkspaceSkill skill,
  ({bool isSelected}) change,
);

typedef _SkillEnabledChanged = void Function(
  WorkspaceSkill skill,
  ({bool isEnabled}) change,
);

typedef _SkillsLoadedHooks = ({
  SkillsListViewState view,
  SkillsListViewNotifier notifier,
  ValueNotifier<Set<String>> selectedIds,
  ValueNotifier<bool> isDeleting,
});

typedef _SkillsFilterData = ({
  String searchQuery,
  List<WorkspaceSkill> skills,
  SkillSource? skillSource,
  bool? enabled,
  SkillSort sort,
});

typedef _SkillsSelectionData = ({
  Set<String> selectedIds,
  int selectedCount,
  int hiddenSelectedCount,
  int selectableCount,
  bool allVisibleSelected,
  bool isDeleting,
});

typedef _SkillsViewData = ({
  String workspaceId,
  _SkillsFilterData filter,
  _SkillsSelectionData selection,
});

typedef _SkillsFilterActions = ({
  ValueChanged<String> onSearchChanged,
  ValueChanged<SkillSource?> onSourceChanged,
  ValueChanged<bool?> onEnabledChanged,
  ValueChanged<SkillSort> onSortChanged,
});

typedef _SkillsBulkActions = ({
  VoidCallback onSelectAll,
  VoidCallback onClearSelection,
  VoidCallback onDeleteSelected,
  _SkillSelectionChanged onSelectionChanged,
});

typedef _SkillsItemActions = ({
  ValueChanged<WorkspaceSkill> onOpenSkill,
  ValueChanged<WorkspaceSkill> onDeleteSkill,
  _SkillEnabledChanged onSkillEnabledChanged,
});

typedef _SkillsViewActions = ({
  _SkillsFilterActions filter,
  _SkillsBulkActions bulk,
  _SkillsItemActions items,
});

typedef _SkillsViewState = ({_SkillsViewData data, _SkillsViewActions actions});

class const SkillsScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _SkillsScreenScaffold(workspaceId: workspaceId);
}

class const _SkillsScreenScaffold({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(workspaceSkillsProvider(workspaceId));

    return _SkillsScreenScaffoldView(
      workspaceId: workspaceId,
      skillsAsync: skillsAsync,
      onCreateSkill: _openCreateSkill,
      onOpenSkill: _openSkill,
      onDeleteSkill: _confirmDeleteSkill,
      onDeleteSkills: (skills) => _deleteSkills(ref, skills),
      onSkillEnabledChanged: _setSkillEnabled,
    );
  }
}

extension on _SkillsScreenScaffold {
  Future<void> _openCreateSkill(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await context.push<bool>(
      '/workspaces/$workspaceId/more/skills/new',
    );
    if (result == true) {
      _scheduleWorkspaceSkillsRefresh(container);
    }
  }

  Future<void> _openSkill(BuildContext context, String skillId) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await context.push<bool>(
      '/workspaces/$workspaceId/more/skills/$skillId',
    );
    if (result == true) {
      _scheduleWorkspaceSkillsRefresh(container);
    }
  }

  void _scheduleWorkspaceSkillsRefresh(ProviderContainer container) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshWorkspaceSkillsAfterFrame(container));
    });
  }

  Future<void> _refreshWorkspaceSkillsAfterFrame(
    ProviderContainer container,
  ) async {
    await container.pump();
    container.invalidate(workspaceSkillsProvider(workspaceId));
  }

  Future<void> _setSkillEnabled(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  ) async {
    final usecase = ref.read(disableSkillUsecaseProvider(workspaceId));
    await usecase.call(_disableSkillRequest(workspaceId, skill, change));
    ref.invalidate(workspaceSkillsProvider(workspaceId));
  }

  Future<void> _confirmDeleteSkill(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  ) async {
    if (skill.source != SkillSource.user) return;
    final shouldDelete = await _showDeleteConfirmation(context);
    if (shouldDelete != true) return;

    await _deleteSkill(ref, skill);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    return showDialog<bool>(
      context: context,
      builder: (_) => _DeleteSkillDialog(),
    );
  }

  Future<void> _deleteSkill(WidgetRef ref, WorkspaceSkill skill) async {
    await ref.read(deleteSkillProvider(workspaceId))(skill.id);
    ref.invalidate(workspaceSkillsProvider(workspaceId));
  }

  Future<List<WorkspaceSkill>> _deleteSkills(
    WidgetRef ref,
    List<WorkspaceSkill> skills,
  ) async {
    final deleteSkill = ref.read(deleteSkillProvider(workspaceId));
    final failed = await _deleteSkillTargets(deleteSkill, skills);
    ref.invalidate(workspaceSkillsProvider(workspaceId));

    return failed;
  }
}

Future<List<WorkspaceSkill>> _deleteSkillTargets(
  _DeleteSkillById deleteSkill,
  List<WorkspaceSkill> skills,
) async {
  final failed = <WorkspaceSkill>[];
  for (final skill in skills.where(_isUserSkill)) {
    if (!await _deleteSkillTarget(deleteSkill, skill)) failed.add(skill);
  }

  return failed;
}

bool _isUserSkill(WorkspaceSkill skill) => skill.source == SkillSource.user;

Future<bool> _deleteSkillTarget(
  _DeleteSkillById deleteSkill,
  WorkspaceSkill skill,
) async {
  try {
    await deleteSkill(skill.id);

    return true;
  } on Object catch (error, stackTrace) {
    _logger.warning('Failed to delete skill ${skill.id}', error, stackTrace);

    return false;
  }
}

DisableSkillRequest _disableSkillRequest(
  String workspaceId,
  WorkspaceSkill skill,
  ({bool isEnabled}) change,
) => (
  workspaceId: workspaceId,
  source: skill.source,
  kind: skill.kind,
  skillId: skill.id,
  isEnabled: change.isEnabled,
  slug: skill.slug,
  title: skill.title,
  description: skill.description,
  content: null,
);

class const _SkillsScreenScaffoldView({
  required final String workspaceId,
  required final AsyncValue<List<WorkspaceSkill>> skillsAsync,
  required final Future<void> Function(BuildContext context) onCreateSkill,
  required final Future<void> Function(BuildContext context, String skillId)
  onOpenSkill,
  required final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  )
  onDeleteSkill,
  required final _DeleteSkills onDeleteSkills,
  required final Future<void> Function(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  )
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _SkillsScreenBody(
        workspaceId: workspaceId,
        skillsAsync: skillsAsync,
        onCreateSkill: onCreateSkill,
        onOpenSkill: onOpenSkill,
        onDeleteSkill: onDeleteSkill,
        onDeleteSkills: onDeleteSkills,
        onSkillEnabledChanged: onSkillEnabledChanged,
      ),
      appBar: _SkillsScreenAppBar(
        workspaceId: workspaceId,
        onCreateSkill: () => onCreateSkill(context),
      ),
    );
  }
}

class const _SkillsScreenAppBar({
  required final String workspaceId,
  required final VoidCallback onCreateSkill,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 2);

  @override
  Widget build(BuildContext context) => _SkillsScreenAppBarData(
    workspaceId: workspaceId,
    onCreateSkill: onCreateSkill,
  ).child;
}

class _SkillsScreenAppBarData {
  new({required String workspaceId, required VoidCallback onCreateSkill})
    : child = AuraAppBarWithDrawer(
        title: const TextLocale(LocaleKeys.skills_screen_title),
        actions: [_SkillsScreenCreateButton(onPressed: onCreateSkill)],
        bottom: AgentsSkillsTabs(workspaceId: workspaceId, value: .skills),
      );

  final Widget child;
}

class const _SkillsScreenCreateButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.add,
    onPressed: onPressed,
    tooltip: LocaleKeys.skills_screen_create.tr(context: context),
  );
}

class const _SkillsScreenBody({
  required final String workspaceId,
  required final AsyncValue<List<WorkspaceSkill>> skillsAsync,
  required final Future<void> Function(BuildContext context) onCreateSkill,
  required final Future<void> Function(BuildContext context, String skillId)
  onOpenSkill,
  required final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  )
  onDeleteSkill,
  required final _DeleteSkills onDeleteSkills,
  required final Future<void> Function(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  )
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillsScreenAsyncContent(
    workspaceId: workspaceId,
    skillsAsync: skillsAsync,
    onCreateSkill: () => unawaited(onCreateSkill(context)),
    onOpenSkill: (skill) => onOpenSkill(context, skill.id),
    onDeleteSkill: onDeleteSkill,
    onDeleteSkills: onDeleteSkills,
    onSkillEnabledChanged: onSkillEnabledChanged,
  );
}

class const _SkillsScreenAsyncContent({
  required final String workspaceId,
  required final AsyncValue<List<WorkspaceSkill>> skillsAsync,
  required final VoidCallback onCreateSkill,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  )
  onDeleteSkill,
  required final _DeleteSkills onDeleteSkills,
  required final Future<void> Function(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  )
  onSkillEnabledChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _SkillsScreenAsyncContentData(
        workspaceId: workspaceId,
        skillsAsync: skillsAsync,
        onCreateSkill: onCreateSkill,
        onOpenSkill: onOpenSkill,
        onDeleteSkill: (skill) => onDeleteSkill(context, ref, skill),
        onDeleteSkills: onDeleteSkills,
        onSkillEnabledChanged: (skill, value) =>
            onSkillEnabledChanged(ref, skill, value),
      ).child;
}

class _SkillsScreenAsyncContentData {
  new({
    required String workspaceId,
    required AsyncValue<List<WorkspaceSkill>> skillsAsync,
    required VoidCallback onCreateSkill,
    required ValueChanged<WorkspaceSkill> onOpenSkill,
    required ValueChanged<WorkspaceSkill> onDeleteSkill,
    required _DeleteSkills onDeleteSkills,
    required void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
    onSkillEnabledChanged,
  }) : child = switch (_loadedSkills(skillsAsync)) {
         null => _SkillsScreenPendingState(skillsAsync: skillsAsync),
         final skills => _SkillsScreenLoadedContent(
           workspaceId: workspaceId,
           skills: skills,
           onCreateSkill: onCreateSkill,
           onOpenSkill: onOpenSkill,
           onDeleteSkill: onDeleteSkill,
           onDeleteSkills: onDeleteSkills,
           onSkillEnabledChanged: onSkillEnabledChanged,
         ),
       };

  final Widget child;
}

List<WorkspaceSkill>? _loadedSkills(
  AsyncValue<List<WorkspaceSkill>> skillsAsync,
) => switch (skillsAsync) {
  AsyncData(:final value) => value,
  AsyncLoading(value: final value, hasValue: true) => value,
  AsyncLoading() => null,
  AsyncError() => null,
};

class const _SkillsScreenPendingState({
  required final AsyncValue<List<WorkspaceSkill>> skillsAsync,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (skillsAsync) {
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncError(:final error) => _SkillsScreenError(error: error),
    AsyncData() => const SizedBox.shrink(),
  };
}

class const _SkillsScreenError({required final Object error})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: AuraText(child: TextLocale(CloudAppErrors.localizationKey(error))),
  );
}

class const _SkillsScreenLoadedContent({
  required final String workspaceId,
  required final List<WorkspaceSkill> skills,
  required final VoidCallback onCreateSkill,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final _DeleteSkills onDeleteSkills,
  required final void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
  onSkillEnabledChanged,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _useSkillsViewState(context, this, ref);

    if (skills.isEmpty) {
      return _SkillsScreenEmpty(onCreateSkill: onCreateSkill);
    }

    return _SkillsScreenLoadedView(state: state);
  }
}

_SkillsViewState _useSkillsViewState(
  BuildContext context,
  _SkillsScreenLoadedContent content,
  WidgetRef ref,
) {
  final hooks = _useSkillsLoadedHooks(ref, content.workspaceId);
  final runtime = _skillsViewRuntime(context, content.skills, hooks);
  final request = (
    context: context,
    content: content,
    hooks: hooks,
    runtime: runtime,
  );

  return (
    data: _skillsViewData(hooks, runtime, content.workspaceId),
    actions: _skillsViewActions(request),
  );
}

_SkillsLoadedHooks _useSkillsLoadedHooks(WidgetRef ref, String workspaceId) => (
  view: ref.watch(skillsListViewProvider(workspaceId)),
  notifier: ref.read(skillsListViewProvider(workspaceId).notifier),
  selectedIds: useState(<String>{}),
  isDeleting: useState(false),
);

typedef _SkillsViewRuntime = ({
  List<WorkspaceSkill> visibleSkills,
  List<WorkspaceSkill> visibleUserSkills,
  List<WorkspaceSkill> selectedSkills,
  int hiddenSelectedCount,
  bool allVisibleSelected,
});

_SkillsViewRuntime _skillsViewRuntime(
  BuildContext context,
  List<WorkspaceSkill> skills,
  _SkillsLoadedHooks hooks,
) {
  final visibleSkills = _visibleSkills(context, skills, hooks);
  final visibleUserSkills = _userSkills(visibleSkills);
  final selectedSkills = _selectedUserSkills(skills, hooks.selectedIds.value);

  return (
    visibleSkills: visibleSkills,
    visibleUserSkills: visibleUserSkills,
    selectedSkills: selectedSkills,
    hiddenSelectedCount: _hiddenSelectedSkillCount(
      selectedSkills,
      visibleUserSkills,
      hooks.selectedIds.value,
    ),
    allVisibleSelected: _allVisibleSkillsSelected(
      visibleUserSkills,
      hooks.selectedIds.value,
    ),
  );
}

int _hiddenSelectedSkillCount(
  List<WorkspaceSkill> selectedSkills,
  List<WorkspaceSkill> skills,
  Set<String> selectedIds,
) =>
    selectedSkills.length -
    skills.where((skill) => selectedIds.contains(skill.id)).length;

List<WorkspaceSkill> _visibleSkills(
  BuildContext context,
  List<WorkspaceSkill> skills,
  _SkillsLoadedHooks hooks,
) => _sortSkills(
  context,
  _filterSkills(context, skills, _loadedSkillFiltersFromHooks(hooks)),
  hooks.view.sort,
);

List<WorkspaceSkill> _userSkills(List<WorkspaceSkill> skills) =>
    skills.where((skill) => skill.source == SkillSource.user).toList();

List<WorkspaceSkill> _selectedUserSkills(
  List<WorkspaceSkill> skills,
  Set<String> selectedIds,
) => skills
    .where(
      (skill) =>
          skill.source == SkillSource.user && selectedIds.contains(skill.id),
    )
    .toList();

bool _allVisibleSkillsSelected(
  List<WorkspaceSkill> skills,
  Set<String> selectedIds,
) =>
    skills.isNotEmpty &&
    skills.every((skill) => selectedIds.contains(skill.id));

_SkillsViewData _skillsViewData(
  _SkillsLoadedHooks hooks,
  _SkillsViewRuntime runtime,
  String workspaceId,
) => (
  workspaceId: workspaceId,
  filter: _skillsFilterData(hooks, runtime),
  selection: _skillsSelectionData(hooks, runtime),
);

_SkillsFilterData _skillsFilterData(
  _SkillsLoadedHooks hooks,
  _SkillsViewRuntime runtime,
) {
  final view = hooks.view;

  return (
    skills: runtime.visibleSkills,
    searchQuery: view.searchQuery,
    skillSource: view.sourceFilter,
    enabled: view.enabledFilter,
    sort: view.sort,
  );
}

_SkillsSelectionData _skillsSelectionData(
  _SkillsLoadedHooks hooks,
  _SkillsViewRuntime runtime,
) => (
  selectedIds: hooks.selectedIds.value,
  selectedCount: runtime.selectedSkills.length,
  hiddenSelectedCount: runtime.hiddenSelectedCount,
  selectableCount: runtime.visibleUserSkills.length,
  allVisibleSelected: runtime.allVisibleSelected,
  isDeleting: hooks.isDeleting.value,
);

typedef _SkillsViewRequest = ({
  BuildContext context,
  _SkillsScreenLoadedContent content,
  _SkillsLoadedHooks hooks,
  _SkillsViewRuntime runtime,
});

_SkillsViewActions _skillsViewActions(_SkillsViewRequest request) {
  final content = request.content;

  return (
    filter: _skillsFilterActions(request.hooks),
    bulk: _skillsBulkActions(request),
    items: (
      onOpenSkill: content.onOpenSkill,
      onDeleteSkill: content.onDeleteSkill,
      onSkillEnabledChanged: content.onSkillEnabledChanged,
    ),
  );
}

_SkillsFilterActions _skillsFilterActions(_SkillsLoadedHooks hooks) {
  final notifier = hooks.notifier;

  return (
    onSearchChanged: notifier.setSearchQuery,
    onSourceChanged: notifier.setSourceFilter,
    onEnabledChanged: (value) => notifier.setEnabledFilter(value: value),
    onSortChanged: notifier.setSort,
  );
}

_SkillsBulkActions _skillsBulkActions(_SkillsViewRequest request) => (
  onSelectAll: _skillsSelectAllCallback(request),
  onClearSelection: _clearSkillSelectionCallback(request.hooks.selectedIds),
  onDeleteSelected: _skillsDeleteSelectedCallback(request),
  onSelectionChanged: _skillSelectionCallback(request.hooks.selectedIds),
);

VoidCallback _clearSkillSelectionCallback(
  ValueNotifier<Set<String>> selectedIds,
) =>
    () => selectedIds.value = <String>{};

_SkillSelectionChanged _skillSelectionCallback(
  ValueNotifier<Set<String>> selectedIds,
) =>
    (skill, change) =>
        _setSkillSelected(selectedIds, skill.id, change.isSelected);

VoidCallback _skillsSelectAllCallback(_SkillsViewRequest request) =>
    () => _toggleAllVisibleSkills(
      request.hooks.selectedIds,
      request.runtime.visibleUserSkills,
      request.runtime.allVisibleSelected,
    );

VoidCallback _skillsDeleteSelectedCallback(_SkillsViewRequest request) {
  final bulkDelete = (
    context: request.context,
    selectedSkills: request.runtime.selectedSkills,
    hiddenSelectedCount: request.runtime.hiddenSelectedCount,
    selectedIds: request.hooks.selectedIds,
    isDeleting: request.hooks.isDeleting,
    onDeleteSkills: request.content.onDeleteSkills,
  );

  return () => unawaited(_confirmDeleteSelectedSkills(bulkDelete));
}

_SkillsFilterState _loadedSkillFiltersFromHooks(_SkillsLoadedHooks hooks) {
  final view = hooks.view;

  return (
    queryTokens: _searchTokens(view.searchQuery),
    source: view.sourceFilter,
    enabled: view.enabledFilter,
  );
}

List<WorkspaceSkill> _sortSkills(
  BuildContext context,
  List<WorkspaceSkill> skills,
  SkillSort sort,
) =>
    List<WorkspaceSkill>.of(skills)
      ..sort((left, right) => _compareSkills(context, left, right, sort));

int _compareSkills(
  BuildContext context,
  WorkspaceSkill left,
  WorkspaceSkill right,
  SkillSort sort,
) {
  if (sort == SkillSort.enabled && left.isEnabled != right.isEnabled) {
    return left.isEnabled ? -1 : 1;
  }

  return _compareSkillsByName(context, left, right);
}

int _compareSkillsByName(
  BuildContext context,
  WorkspaceSkill left,
  WorkspaceSkill right,
) {
  final leftTitle = _localizedSkillTitle(context, left);
  final rightTitle = _localizedSkillTitle(context, right);
  final titleComparison = leftTitle.toLowerCase().compareTo(
    rightTitle.toLowerCase(),
  );
  if (titleComparison != 0) return titleComparison;

  return left.id.compareTo(right.id);
}

String _localizedSkillTitle(BuildContext context, WorkspaceSkill skill) =>
    skill.titleKey?.tr(context: context) ?? skill.title;

void _setSkillSelected(
  ValueNotifier<Set<String>> selectedIds,
  String skillId,
  bool isSelected,
) {
  final next = Set<String>.of(selectedIds.value);
  final _ = isSelected ? next.add(skillId) : next.remove(skillId);
  selectedIds.value = next;
}

void _toggleAllVisibleSkills(
  ValueNotifier<Set<String>> selectedIds,
  List<WorkspaceSkill> visibleSkills,
  bool allVisibleSelected,
) {
  final next = Set<String>.of(selectedIds.value);
  final visibleIds = visibleSkills.map((skill) => skill.id);
  if (allVisibleSelected) {
    next.removeAll(visibleIds);
  } else {
    next.addAll(visibleIds);
  }
  selectedIds.value = next;
}

typedef _SkillsBulkDeleteRequest = ({
  BuildContext context,
  List<WorkspaceSkill> selectedSkills,
  int hiddenSelectedCount,
  ValueNotifier<Set<String>> selectedIds,
  ValueNotifier<bool> isDeleting,
  _DeleteSkills onDeleteSkills,
});

Future<void> _confirmDeleteSelectedSkills(
  _SkillsBulkDeleteRequest request,
) async {
  if (request.selectedSkills.isEmpty || request.isDeleting.value) return;
  final shouldDelete = await _confirmSkillsBulkDelete(
    request.context,
    request.selectedSkills.length,
    request.hiddenSelectedCount,
  );
  if (shouldDelete != true || !request.context.mounted) return;

  await _runSkillsBulkDelete(request);
}

Future<bool?> _confirmSkillsBulkDelete(
  BuildContext context,
  int selectedCount,
  int hiddenCount,
) {
  FocusManager.instance.primaryFocus?.unfocus();

  return showDialog<bool>(
    context: context,
    builder: (_) => _BulkDeleteSkillsDialog(
      selectedCount: selectedCount,
      hiddenCount: hiddenCount,
    ),
  );
}

Future<void> _runSkillsBulkDelete(_SkillsBulkDeleteRequest request) async {
  request.isDeleting.value = true;
  final failed = await _deleteSelectedSkills(request);
  if (!request.context.mounted) return;

  request.selectedIds.value = failed.map((skill) => skill.id).toSet();
  if (failed.isEmpty) return;

  _showSkillsDeleteFailures(request.context, failed);
}

Future<List<WorkspaceSkill>> _deleteSelectedSkills(
  _SkillsBulkDeleteRequest request,
) async {
  try {
    return await request.onDeleteSkills(request.selectedSkills);
  } on Object catch (error, stackTrace) {
    _logger.warning('Failed to delete selected skills', error, stackTrace);

    return request.selectedSkills;
  } finally {
    if (request.context.mounted) request.isDeleting.value = false;
  }
}

void _showSkillsDeleteFailures(
  BuildContext context,
  List<WorkspaceSkill> failed,
) {
  final _ = AuraSnackBars.show(
    context: context,
    content: Text(
      ManagementListFeedback.failureText(
        context,
        LocaleKeys.skills_screen_bulk_delete_failures,
        failed.map((skill) => _localizedSkillTitle(context, skill)).toList(),
      ),
    ),
    variant: .error,
  );
}

class const _SkillsScreenLoadedView({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Column(
    children: [
      _SkillsScreenFilters(state: state),
      _OptionalSkillsSelectionActions(state: state),
      Expanded(child: _SkillsScreenFilteredList(state: state)),
    ],
  );
}

class const _OptionalSkillsSelectionActions({
  required final _SkillsViewState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selection = state.data.selection;
    if (selection.selectedCount == 0) return const SizedBox.shrink();

    return _SkillsSelectionActions(
      count: selection.selectedCount,
      hiddenCount: selection.hiddenSelectedCount,
      isDeleting: selection.isDeleting,
      onDelete: state.actions.bulk.onDeleteSelected,
      onClear: state.actions.bulk.onClearSelection,
    );
  }
}

class const _SkillsScreenFilteredList({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => state.data.filter.skills.isEmpty
      ? const _SkillsScreenSearchEmpty()
      : _SkillsList(state: state);
}

class const _SkillsScreenFilters({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.sm);

    return Padding(
      padding: EdgeInsets.only(left: spacing, top: spacing, right: spacing),
      child: _SkillsScreenFilterFields(state: state),
    );
  }
}

class const _SkillsScreenFilterFields({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: _SkillsScreenFilterFieldChildren(state).values,
    spacing: .sm,
  );
}

class _SkillsScreenFilterFieldChildren {
  factory(_SkillsViewState state) {
    final data = state.data.filter;
    final actions = state.actions.filter;

    return _SkillsScreenFilterFieldChildren._([
      _SkillsScreenSearchInput(
        searchQuery: data.searchQuery,
        onChanged: actions.onSearchChanged,
      ),
      _SkillsScreenFilterRow(
        source: data.skillSource,
        enabled: data.enabled,
        onSourceChanged: actions.onSourceChanged,
        onEnabledChanged: actions.onEnabledChanged,
      ),
      _SkillsManagementRow(state: state),
    ]);
  }

  new _(this.values);

  final List<Widget> values;
}

class const _SkillsScreenSearchInput({
  required final String searchQuery,
  required final ValueChanged<String> onChanged,
}) extends HookWidget {
  @override
  Widget build(BuildContext _) => AuraInput(
    controller: useTextEditingController(text: searchQuery),
    placeholder: const TextLocale(LocaleKeys.skills_screen_search_placeholder),
    prefixIcon: const AuraIcon(Icons.search),
    size: .small,
    textInputAction: .search,
    onChanged: onChanged,
  );
}

class const _SkillsScreenFilterRow({
  required final SkillSource? source,
  required final bool? enabled,
  required final ValueChanged<SkillSource?> onSourceChanged,
  required final ValueChanged<bool?> onEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => _SkillsScreenFilterRowData(
    source: source,
    enabled: enabled,
    onSourceChanged: onSourceChanged,
    onEnabledChanged: onEnabledChanged,
  ).child;
}

class _SkillsScreenFilterRowData {
  new({
    required SkillSource? source,
    required bool? enabled,
    required ValueChanged<SkillSource?> onSourceChanged,
    required ValueChanged<bool?> onEnabledChanged,
  }) : child = Row(
         children: [
           Expanded(
             child: _SkillsFilter(
               labelKey: LocaleKeys.skills_screen_filter_source,
               options: _skillSourceFilterOptions,
               value: _sourceFilterValue(source),
               onChanged: (value) =>
                   onSourceChanged(_skillSourceFromFilterValue(value)),
               key: const ValueKey('skills-source-filter'),
             ),
           ),
           const SizedBox(width: _skillScreenSpacing),
           Expanded(
             child: _SkillsFilter(
               labelKey: LocaleKeys.skills_screen_filter_status,
               options: _skillStatusFilterOptions,
               value: _statusFilterValue(enabled),
               onChanged: (value) =>
                   onEnabledChanged(_enabledFromFilterValue(value)),
               key: const ValueKey('skills-status-filter'),
             ),
           ),
         ],
       );

  final Widget child;
}

class const _SkillsManagementRow({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 600
        ? _CompactSkillsManagementRow(state: state)
        : _WideSkillsManagementRow(state: state),
  );
}

class const _CompactSkillsManagementRow({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _SkillsSortSelector(state: state),
      const SizedBox(height: _skillScreenSpacing),
      Align(
        alignment: .centerRight,
        child: _SkillsSelectAllButton(state: state),
      ),
    ],
  );
}

class const _WideSkillsManagementRow({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .end,
    children: [
      Expanded(child: _SkillsSortSelector(state: state)),
      const SizedBox(width: _skillScreenSpacing),
      _SkillsSelectAllButton(state: state),
    ],
  );
}

class const _SkillsSortSelector({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _SkillsSortSelectorData(context: context, state: state).child;
}

class _SkillsSortSelectorData {
  new({required BuildContext context, required _SkillsViewState state})
    : child = AuraDropdownSelector<SkillSort>(
        options: _skillSortOptions,
        key: const ValueKey('skills-sort'),
        value: state.data.filter.sort,
        onChanged: _skillsSortChanged(state.actions.filter),
        label: const TextLocale(LocaleKeys.common_sort_by),
        isEnabled: !state.data.selection.isDeleting,
        semanticLabel: LocaleKeys.common_sort_by.tr(context: context),
      );

  final Widget child;
}

ValueChanged<SkillSort?> _skillsSortChanged(_SkillsFilterActions actions) =>
    (value) {
      if (value != null) actions.onSortChanged(value);
    };

class const _SkillsSelectAllButton({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selection = state.data.selection;

    return AuraButton(
      onPressed: state.actions.bulk.onSelectAll,
      child: TextLocale(
        selection.allVisibleSelected
            ? LocaleKeys.common_deselect_all
            : LocaleKeys.common_select_all,
      ),
      key: const ValueKey('skills-select-all'),
      size: .small,
      disabled: selection.selectableCount == 0 || selection.isDeleting,
    );
  }
}

const _skillSortOptions = <AuraDropdownOption<SkillSort>>[
  AuraDropdownOption(
    value: SkillSort.name,
    child: TextLocale(LocaleKeys.common_sort_name_ascending),
  ),
  AuraDropdownOption(
    value: SkillSort.enabled,
    child: TextLocale(LocaleKeys.common_sort_enabled_first),
  ),
];

class const _SkillsSelectionActions({
  required final int count,
  required final int hiddenCount,
  required final bool isDeleting,
  required final VoidCallback onDelete,
  required final VoidCallback onClear,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.sm);

    return Padding(
      padding: EdgeInsets.only(left: spacing, top: spacing, right: spacing),
      child: _SkillsSelectionActionRow(
        count: count,
        hiddenCount: hiddenCount,
        isDeleting: isDeleting,
        onDelete: onDelete,
        onClear: onClear,
        spacing: spacing,
      ),
    );
  }
}

class const _SkillsSelectionActionRow({
  required final int count,
  required final int hiddenCount,
  required final bool isDeleting,
  required final VoidCallback onDelete,
  required final VoidCallback onClear,
  required final double spacing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _SkillsSelectedCount(count: count, hiddenCount: hiddenCount),
      ),
      _SkillsDeleteSelectedButton(isDeleting: isDeleting, onPressed: onDelete),
      SizedBox(width: spacing),
      _SkillsClearSelectionButton(isDeleting: isDeleting, onPressed: onClear),
    ],
  );
}

class const _SkillsSelectedCount({
  required final int count,
  required final int hiddenCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      ManagementListFeedback.selectionText(
        context,
        selectedCount: count,
        hiddenCount: hiddenCount,
      ),
    ),
    style: .bodySmall,
  );
}

class const _SkillsDeleteSelectedButton({
  required final bool isDeleting,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.common_delete_selected),
    key: const ValueKey('skills-delete-selected'),
    size: .small,
    isLoading: isDeleting,
  );
}

class const _SkillsClearSelectionButton({
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

class const _SkillsFilter({
  required final String labelKey,
  required final List<AuraDropdownOption<String>> options,
  required final String value,
  required final ValueChanged<String?> onChanged,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraDropdownSelector<String>(
    options: options,
    value: value,
    onChanged: onChanged,
    label: TextLocale(labelKey),
  );
}

class const _SkillsScreenSearchEmpty() extends StatelessWidget {
  @override
  Widget build(BuildContext _) => const Center(
    child: AuraColumn(
      children: [
        AuraIcon(Icons.search_off, size: .large),
        AuraText(
          child: TextLocale(LocaleKeys.skills_screen_search_no_results),
          textAlign: .center,
        ),
      ],
      spacing: .sm,
      mainAxisSize: .min,
    ),
  );
}

const _skillSourceFilterOptions = <AuraDropdownOption<String>>[
  AuraDropdownOption(
    value: 'all',
    child: TextLocale(LocaleKeys.skills_screen_filter_all),
  ),
  AuraDropdownOption(
    value: 'app',
    child: TextLocale(LocaleKeys.skills_screen_source_app),
  ),
  AuraDropdownOption(
    value: 'user',
    child: TextLocale(LocaleKeys.skills_screen_source_user),
  ),
];

const _skillStatusFilterOptions = <AuraDropdownOption<String>>[
  AuraDropdownOption(
    value: 'all',
    child: TextLocale(LocaleKeys.skills_screen_filter_all),
  ),
  AuraDropdownOption(
    value: 'enabled',
    child: TextLocale(LocaleKeys.skills_screen_enabled_label),
  ),
  AuraDropdownOption(
    value: 'disabled',
    child: TextLocale(LocaleKeys.skills_screen_disabled_label),
  ),
];

String _sourceFilterValue(SkillSource? source) => source?.name ?? 'all';

SkillSource? _skillSourceFromFilterValue(String? value) => switch (value) {
  'app' => .app,
  'user' => .user,
  _ => null,
};

String _statusFilterValue(bool? enabled) => switch (enabled) {
  null => 'all',
  true => 'enabled',
  false => 'disabled',
};

bool? _enabledFromFilterValue(String? value) => switch (value) {
  'enabled' => true,
  'disabled' => false,
  _ => null,
};

typedef _SkillsFilterState = ({
  List<String> queryTokens,
  SkillSource? source,
  bool? enabled,
});

List<WorkspaceSkill> _filterSkills(
  BuildContext context,
  List<WorkspaceSkill> skills,
  _SkillsFilterState filters,
) => skills
    .where((skill) => _matchesSkillFilters(context, skill, filters))
    .toList();

bool _matchesSkillFilters(
  BuildContext context,
  WorkspaceSkill skill,
  _SkillsFilterState filters,
) {
  if (!_matchesSkillMetadata(skill, filters)) return false;

  return _matchesSkillQuery(context, skill, filters.queryTokens);
}

bool _matchesSkillMetadata(WorkspaceSkill skill, _SkillsFilterState filters) =>
    (filters.source == null || skill.source == filters.source) &&
    (filters.enabled == null || skill.isEnabled == filters.enabled);

bool _matchesSkillQuery(
  BuildContext context,
  WorkspaceSkill skill,
  List<String> queryTokens,
) =>
    queryTokens.isEmpty ||
    queryTokens.every(
      (queryToken) => _skillSearchValues(
        context,
        skill,
      ).any((value) => _matchesSearchToken(queryToken, value)),
    );

bool _matchesSearchToken(String queryToken, String value) {
  final normalizedValue = value.toLowerCase();
  if (normalizedValue.contains(queryToken)) return true;

  return _searchTokens(value).any(
    (valueToken) =>
        _editDistance(queryToken, valueToken) <=
        _maxSearchEditDistance(queryToken.length),
  );
}

List<String> _searchTokens(String value) => value
    .toLowerCase()
    .split(RegExp(r'[\s_./-]+'))
    .where((token) => token.isNotEmpty)
    .toList();

int _maxSearchEditDistance(int tokenLength) => switch (tokenLength) {
  _searchEmptyTokenLength ||
  _searchSingleCharacterTokenLength ||
  _searchShortTokenLength => _searchNoEditDistance,
  _searchMediumTokenMinLength ||
  _searchMediumTokenMaxLength => _searchSingleEditDistance,
  _ => _searchMultipleEditDistance,
};

int _editDistance(String left, String right) =>
    left == right ? _searchNoEditDistance : _calculateEditDistance(left, right);

int _calculateEditDistance(String left, String right) {
  var previousRow = List<int>.generate(right.length + 1, (index) => index);
  for (var leftIndex = 1; leftIndex <= left.length; leftIndex++) {
    previousRow = _editDistanceRow((
      left: left,
      right: right,
      leftIndex: leftIndex,
      previousRow: previousRow,
    ));
  }

  return previousRow.last;
}

typedef _EditDistanceRowState = ({
  String left,
  String right,
  int leftIndex,
  List<int> previousRow,
});

List<int> _editDistanceRow(_EditDistanceRowState state) {
  final currentRow = <int>[
    state.leftIndex,
    ...List<int>.filled(state.right.length, 0),
  ];
  for (var rightIndex = 1; rightIndex <= state.right.length; rightIndex++) {
    currentRow[rightIndex] = _editDistanceCell(state, currentRow, rightIndex);
  }

  return currentRow;
}

int _editDistanceCell(
  _EditDistanceRowState state,
  List<int> currentRow,
  int rightIndex,
) {
  final substitutionCost = _editDistanceSubstitutionCost(
    state.left.codeUnitAt(state.leftIndex - 1),
    state.right.codeUnitAt(rightIndex - 1),
    state.previousRow[rightIndex - 1],
  );

  return _minimumEditDistance(
    currentRow[rightIndex - 1],
    state.previousRow[rightIndex],
    substitutionCost,
  );
}

int _editDistanceSubstitutionCost(
  int leftCodeUnit,
  int rightCodeUnit,
  int diagonal,
) =>
    diagonal +
    (leftCodeUnit == rightCodeUnit
        ? _searchNoEditDistance
        : _searchSingleEditDistance);

int _minimumEditDistance(int left, int top, int diagonal) => math.min(
  math.min(left + _searchSingleEditDistance, top + _searchSingleEditDistance),
  diagonal,
);

Iterable<String> _skillSearchValues(
  BuildContext context,
  WorkspaceSkill skill,
) sync* {
  yield skill.title;
  final titleKey = skill.titleKey;
  if (titleKey != null) yield titleKey.tr(context: context);
  yield skill.slug;
  yield skill.source.name;
  yield _skillSourceLabel(context, skill.source);
  yield skill.kind.name;
  yield _skillKindLabel(context, skill.kind);
}

class const _SkillsScreenEmpty({required final VoidCallback onCreateSkill})
    extends StatelessWidget {
  static const _staticChildren = <Widget>[
    Icon(Icons.psychology_alt_outlined, size: _skillScreenIconSize),
    AuraText(
      child: TextLocale(LocaleKeys.skills_screen_empty_title),
      style: .heading4,
    ),
    AuraText(
      child: TextLocale(LocaleKeys.skills_screen_empty_subtitle),
      textAlign: .center,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AuraColumn(
        children: [
          ..._staticChildren,
          AuraButton(
            onPressed: onCreateSkill,
            child: const TextLocale(LocaleKeys.skills_screen_create),
          ),
        ],
        mainAxisSize: .min,
      ),
    );
  }
}

class const _SkillsList({required final _SkillsViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final skills = state.data.filter.skills;

    return _SkillsListView(
      skills: skills,
      itemBuilder: (_, index) =>
          _SkillsListItemBuilder(skill: skills[index], state: state).child,
    );
  }
}

class _SkillsListItemBuilder {
  new({required WorkspaceSkill skill, required _SkillsViewState state})
    : child = _SkillListItem(
        workspaceId: state.data.workspaceId,
        skill: skill,
        isSelected: state.data.selection.selectedIds.contains(skill.id),
        isDeleting: state.data.selection.isDeleting,
        onSelectionChanged: state.actions.bulk.onSelectionChanged,
        onOpenSkill: state.actions.items.onOpenSkill,
        onDeleteSkill: state.actions.items.onDeleteSkill,
        onSkillEnabledChanged: state.actions.items.onSkillEnabledChanged,
      );

  final Widget child;
}

class const _SkillsListView({
  required final List<WorkspaceSkill> skills,
  required final IndexedWidgetBuilder itemBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(_skillScreenListPadding).copyWith(
      bottom: BottomPadding.of(context, minimum: _skillScreenListPadding),
    ),
    itemBuilder: itemBuilder,
    separatorBuilder: (_, _) => const SizedBox(height: _skillScreenListPadding),
    itemCount: skills.length,
    keyboardDismissBehavior: .onDrag,
  );
}

class const _SkillListItem({
  required final String workspaceId,
  required final WorkspaceSkill skill,
  required final bool isSelected,
  required final bool isDeleting,
  required final void Function(WorkspaceSkill skill, ({bool isSelected}) change)
  onSelectionChanged,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SkillTile(
      workspaceId: workspaceId,
      skill: skill,
      isSelected: isSelected,
      isDeleting: isDeleting,
      onSelectionChanged: (value) =>
          onSelectionChanged(skill, (isSelected: value)),
      onOpen: () => onOpenSkill(skill),
      onDelete: () => onDeleteSkill(skill),
      onChanged: (value) => onSkillEnabledChanged(skill, (isEnabled: value)),
    );
  }
}

class const _SkillTile({
  required final String workspaceId,
  required final WorkspaceSkill skill,
  required final bool isSelected,
  required final bool isDeleting,
  required final ValueChanged<bool> onSelectionChanged,
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: _SkillTileRow(
        workspaceId: workspaceId,
        skill: skill,
        isSelected: isSelected,
        isDeleting: isDeleting,
        onSelectionChanged: onSelectionChanged,
        onOpen: onOpen,
        onDelete: onDelete,
        onChanged: onChanged,
      ),
      onTap: isDeleting ? null : onOpen,
      style: .border,
    );
  }
}

class const _SkillTileRow({
  required final String workspaceId,
  required final WorkspaceSkill skill,
  required final bool isSelected,
  required final bool isDeleting,
  required final ValueChanged<bool> onSelectionChanged,
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      _OptionalSkillSelection(
        skill: skill,
        isSelected: isSelected,
        isDeleting: isDeleting,
        onChanged: onSelectionChanged,
      ),
      AuraIcon(_skillIcon(skill)),
      Expanded(
        child: _SkillTileInfo(workspaceId: workspaceId, skill: skill),
      ),
      _SkillTileActions(
        skill: skill,
        isDeleting: isDeleting,
        onOpen: onOpen,
        onDelete: onDelete,
        onChanged: onChanged,
      ),
    ],
    spacing: .sm,
  );
}

class const _OptionalSkillSelection({
  required final WorkspaceSkill skill,
  required final bool isSelected,
  required final bool isDeleting,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (skill.source != SkillSource.user) return const SizedBox.shrink();

    return AuraCheckbox(
      value: isSelected,
      onChanged: isDeleting ? null : onChanged,
      key: ValueKey('skill-selection-${skill.id}'),
      disabled: isDeleting,
      semanticLabel: _skillSelectionLabel(context, skill, isSelected),
    );
  }
}

String _skillSelectionLabel(
  BuildContext context,
  WorkspaceSkill skill,
  bool isSelected,
) =>
    (isSelected
            ? LocaleKeys.skills_screen_deselect_skill
            : LocaleKeys.skills_screen_select_skill)
        .tr(args: [_localizedSkillTitle(context, skill)]);

IconData _skillIcon(WorkspaceSkill skill) => switch (skill.source) {
  .user => Icons.psychology_alt_outlined,
  .app => Icons.auto_awesome_outlined,
};

class const _SkillTileInfo({
  required final String workspaceId,
  required final WorkspaceSkill skill,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _SkillTileTitle(skill: skill),
        if (_description(context) case final description?)
          _SkillTileDescription(description: description),
        _SkillTileTags(skill: skill),
        TextLocale(
          skill.isEnabled
              ? LocaleKeys.authoring_enabled
              : LocaleKeys.authoring_disabled,
        ),
        SkillAccessStatusView(workspaceId: workspaceId, skillId: skill.id),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }

  String? _description(BuildContext context) {
    final description = switch (skill.descriptionKey) {
      null => skill.description,
      final descriptionKey => descriptionKey.tr(context: context),
    };

    if (description.trim().isEmpty) return null;

    return description;
  }
}

class const _SkillTileTitle({required final WorkspaceSkill skill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: switch (skill.titleKey) {
        null => Text(skill.title),
        final titleKey => TextLocale(titleKey),
      },
      style: .heading6,
    );
  }
}

class const _SkillTileDescription({required final String description})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GptMarkdown(
      description,
      style: .new(
        color: context.auraColors.onSurfaceVariant,
        fontWeight: context.auraTheme.typography.fontWeightRegular,
      ),
      maxLines: _skillDescriptionMaxLines,
      overflow: .ellipsis,
    );
  }
}

class const _SkillTileTags({required final WorkspaceSkill skill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _skillScreenSpacing,
      runSpacing: _skillScreenRunSpacing,
      children: [
        _SkillChip(label: _skillSourceLabel(context, skill.source)),
        _SkillChip(label: _skillKindLabel(context, skill.kind)),
        _SkillChip(label: skill.slug),
      ],
    );
  }
}

String _skillSourceLabel(BuildContext context, SkillSource source) =>
    switch (source) {
      .user => LocaleKeys.skills_screen_source_user.tr(context: context),
      .app => LocaleKeys.skills_screen_source_app.tr(context: context),
    };

String _skillKindLabel(BuildContext context, SkillKind kind) => switch (kind) {
  .template => LocaleKeys.skills_screen_kind_template.tr(context: context),
  .native => LocaleKeys.skills_screen_kind_native.tr(context: context),
};

class const _SkillTileActions({
  required final WorkspaceSkill skill,
  required final bool isDeleting,
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraSwitch(
          value: skill.isEnabled,
          onChanged: isDeleting ? null : onChanged,
          disabled: isDeleting,
        ),
        if (skill.source == SkillSource.user && !isDeleting)
          _SkillTileMenu(onOpen: onOpen, onDelete: onDelete),
      ],
      mainAxisSize: .min,
    );
  }
}

class const _SkillTileMenu({
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPopupMenuButton(
      items: _items(context),
      tooltip: LocaleKeys.common_show_more.tr(context: context),
    );
  }

  List<AuraPopupMenuItem> _items(BuildContext context) => [
    AuraPopupMenuItem(
      title: Text(LocaleKeys.common_edit.tr(context: context)),
      onTap: onOpen,
    ),
    AuraPopupMenuItem(
      title: Text(LocaleKeys.common_delete.tr(context: context)),
      onTap: onDelete,
      variant: .error,
    ),
  ];
}

class const _SkillChip({required final String label}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraBadge(
      child: AuraText(child: Text(label), style: .caption),
      variant: .outlined,
      size: .small,
    );
  }
}

class _DeleteSkillDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraConfirmDialog(
      title: const TextLocale(LocaleKeys.skills_screen_delete),
      message: const TextLocale(LocaleKeys.skills_screen_delete_confirm),
      confirmLabel: Text(_label(context, LocaleKeys.common_delete)),
      cancelLabel: Text(_label(context, LocaleKeys.common_cancel)),
      isDestructive: true,
    );
  }

  String _label(BuildContext context, String key) {
    return key.tr(context: context);
  }
}

class const _BulkDeleteSkillsDialog({
  required final int selectedCount,
  required final int hiddenCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraConfirmDialog(
    title: const TextLocale(LocaleKeys.skills_screen_bulk_delete_title),
    message: ManagementListFeedback.confirmationMessage(
      context,
      LocaleKeys.skills_screen_bulk_delete_confirm,
      selectedCount: selectedCount,
      hiddenCount: hiddenCount,
    ),
    confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
    cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
    isDestructive: true,
  );
}
