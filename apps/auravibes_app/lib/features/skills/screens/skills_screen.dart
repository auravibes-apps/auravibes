// Required: Existing UI spacing uses small numeric values.
// Required: Local builders keep this small screen readable.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';
import 'dart:math' as math;

import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/skills/usecases/disable_skill_usecase.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
      skillsAsync: skillsAsync,
      onCreateSkill: _openCreateSkill,
      onOpenSkill: _openSkill,
      onDeleteSkill: _confirmDeleteSkill,
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
    return showDialog<bool>(
      context: context,
      builder: (_) => _DeleteSkillDialog(),
    );
  }

  Future<void> _deleteSkill(WidgetRef ref, WorkspaceSkill skill) async {
    await ref.read(deleteSkillProvider(workspaceId))(skill.id);
    ref.invalidate(workspaceSkillsProvider(workspaceId));
  }
}

DisableSkillRequest _disableSkillRequest(
  String workspaceId,
  WorkspaceSkill skill,
  ({bool isEnabled}) change,
) => (
  workspaceId: workspaceId,
  source: skill.source,
  skillId: skill.id,
  isEnabled: change.isEnabled,
  slug: skill.slug,
  title: skill.title,
  description: skill.description,
  content: null,
);

class const _SkillsScreenScaffoldView({
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
        skillsAsync: skillsAsync,
        onCreateSkill: onCreateSkill,
        onOpenSkill: onOpenSkill,
        onDeleteSkill: onDeleteSkill,
        onSkillEnabledChanged: onSkillEnabledChanged,
      ),
      appBar: _SkillsScreenAppBar(onCreateSkill: () => onCreateSkill(context)),
    );
  }
}

class const _SkillsScreenAppBar({required final VoidCallback onCreateSkill})
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      _SkillsScreenAppBarData(onCreateSkill: onCreateSkill).child;
}

class _SkillsScreenAppBarData {
  new({required VoidCallback onCreateSkill})
    : child = AuraAppBarWithDrawer(
        title: const TextLocale(LocaleKeys.skills_screen_title),
        actions: [_SkillsScreenCreateButton(onPressed: onCreateSkill)],
        leading: const _SkillsScreenBackButton(),
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

class const _SkillsScreenBackButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.arrow_back,
    onPressed: () => Navigator.of(context).pop(),
  );
}

class const _SkillsScreenBody({
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
  required final Future<void> Function(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  )
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillsScreenAsyncContent(
    skillsAsync: skillsAsync,
    onCreateSkill: () => unawaited(onCreateSkill(context)),
    onOpenSkill: (skill) => onOpenSkill(context, skill.id),
    onDeleteSkill: onDeleteSkill,
    onSkillEnabledChanged: onSkillEnabledChanged,
  );
}

class const _SkillsScreenAsyncContent({
  required final AsyncValue<List<WorkspaceSkill>> skillsAsync,
  required final VoidCallback onCreateSkill,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  )
  onDeleteSkill,
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
        skillsAsync: skillsAsync,
        onCreateSkill: onCreateSkill,
        onOpenSkill: onOpenSkill,
        onDeleteSkill: (skill) => onDeleteSkill(context, ref, skill),
        onSkillEnabledChanged: (skill, value) =>
            onSkillEnabledChanged(ref, skill, value),
      ).child;
}

class _SkillsScreenAsyncContentData {
  new({
    required AsyncValue<List<WorkspaceSkill>> skillsAsync,
    required VoidCallback onCreateSkill,
    required ValueChanged<WorkspaceSkill> onOpenSkill,
    required ValueChanged<WorkspaceSkill> onDeleteSkill,
    required void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
    onSkillEnabledChanged,
  }) : child = switch (_loadedSkills(skillsAsync)) {
         null => _SkillsScreenPendingState(skillsAsync: skillsAsync),
         final skills => _SkillsScreenLoadedContent(
           skills: skills,
           onCreateSkill: onCreateSkill,
           onOpenSkill: onOpenSkill,
           onDeleteSkill: onDeleteSkill,
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
  required final List<WorkspaceSkill> skills,
  required final VoidCallback onCreateSkill,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
  onSkillEnabledChanged,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final searchQuery = useState('');
    final sourceFilter = useState<SkillSource?>(null);
    final enabledFilter = useState<bool?>(null);

    return _SkillsScreenLoadedContentData(
      context,
      this,
      searchQuery,
      sourceFilter,
      enabledFilter,
    ).child;
  }
}

typedef _SkillsScreenSearchActions = ({
  ValueChanged<String> onSearchChanged,
  ValueChanged<SkillSource?> onSourceChanged,
  ValueChanged<bool?> onEnabledChanged,
});

typedef _SkillsScreenSkillActions = ({
  VoidCallback onCreateSkill,
  ValueChanged<WorkspaceSkill> onOpenSkill,
  ValueChanged<WorkspaceSkill> onDeleteSkill,
  void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
  onSkillEnabledChanged,
});

class _SkillsScreenLoadedContentData {
  new(
    BuildContext context,
    _SkillsScreenLoadedContent screen,
    ValueNotifier<String> searchQuery,
    ValueNotifier<SkillSource?> sourceFilter,
    ValueNotifier<bool?> enabledFilter,
  ) : child = _SkillsScreenLoadedContentViewData(
        context,
        screen,
        _loadedSkillFilters(searchQuery, sourceFilter, enabledFilter),
        _loadedSearchActions(searchQuery, sourceFilter, enabledFilter),
        _loadedSkillActions(screen),
      ).child;

  final Widget child;
}

class _SkillsScreenLoadedContentViewData {
  new(
    BuildContext context,
    _SkillsScreenLoadedContent screen,
    _SkillsFilterState filters,
    _SkillsScreenSearchActions searchActions,
    _SkillsScreenSkillActions skillActions,
  ) : child = screen.skills.isEmpty
          ? _SkillsScreenEmpty(onCreateSkill: skillActions.onCreateSkill)
          : _SkillsScreenLoadedView(
              source: filters.source,
              skills: _filterSkills(context, screen.skills, filters),
              enabled: filters.enabled,
              onSearchChanged: searchActions.onSearchChanged,
              onSourceChanged: searchActions.onSourceChanged,
              onEnabledChanged: searchActions.onEnabledChanged,
              onOpenSkill: skillActions.onOpenSkill,
              onDeleteSkill: skillActions.onDeleteSkill,
              onSkillEnabledChanged: skillActions.onSkillEnabledChanged,
            );

  final Widget child;
}

_SkillsFilterState _loadedSkillFilters(
  ValueNotifier<String> searchQuery,
  ValueNotifier<SkillSource?> sourceFilter,
  ValueNotifier<bool?> enabledFilter,
) => (
  queryTokens: _searchTokens(searchQuery.value),
  source: sourceFilter.value,
  enabled: enabledFilter.value,
);

_SkillsScreenSearchActions _loadedSearchActions(
  ValueNotifier<String> searchQuery,
  ValueNotifier<SkillSource?> sourceFilter,
  ValueNotifier<bool?> enabledFilter,
) => (
  onSearchChanged: (value) => searchQuery.value = value,
  onSourceChanged: (value) => sourceFilter.value = value,
  onEnabledChanged: (value) => enabledFilter.value = value,
);

_SkillsScreenSkillActions _loadedSkillActions(
  _SkillsScreenLoadedContent screen,
) => (
  onCreateSkill: screen.onCreateSkill,
  onOpenSkill: screen.onOpenSkill,
  onDeleteSkill: screen.onDeleteSkill,
  onSkillEnabledChanged: screen.onSkillEnabledChanged,
);

class const _SkillsScreenLoadedView({
  required final List<WorkspaceSkill> skills,
  required final SkillSource? source,
  required final bool? enabled,
  required final ValueChanged<String> onSearchChanged,
  required final ValueChanged<SkillSource?> onSourceChanged,
  required final ValueChanged<bool?> onEnabledChanged,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Column(
    children: [
      _SkillsScreenFilters(
        source: source,
        enabled: enabled,
        onSearchChanged: onSearchChanged,
        onSourceChanged: onSourceChanged,
        onEnabledChanged: onEnabledChanged,
      ),
      Expanded(
        child: _SkillsScreenFilteredList(
          skills: skills,
          onOpenSkill: onOpenSkill,
          onDeleteSkill: onDeleteSkill,
          onSkillEnabledChanged: onSkillEnabledChanged,
        ),
      ),
    ],
  );
}

class const _SkillsScreenFilteredList({
  required final List<WorkspaceSkill> skills,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => skills.isEmpty
      ? const _SkillsScreenSearchEmpty()
      : _SkillsList(
          skills: skills,
          onOpenSkill: onOpenSkill,
          onDeleteSkill: onDeleteSkill,
          onSkillEnabledChanged: onSkillEnabledChanged,
        );
}

class const _SkillsScreenFilters({
  required final SkillSource? source,
  required final bool? enabled,
  required final ValueChanged<String> onSearchChanged,
  required final ValueChanged<SkillSource?> onSourceChanged,
  required final ValueChanged<bool?> onEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.sm);

    return Padding(
      padding: EdgeInsets.only(left: spacing, top: spacing, right: spacing),
      child: _SkillsScreenFilterFields(
        source: source,
        enabled: enabled,
        onSearchChanged: onSearchChanged,
        onSourceChanged: onSourceChanged,
        onEnabledChanged: onEnabledChanged,
      ),
    );
  }
}

class const _SkillsScreenFilterFields({
  required final SkillSource? source,
  required final bool? enabled,
  required final ValueChanged<String> onSearchChanged,
  required final ValueChanged<SkillSource?> onSourceChanged,
  required final ValueChanged<bool?> onEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      _SkillsScreenSearchInput(onChanged: onSearchChanged),
      _SkillsScreenFilterRow(
        source: source,
        enabled: enabled,
        onSourceChanged: onSourceChanged,
        onEnabledChanged: onEnabledChanged,
      ),
    ],
    spacing: .sm,
  );
}

class const _SkillsScreenSearchInput({
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraInput(
    placeholder: const TextLocale(LocaleKeys.skills_screen_search_placeholder),
    prefixIcon: const AuraIcon(Icons.search),
    size: .small,
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

class const _SkillsList({
  required final List<WorkspaceSkill> skills,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillsListView(
    skills: skills,
    itemBuilder: (_, index) => _SkillListItem(
      skill: skills[index],
      onOpenSkill: onOpenSkill,
      onDeleteSkill: onDeleteSkill,
      onSkillEnabledChanged: onSkillEnabledChanged,
    ),
  );
}

class const _SkillsListView({
  required final List<WorkspaceSkill> skills,
  required final IndexedWidgetBuilder itemBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(_skillScreenListPadding),
    itemBuilder: itemBuilder,
    separatorBuilder: (_, _) => const SizedBox(height: _skillScreenListPadding),
    itemCount: skills.length,
  );
}

class const _SkillListItem({
  required final WorkspaceSkill skill,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final void Function(WorkspaceSkill skill, ({bool isEnabled}) change)
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SkillTile(
      skill: skill,
      onOpen: () => onOpenSkill(skill),
      onDelete: () => onDeleteSkill(skill),
      onChanged: (value) => onSkillEnabledChanged(skill, (isEnabled: value)),
    );
  }
}

class const _SkillTile({
  required final WorkspaceSkill skill,
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: _SkillTileRow(
        skill: skill,
        onOpen: onOpen,
        onDelete: onDelete,
        onChanged: onChanged,
      ),
      onTap: onOpen,
      style: .border,
    );
  }
}

class const _SkillTileRow({
  required final WorkspaceSkill skill,
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraIcon(_skillIcon(skill)),
        Expanded(child: _SkillTileInfo(skill: skill)),
        _SkillTileActions(
          skill: skill,
          onOpen: onOpen,
          onDelete: onDelete,
          onChanged: onChanged,
        ),
      ],
      spacing: .sm,
    );
  }
}

IconData _skillIcon(WorkspaceSkill skill) => switch (skill.source) {
  .user => Icons.psychology_alt_outlined,
  .app => Icons.auto_awesome_outlined,
};

class const _SkillTileInfo({required final WorkspaceSkill skill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _SkillTileTitle(skill: skill),
        if (_description(context) case final description?)
          _SkillTileDescription(description: description),
        _SkillTileTags(skill: skill),
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
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraSwitch(value: skill.isEnabled, onChanged: onChanged),
        if (skill.source == SkillSource.user)
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
