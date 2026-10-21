import 'dart:async';

import 'package:auravibes_app/features/chats/models/skill_context_preparation_failure.dart';
import 'package:auravibes_app/features/chats/models/skill_context_preparation_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/prepare_conversation_skill_context_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/models/conversation_skill_action.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/features/skills/usecases/apply_conversation_skill_action_usecase.dart';
import 'package:auravibes_app/features/skills/widgets/skill_access_status_view.dart';
import 'package:auravibes_app/features/skills/widgets/skill_capability_preview_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _selectorDialogWidth = 520.0;
const _selectorLoadingHeight = 120.0;

typedef _SkillSectionContext = ({
  ConversationSkillSelectorState state,
  String query,
  Set<String> pendingSlugs,
  Map<String, ConversationSkillActionResult> actionResults,
  _SelectorActions actions,
  List<AvailableSkill> recentSkills,
  Set<String> recentSlugs,
});

typedef _SkillSectionDisplayData = ({
  bool hidden,
  String emptyKey,
  List<AvailableSkill> skills,
});

typedef _SkillTileData = ({
  ConversationSkillContextStatus? contextStatus,
  ConversationSkillContextFailure? contextFailure,
  bool pending,
  ConversationSkillActionResult? actionResult,
  _SelectorActions actions,
});

void _restoreSelectorFocus(FocusNode? focusNode) {
  if (focusNode == null || focusNode.context == null) return;
  focusNode.requestFocus();
}

class const ConversationSkillSelectorModal({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerStatefulWidget {
  /// Opens the selector and restores the previous focus node when it closes.
  static Future<void> show({
    required BuildContext context,
    required String workspaceId,
    required String conversationId,
  }) async {
    final focusNode = FocusManager.instance.primaryFocus;
    await showDialog<void>(
      context: context,
      builder: (_) => ConversationSkillSelectorModal(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    );
    if (!context.mounted) return;
    _restoreSelectorFocus(focusNode);
  }

  @override
  ConsumerState<ConversationSkillSelectorModal> createState() =>
      _ConversationSkillSelectorModalState();
}

class _ConversationSkillSelectorModalState
    extends ConsumerState<ConversationSkillSelectorModal> {
  final Set<String> _pendingSlugs = {};
  final Map<String, ConversationSkillActionResult> _actionResults = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final selectorAsync = ref.watch(
      conversationSkillSelectorProvider(
        widget.workspaceId,
        widget.conversationId,
      ),
    );

    return _SelectorDialog(
      selectorAsync: selectorAsync,
      query: _query,
      pendingSlugs: _pendingSlugs,
      actionResults: _actionResults,
      actions: _selectorActions(this),
    );
  }

  Future<void> _apply(
    AvailableSkill skill,
    ConversationSkillAction action,
  ) async {
    if (!_beginAction(skill)) return;

    final result = await _applyAction(skill, action);
    if (!mounted) return;
    _completeAction(skill, result);
  }

  bool _beginAction(AvailableSkill skill) {
    if (!_pendingSlugs.add(skill.slug)) return false;

    setState(() => _actionResults.remove(skill.slug));

    return true;
  }

  void _completeAction(
    AvailableSkill skill,
    ConversationSkillActionResult result,
  ) {
    setState(() {
      final _ = _pendingSlugs.remove(skill.slug);
      _actionResults[skill.slug] = result;
    });
    _handleActionResult(result);
  }

  Future<void> _retryContext(AvailableSkill _) async {
    final runtime = ref.read(conversationSkillContextRuntimeProvider.notifier);
    final generation = runtime.begin(widget.conversationId);
    await _prepareContext(runtime, generation);
    if (!mounted) return;
    _invalidateSelector();
  }

  void _refreshSelector() {
    ref.invalidate(skillAccessSummaryProvider);
    ref
        .read(conversationSkillContextRuntimeProvider.notifier)
        .markNeedsContext(widget.conversationId);
    _invalidateSelector();
  }

  Future<void> _openConnectorSetup(AvailableSkill skill) async {
    if (skill.connectorToolIds.isEmpty) return;
    final _ = await FeatureDestinations.push<bool>(
      context,
      ServiceConnectionsRoute(
        workspaceId: widget.workspaceId,
        view: 'connectors',
      ).location,
    );
    if (!mounted) return;

    _refreshSelector();
  }

  ConversationSkillContextFailure _runtimeFailure(
    SkillContextPreparationFailure failure,
  ) => switch (failure) {
    .missingConnection => .missingConnection,
    .unavailableMetadata => .unavailableMetadata,
    .preparationFailed => .preparationFailed,
  };

  void _invalidateSelector() => ref.invalidate(
    conversationSkillSelectorProvider(
      widget.workspaceId,
      widget.conversationId,
    ),
  );

  void _setQuery(String query) => setState(() => _query = query);
}

extension _ConversationSkillSelectorActionHandlers
    on _ConversationSkillSelectorModalState {
  void _showPreview(AvailableSkill skill) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => SkillCapabilityPreviewDialog(
          workspaceId: widget.workspaceId,
          skill: skill,
        ),
      ),
    );
  }

  Future<ConversationSkillActionResult> _applyAction(
    AvailableSkill skill,
    ConversationSkillAction action,
  ) async {
    try {
      return await ref
          .read(applyConversationSkillActionUsecaseProvider)
          .call(
            request: (
              workspaceId: widget.workspaceId,
              conversationId: widget.conversationId,
              slug: skill.slug,
              action: action,
              userRequestForSkill: (title) => LocaleKeys
                  .skills_selector_use_now_request
                  .tr(namedArgs: {'skill': title}),
              expectedCatalogRevision: null,
            ),
          );
    } on Object {
      return .unavailable;
    }
  }

  void _handleActionResult(ConversationSkillActionResult result) {
    if (_refreshesSelector(result)) _invalidateSelector();
    if (result == .used) {
      final _ = Navigator.of(context).maybePop();
    }
  }
}

extension _ConversationSkillSelectorContextHandlers
    on _ConversationSkillSelectorModalState {
  Future<void> _prepareContext(
    ConversationSkillContextRuntime runtime,
    int generation,
  ) async {
    try {
      final result = await ref
          .read(prepareConversationSkillContextUsecaseProvider)
          .call(
            workspaceId: widget.workspaceId,
            conversationId: widget.conversationId,
          );
      _recordContextResult(runtime, generation, result);
    } on Object {
      runtime.errorWithCause(
        widget.conversationId,
        generation,
        .preparationFailed,
      );
    }
  }

  void _recordContextResult(
    ConversationSkillContextRuntime runtime,
    int generation,
    SkillContextPreparationResult result,
  ) {
    final failure = result.failure;
    if (failure == null) {
      runtime.ready(
        widget.conversationId,
        generation,
        selectedRevisions: result.selectedRevisions,
        canActivate: result.canActivate,
      );

      return;
    }
    runtime.errorWithCause(
      widget.conversationId,
      generation,
      _runtimeFailure(failure),
    );
  }

  void _startConnectorSetup(AvailableSkill skill) {
    unawaited(_openConnectorSetup(skill));
  }
}

_SelectorActions _selectorActions(_ConversationSkillSelectorModalState state) =>
    _SelectorActions(
      workspaceId: state.widget.workspaceId,
      onSearch: state._setQuery,
      onAdd: _skillActionHandler(state, .add),
      onUseNow: _skillActionHandler(state, .useNow),
      onRetry: _contextRetryHandler(state),
      onRefresh: state._refreshSelector,
      onConnectorSetup: state._startConnectorSetup,
      onPreview: state._showPreview,
    );

ValueChanged<AvailableSkill> _skillActionHandler(
  _ConversationSkillSelectorModalState state,
  ConversationSkillAction action,
) =>
    (skill) => unawaited(state._apply(skill, action));

ValueChanged<AvailableSkill> _contextRetryHandler(
  _ConversationSkillSelectorModalState state,
) =>
    (skill) => unawaited(state._retryContext(skill));

bool _refreshesSelector(ConversationSkillActionResult result) =>
    result == .added || result == .alreadyAdded || result == .used;

class const _SelectorActions({
  required final String workspaceId,
  required final ValueChanged<String> onSearch,
  required final ValueChanged<AvailableSkill> onAdd,
  required final ValueChanged<AvailableSkill> onUseNow,
  required final ValueChanged<AvailableSkill> onRetry,
  required final VoidCallback onRefresh,
  required final ValueChanged<AvailableSkill> onConnectorSetup,
  required final ValueChanged<AvailableSkill> onPreview,
});

class const _SelectorDialog({
  required final AsyncValue<ConversationSkillSelectorState> selectorAsync,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraAlertDialog(
    title: const AuraColumn(
      children: [
        TextLocale(LocaleKeys.skills_selector_title),
        TextLocale(LocaleKeys.skills_selector_actions_hint),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    ),
    message: _SelectorDialogMessage(
      selectorAsync: selectorAsync,
      query: query,
      pendingSlugs: pendingSlugs,
      actionResults: actionResults,
      actions: actions,
    ),
    dismissLabel: const TextLocale(LocaleKeys.common_close),
  );
}

class const _SelectorDialogMessage({
  required final AsyncValue<ConversationSkillSelectorState> selectorAsync,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: _selectorDialogWidth,
    child: _SelectorBody(
      selectorAsync: selectorAsync,
      query: query,
      pendingSlugs: pendingSlugs,
      actionResults: actionResults,
      actions: actions,
    ),
  );
}

class const _SelectorBody({
  required final AsyncValue<ConversationSkillSelectorState> selectorAsync,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = switch (selectorAsync) {
      AsyncData(:final value) => value,
      AsyncLoading(value: final value?, hasValue: true) => value,
      AsyncLoading() || AsyncError() => null,
    };
    if (state != null) {
      return _SelectorScrollContent(
        state: state,
        query: query,
        pendingSlugs: pendingSlugs,
        actionResults: actionResults,
        actions: actions,
      );
    }

    return _SelectorAsyncFallback(isLoading: selectorAsync is AsyncLoading);
  }
}

class const _SelectorScrollContent({
  required final ConversationSkillSelectorState state,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: _SelectorContent(
      state: state,
      query: query,
      pendingSlugs: pendingSlugs,
      actionResults: actionResults,
      actions: actions,
    ),
  );
}

class const _SelectorAsyncFallback({required final bool isLoading})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Semantics(
        child: const ExcludeSemantics(
          child: SizedBox(
            height: _selectorLoadingHeight,
            child: Center(child: AuraSpinner()),
          ),
        ),
        liveRegion: true,
        label: LocaleKeys.skills_selector_loading.tr(context: context),
      );
    }

    return Semantics(
      child: const TextLocale(LocaleKeys.skills_selector_error),
      liveRegion: true,
    );
  }
}

class const _SelectorContent({
  required final ConversationSkillSelectorState state,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  _SkillSectionContext get _sectionContext {
    final recentSkills = _visibleRecentSkills(state.recentSkills, query);

    return (
      state: state,
      query: query,
      pendingSlugs: pendingSlugs,
      actionResults: actionResults,
      actions: actions,
      recentSkills: recentSkills,
      recentSlugs: recentSkills.map((skill) => skill.slug).toSet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionContext = _sectionContext;

    return AuraColumn(
      children: [
        _SelectorSearch(onChanged: actions.onSearch),
        if (sectionContext.recentSkills.isNotEmpty)
          _RecentSkillSection(context: sectionContext),
        _LoadedSkillSection(context: sectionContext),
        _AvailableSkillSection(context: sectionContext, skills: state.loadable),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _LoadedSkillSection({required final _SkillSectionContext context})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sectionContext = this.context;
    final display = _skillSectionDisplayData(
      sectionContext,
      sectionContext.state.loaded,
      LocaleKeys.skills_selector_loaded_empty,
    );
    if (display.hidden) return const SizedBox.shrink();

    return _SkillSection(
      titleKey: LocaleKeys.skills_selector_loaded_title,
      emptyKey: display.emptyKey,
      children: display.skills.isEmpty
          ? const []
          : [
              _LoadedSkillTiles(
                skills: display.skills,
                context: sectionContext,
              ),
            ],
    );
  }
}

class const _LoadedSkillTiles({
  required final List<AvailableSkill> skills,
  required final _SkillSectionContext context,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sectionContext = this.context;

    return AuraColumn(
      children: [
        for (final skill in skills)
          _LoadedSkillTile(
            skill: skill,
            data: _skillTileData(sectionContext, skill, loaded: true),
          ),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _RecentSkillSection({required final _SkillSectionContext context})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sectionContext = this.context;

    return _SkillSection(
      titleKey: LocaleKeys.skills_selector_recent_title,
      emptyKey: null,
      children: [_RecentSkillTiles(context: sectionContext)],
    );
  }
}

class const _RecentSkillTiles({required final _SkillSectionContext context})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sectionContext = this.context;
    final loadedSlugs = sectionContext.state.loaded
        .map((skill) => skill.slug)
        .toSet();

    return AuraColumn(
      children: [
        for (final skill in sectionContext.recentSkills)
          _RecentSkillTile(
            context: sectionContext,
            skill: skill,
            loaded: loadedSlugs.contains(skill.slug),
          ),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _RecentSkillTile({
  required final _SkillSectionContext context,
  required final AvailableSkill skill,
  required final bool loaded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sectionContext = this.context;
    final skill = this.skill;

    if (!loaded) {
      return _AvailableSkillTile(
        skill: skill,
        data: _skillTileData(sectionContext, skill),
      );
    }

    return _LoadedSkillTile(
      skill: skill,
      data: _skillTileData(sectionContext, skill, loaded: true),
    );
  }
}

class const _AvailableSkillSection({
  required final _SkillSectionContext context,
  required final List<AvailableSkill> skills,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sectionContext = this.context;
    final display = _skillSectionDisplayData(
      sectionContext,
      skills,
      LocaleKeys.skills_selector_available_empty,
    );
    if (display.hidden) return const SizedBox.shrink();

    return _SkillSection(
      titleKey: LocaleKeys.skills_selector_available_title,
      emptyKey: display.emptyKey,
      children: display.skills.isEmpty
          ? const []
          : [
              _AvailableSkillTiles(
                context: sectionContext,
                skills: display.skills,
              ),
            ],
    );
  }
}

class const _AvailableSkillTiles({
  required final _SkillSectionContext context,
  required final List<AvailableSkill> skills,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sectionContext = this.context;

    return AuraColumn(
      children: [
        for (final skill in skills)
          _AvailableSkillTile(
            skill: skill,
            data: _skillTileData(sectionContext, skill),
          ),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

_SkillSectionDisplayData _skillSectionDisplayData(
  _SkillSectionContext context,
  List<AvailableSkill> skills,
  String emptyKey,
) {
  final query = context.query;
  final recentSlugs = context.recentSlugs;

  return (
    hidden: _onlyRecentSkills(skills, query, recentSlugs),
    emptyKey: _emptySkillKey(query, emptyKey),
    skills: _searchableSkills(skills, query, recentSlugs),
  );
}

_SkillTileData _skillTileData(
  _SkillSectionContext context,
  AvailableSkill skill, {
  bool loaded = false,
}) => (
  contextStatus: loaded ? context.state.contextStatusBySlug[skill.slug] : null,
  contextFailure: loaded ? context.state.failureBySlug[skill.slug] : null,
  pending: context.pendingSlugs.contains(skill.slug),
  actionResult: context.actionResults[skill.slug],
  actions: context.actions,
);

bool _onlyRecentSkills(
  List<AvailableSkill> skills,
  String query,
  Set<String> recentSlugs,
) =>
    query.trim().isEmpty &&
    skills.isNotEmpty &&
    skills.every((skill) => recentSlugs.contains(skill.slug));

List<AvailableSkill> _searchableSkills(
  List<AvailableSkill> skills,
  String query,
  Set<String> excludedSlugs,
) => _matchingSkills(
  skills,
  query,
).where((skill) => !excludedSlugs.contains(skill.slug)).toList();

String _emptySkillKey(String query, String emptyKey) =>
    query.trim().isEmpty ? emptyKey : LocaleKeys.skills_selector_search_empty;

List<AvailableSkill> _visibleRecentSkills(
  List<AvailableSkill> recentSkills,
  String query,
) {
  if (query.trim().isNotEmpty) return const [];

  final seenSlugs = <String>{};

  return [
    for (final skill in recentSkills)
      if (seenSlugs.add(skill.slug)) skill,
  ];
}

List<AvailableSkill> _matchingSkills(
  List<AvailableSkill> skills,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return skills;

  return skills
      .where(
        (skill) =>
            skill.title.toLowerCase().contains(normalized) ||
            skill.description.toLowerCase().contains(normalized),
      )
      .toList();
}

class const _SelectorSearch({required final ValueChanged<String> onChanged})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    placeholder: const TextLocale(
      LocaleKeys.skills_selector_search_placeholder,
    ),
    prefixIcon: const AuraIcon(Icons.search),
    size: .small,
    textInputAction: .search,
    autofocus: true,
    onChanged: onChanged,
  );
}

class const _SkillSection({
  required final String titleKey,
  required final String? emptyKey,
  required final List<Widget> children,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final emptyMessage = emptyKey;

    return AuraColumn(
      children: [
        AuraText(child: TextLocale(titleKey), style: .heading4),
        if (children.isEmpty && emptyMessage != null)
          AuraText(child: TextLocale(emptyMessage))
        else
          ...children,
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _LoadedSkillTile({
  required final AvailableSkill skill,
  required final _SkillTileData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final tileData = data;

    return _SkillTileLayout(
      child: _SkillTileContents(skill: skill, data: tileData, selected: true),
      actions: _LoadedSkillActions(skill: skill, data: tileData),
    );
  }
}

class const _AvailableSkillTile({
  required final AvailableSkill skill,
  required final _SkillTileData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final tileData = data;

    return _SkillTileLayout(
      child: _SkillTileContents(skill: skill, data: tileData, selected: false),
      actions: _AvailableSkillActions(skill: skill, data: tileData),
    );
  }
}

class const _SkillTileLayout({
  required final Widget child,
  required final Widget actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => constraints.maxWidth < _selectorDialogWidth
        ? _CompactSkillTile(child: child, actions: actions)
        : _WideSkillTile(child: child, actions: actions),
  );
}

class const _CompactSkillTile({
  required final Widget child,
  required final Widget actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: AuraColumn(
      children: [child, actions],
      spacing: .sm,
      crossAxisAlignment: .stretch,
    ),
    variant: .ghost,
  );
}

class const _WideSkillTile({
  required final Widget child,
  required final Widget actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraTile(child: child, variant: .ghost, trailing: actions);
}

class _SkillTileContents extends StatelessWidget {
  new({
    required AvailableSkill skill,
    required _SkillTileData data,
    required bool selected,
  }) : _children = [
         _SkillTileIdentity(
           skill: skill,
           selected: selected,
           pending: data.pending,
           onPreview: data.actions.onPreview,
           contextStatus: data.contextStatus,
           contextFailure: data.contextFailure,
           actionResult: data.actionResult,
         ),
         _SkillTileAccessStatus(
           skill: skill,
           actions: data.actions,
           pending: data.pending,
         ),
         _SkillTileMessages(
           description: skill.description,
           contextFailure: data.contextFailure,
           actionResult: data.actionResult,
         ),
       ];

  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      AuraColumn(children: _children, spacing: .xs, crossAxisAlignment: .start);
}

class const _SkillTileAccessStatus({
  required final AvailableSkill skill,
  required final _SelectorActions actions,
  required final bool pending,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SkillAccessStatusView(
    workspaceId: actions.workspaceId,
    skillId: skill.id,
    showDependencies: true,
    isAppSkill: skill.source == .app,
    onChanged: actions.onRefresh,
    recoveryEnabled: !pending,
    connectorSetupSemanticLabel: LocaleKeys
        .skills_selector_semantics_connector_setup
        .tr(namedArgs: {'skill': skill.title}),
  );
}

class const _SkillTileIdentity({
  required final AvailableSkill skill,
  required final bool selected,
  required final bool pending,
  required final ValueChanged<AvailableSkill> onPreview,
  final ConversationSkillContextStatus? contextStatus,
  final ConversationSkillContextFailure? contextFailure,
  final ConversationSkillActionResult? actionResult,
}) extends StatefulWidget {
  @override
  State<_SkillTileIdentity> createState() => _SkillTileIdentityState();
}

class _SkillTileIdentityState extends State<_SkillTileIdentity> {
  bool _showFocusHighlight = false;

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;

    return Semantics(
      key: ValueKey('skill-row-${skill.slug}'),
      child: _SkillTileIdentityFocus(
        tile: widget,
        showFocusHighlight: _showFocusHighlight,
        onFocusHighlightChanged: _setFocusHighlight,
      ),
      container: true,
      selected: widget.selected,
      button: true,
      label: _skillIdentitySemanticsLabel(context, widget),
      onTap: () => widget.onPreview(skill),
    );
  }

  void _setFocusHighlight(bool value) {
    if (_showFocusHighlight == value) return;
    setState(() => _showFocusHighlight = value);
  }
}

class const _SkillTileIdentityFocus({
  required final _SkillTileIdentity tile,
  required final bool showFocusHighlight,
  required final ValueChanged<bool> onFocusHighlightChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    actions: _skillTileIdentityActions(tile),
    onShowFocusHighlight: onFocusHighlightChanged,
    mouseCursor: SystemMouseCursors.click,
    child: _SkillTileIdentityContent(
      tile: tile,
      showFocusHighlight: showFocusHighlight,
    ),
  );
}

Map<Type, Action<Intent>> _skillTileIdentityActions(_SkillTileIdentity tile) =>
    {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          tile.onPreview(tile.skill);

          return null;
        },
      ),
    };

class const _SkillTileIdentityContent({
  required final _SkillTileIdentity tile,
  required final bool showFocusHighlight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: showFocusHighlight
          ? Border.all(color: context.auraColors.primary, width: 2)
          : null,
      borderRadius: const BorderRadius.all(.circular(4)),
    ),
    child: ExcludeSemantics(child: _SkillTileIdentityLabels(tile: tile)),
  );
}

class const _SkillTileIdentityLabels({required final _SkillTileIdentity tile})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: Text(tile.skill.title)),
      _ConnectorConnectionBadge(readiness: tile.skill.connectorReadiness),
      if (tile.contextStatus case final status?)
        _SkillContextBadge(status: status),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

String _skillIdentitySemanticsLabel(
  BuildContext context,
  _SkillTileIdentity identity,
) => [
  identity.skill.title,
  _skillIdentityMembershipLabel(context, identity.selected),
  _connectorReadinessLabel(context, identity.skill),
  ..._skillContextSemanticsLabels(context, identity),
  ..._skillActionSemanticsLabels(context, identity),
].join(', ');

List<String> _skillContextSemanticsLabels(
  BuildContext context,
  _SkillTileIdentity identity,
) => [
  if (identity.contextStatus case final status?)
    _skillContextStatusLabel(context, status),
  if (identity.contextFailure case final failure?)
    _skillContextFailureLabel(context, failure),
  if (identity.pending) _skillPendingLabel(context),
];

List<String> _skillActionSemanticsLabels(
  BuildContext context,
  _SkillTileIdentity identity,
) => [
  if (identity.actionResult case final result?)
    ?_skillActionResultLabel(context, result),
];

String _skillIdentityMembershipLabel(BuildContext context, bool selected) =>
    (selected
            ? LocaleKeys.skills_selector_semantics_loaded
            : LocaleKeys.skills_selector_semantics_available)
        .tr(context: context);

String _connectorReadinessLabel(BuildContext context, AvailableSkill skill) =>
    _connectionReadinessKey(skill.connectorReadiness).tr(context: context);

String _skillContextStatusLabel(
  BuildContext context,
  ConversationSkillContextStatus status,
) => _contextStatusKey(status).tr(context: context);

String _skillContextFailureLabel(
  BuildContext context,
  ConversationSkillContextFailure failure,
) => _contextFailureKey(failure).tr(context: context);

String _skillPendingLabel(BuildContext context) =>
    LocaleKeys.skills_selector_semantics_pending.tr(context: context);

String? _skillActionResultLabel(
  BuildContext context,
  ConversationSkillActionResult result,
) => _actionResultKey(result)?.tr(context: context);

String _connectionReadinessKey(ConnectorConnectionReadiness readiness) =>
    switch (readiness) {
      .ready => LocaleKeys.skills_selector_connection_ready,
      .missing => LocaleKeys.skills_selector_connection_missing,
      .unknown => LocaleKeys.skills_selector_connection_unknown,
    };

String _contextStatusKey(ConversationSkillContextStatus status) =>
    switch (status) {
      .added => LocaleKeys.skills_selector_context_added,
      .preparing => LocaleKeys.skills_selector_context_preparing,
      .ready => LocaleKeys.skills_selector_context_ready,
      .needsContext => LocaleKeys.skills_selector_context_needs_context,
      .error => LocaleKeys.skills_selector_context_error,
    };

class const _SkillTileMessages({
  required final String description,
  final ConversationSkillContextFailure? contextFailure,
  final ConversationSkillActionResult? actionResult,
}) extends StatelessWidget {
  String? get _resultKey => switch (actionResult) {
    final result? => _actionResultKey(result),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        AuraText(child: Text(description)),
        if (contextFailure case final failure?)
          _SkillContextFailureMessage(failure: failure),
        if (_resultKey case final resultKey?)
          Semantics(child: TextLocale(resultKey), liveRegion: true),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _SkillContextFailureMessage({
  required final ConversationSkillContextFailure failure,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: TextLocale(_contextFailureKey(failure)),
    liveRegion: true,
  );
}

class _LoadedSkillActions extends StatelessWidget {
  new({required AvailableSkill skill, required _SkillTileData data})
    : _children = [
        _PreviewSkillButton(skill: skill, onPressed: data.actions.onPreview),
        _UseNowButton(
          skill: skill,
          pending: data.pending,
          onPressed: data.actions.onUseNow,
        ),
        if (_showsRecovery(
          data.contextStatus,
          data.contextFailure,
          data.actionResult,
        ))
          _RecoveryButton(
            skill: skill,
            contextFailure: data.contextFailure,
            actionResult: data.actionResult,
            disabled: data.pending,
            actions: data.actions,
          ),
      ];

  final List<Widget> _children;

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _children,
    spacing: .xs,
    crossAxisAlignment: .end,
    mainAxisSize: .min,
  );
}

class _AvailableSkillActions extends StatelessWidget {
  new({required AvailableSkill skill, required _SkillTileData data})
    : _children = [
        _PreviewSkillButton(skill: skill, onPressed: data.actions.onPreview),
        _AddSkillButton(
          skill: skill,
          pending: data.pending,
          onPressed: data.actions.onAdd,
        ),
        if (_requiresConnectorSetup(skill, data.actionResult))
          _AvailableSkillConnectorSetup(
            skill: skill,
            pending: data.pending,
            actions: data.actions,
          ),
      ];

  final List<Widget> _children;

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _children,
    spacing: .xs,
    crossAxisAlignment: .end,
    mainAxisSize: .min,
  );
}

bool _requiresConnectorSetup(
  AvailableSkill skill,
  ConversationSkillActionResult? actionResult,
) => skill.connectorReadiness == .missing || actionResult == .connectionMissing;

class const _AvailableSkillConnectorSetup({
  required final AvailableSkill skill,
  required final bool pending,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ConnectorSetupButton(
    onPressed: pending ? null : () => actions.onConnectorSetup(skill),
    semanticLabel: LocaleKeys.skills_selector_semantics_connector_setup.tr(
      namedArgs: {'skill': skill.title},
    ),
  );
}

class const _UseNowButton({
  required final AvailableSkill skill,
  required final bool pending,
  required final ValueChanged<AvailableSkill> onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () {
      if (!pending) onPressed(skill);
    },
    child: TextLocale(
      pending
          ? LocaleKeys.skills_selector_using
          : LocaleKeys.skills_selector_use_now,
    ),
    size: .small,
    disabled: pending,
    semanticLabel: LocaleKeys.skills_selector_semantics_use_now.tr(
      namedArgs: {'skill': skill.title},
    ),
  );
}

class const _PreviewSkillButton({
  required final AvailableSkill skill,
  required final ValueChanged<AvailableSkill> onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => onPressed(skill),
    child: const TextLocale(LocaleKeys.skills_selector_preview),
    variant: .outlined,
    size: .small,
    semanticLabel: LocaleKeys.skills_selector_semantics_preview.tr(
      namedArgs: {'skill': skill.title},
    ),
  );
}

class const _AddSkillButton({
  required final AvailableSkill skill,
  required final bool pending,
  required final ValueChanged<AvailableSkill> onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () {
      if (!pending) onPressed(skill);
    },
    child: TextLocale(
      pending
          ? LocaleKeys.skills_selector_adding
          : LocaleKeys.skills_selector_add,
    ),
    size: .small,
    disabled: pending,
    semanticLabel: LocaleKeys.skills_selector_semantics_add.tr(
      namedArgs: {'skill': skill.title},
    ),
  );
}

class const _RecoveryButton({
  required final AvailableSkill skill,
  required final ConversationSkillContextFailure? contextFailure,
  required final ConversationSkillActionResult? actionResult,
  required final bool disabled,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      switch (_recoveryAction(contextFailure, actionResult)) {
        .connector => _ConnectorRecoveryButton(
          skill: skill,
          disabled: disabled,
          actions: actions,
        ),
        final action => _ContextRecoveryButton(
          skill: skill,
          action: action,
          disabled: disabled,
          actions: actions,
        ),
      };
}

class const _ConnectorRecoveryButton({
  required final AvailableSkill skill,
  required final bool disabled,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ConnectorSetupButton(
    onPressed: disabled ? null : () => actions.onConnectorSetup(skill),
    semanticLabel: LocaleKeys.skills_selector_semantics_connector_setup.tr(
      context: context,
      namedArgs: {'skill': skill.title},
    ),
  );
}

class const _ContextRecoveryButton({
  required final AvailableSkill skill,
  required final _RecoveryAction action,
  required final bool disabled,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _RecoveryActionButton(
    textKey: _recoveryTextKey(action),
    onPressed: disabled ? null : _recoveryCallback(action, skill, actions),
    semanticLabel: _recoverySemanticLabel(context, action, skill),
  );
}

String _recoverySemanticLabel(
  BuildContext context,
  _RecoveryAction action,
  AvailableSkill skill,
) =>
    _recoverySemanticKey(action)
        .tr(context: context, namedArgs: {'skill': skill.title});

String _recoverySemanticKey(_RecoveryAction action) => switch (action) {
  .connector => LocaleKeys.skills_selector_semantics_connector_setup,
  .refresh => LocaleKeys.skills_selector_semantics_refresh,
  .retry => LocaleKeys.skills_selector_semantics_retry,
};

String _recoveryTextKey(_RecoveryAction action) => switch (action) {
  .connector => LocaleKeys.skills_selector_connector_setup,
  .refresh => LocaleKeys.skills_selector_refresh,
  .retry => LocaleKeys.skills_selector_retry,
};

VoidCallback _recoveryCallback(
  _RecoveryAction action,
  AvailableSkill skill,
  _SelectorActions actions,
) => action == .refresh ? actions.onRefresh : () => actions.onRetry(skill);

enum _RecoveryAction { connector, refresh, retry }

_RecoveryAction _recoveryAction(
  ConversationSkillContextFailure? contextFailure,
  ConversationSkillActionResult? actionResult,
) {
  if (contextFailure == .missingConnection ||
      actionResult == .connectionMissing) {
    return .connector;
  }
  if (contextFailure == .unavailableMetadata || actionResult == .stale) {
    return .refresh;
  }

  return .retry;
}

class const _RecoveryActionButton({
  required final String textKey,
  required final VoidCallback? onPressed,
  required final String semanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => onPressed?.call(),
    child: TextLocale(textKey),
    variant: .outlined,
    size: .small,
    disabled: onPressed == null,
    semanticLabel: semanticLabel,
  );
}

class const _ConnectorSetupButton({
  required final VoidCallback? onPressed,
  final String? semanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => onPressed?.call(),
    child: const TextLocale(LocaleKeys.skills_selector_connector_setup),
    variant: .outlined,
    size: .small,
    disabled: onPressed == null,
    semanticLabel: semanticLabel,
  );
}

class const _SkillContextBadge({
  required final ConversationSkillContextStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraBadge.text(
    child: _SkillContextLabel(status: status),
    variant: switch (status) {
      .ready => .success,
      .needsContext => .warning,
      .added || .preparing || .error => .neutral,
    },
    size: .small,
  );
}

class const _SkillContextLabel({
  required final ConversationSkillContextStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(switch (status) {
    .added => LocaleKeys.skills_selector_context_added,
    .preparing => LocaleKeys.skills_selector_context_preparing,
    .ready => LocaleKeys.skills_selector_context_ready,
    .needsContext => LocaleKeys.skills_selector_context_needs_context,
    .error => LocaleKeys.skills_selector_context_error,
  });
}

class const _ConnectorConnectionBadge({
  required final ConnectorConnectionReadiness readiness,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraBadge.text(
    child: TextLocale(switch (readiness) {
      .ready => LocaleKeys.skills_selector_connection_ready,
      .missing => LocaleKeys.skills_selector_connection_missing,
      .unknown => LocaleKeys.skills_selector_connection_unknown,
    }),
    variant: switch (readiness) {
      .ready => .success,
      .missing => .warning,
      .unknown => .neutral,
    },
    size: .small,
  );
}

bool _showsRecovery(
  ConversationSkillContextStatus? status,
  ConversationSkillContextFailure? failure,
  ConversationSkillActionResult? result,
) =>
    status == .needsContext ||
    status == .error ||
    failure != null ||
    result == .stale ||
    result == .unavailable ||
    result == .connectionMissing ||
    result == .connectionUnknown;

String _contextFailureKey(ConversationSkillContextFailure failure) =>
    switch (failure) {
      .missingConnection => LocaleKeys.skills_selector_error_connection,
      .unavailableMetadata => LocaleKeys.skills_selector_error_metadata,
      .preparationFailed => LocaleKeys.skills_selector_error_preparation,
    };

String? _actionResultKey(ConversationSkillActionResult result) =>
    switch (result) {
      .added || .alreadyAdded || .inProgress || .used => null,
      .stale => LocaleKeys.skills_selector_error_stale,
      .unavailable => LocaleKeys.skills_selector_error_unavailable,
      .unauthorized => LocaleKeys.skills_selector_error_unauthorized,
      .connectionMissing => LocaleKeys.skills_selector_error_connection,
      .connectionUnknown => LocaleKeys.skills_selector_error_connection_unknown,
    };
