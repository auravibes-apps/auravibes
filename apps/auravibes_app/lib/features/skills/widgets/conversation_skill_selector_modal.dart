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
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/apply_conversation_skill_action_usecase.dart';
import 'package:auravibes_app/features/skills/widgets/skill_access_status_view.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _selectorDialogWidth = 520.0;
const _selectorLoadingHeight = 120.0;
const _skillActionSpacing = 4.0;

class const ConversationSkillSelectorModal({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerStatefulWidget {
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

  Future<void> _openCredentialSetup(AvailableSkill skill) async {
    if (skill.source == .user) {
      final definitionId = skill.credentialDefinitionId;
      if (definitionId == null) return;
      await _openUserCredentialSetup(definitionId);
    } else {
      if (!await _openAppCredentialSetup(skill)) return;
    }

    if (!mounted) return;
    _refreshSelector();
  }

  ConversationSkillContextFailure _runtimeFailure(
    SkillContextPreparationFailure failure,
  ) => switch (failure) {
    .missingCredentials => .missingCredentials,
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

  void _startCredentialSetup(AvailableSkill skill) {
    unawaited(_openCredentialSetup(skill));
  }
}

extension _ConversationSkillCredentialHandlers
    on _ConversationSkillSelectorModalState {
  Future<void> _openUserCredentialSetup(String definitionId) async {
    final _ = await ServiceConnectionCreateRoute(
      workspaceId: widget.workspaceId,
      type: 'skillCredential',
      credentialDefinitionId: definitionId,
    ).push<bool>(context);
  }

  Future<bool> _openAppCredentialSetup(AvailableSkill skill) async {
    final appSkill = ref
        .read(appSkillRegistryProvider)
        .getByIdentifier(skill.id);
    if (appSkill == null) return false;
    if (appSkill.compatibleModelProviderIds.isNotEmpty) {
      await _openModelProviderSetup();
    } else {
      await _openAppSkillCredentialSetup(skill);
    }

    return true;
  }

  Future<void> _openModelProviderSetup() async {
    final _ = await ServiceConnectionCreateRoute(
      workspaceId: widget.workspaceId,
      type: 'modelProvider',
    ).push<bool>(context);
  }

  Future<void> _openAppSkillCredentialSetup(AvailableSkill skill) async {
    final _ = await context.push<bool>(
      '/workspaces/${widget.workspaceId}/more/service-connections/new'
      '?type=appSkillCredential&appSkillId=${skill.id}',
    );
  }
}

_SelectorActions _selectorActions(_ConversationSkillSelectorModalState state) =>
    _SelectorActions(
      workspaceId: state.widget.workspaceId,
      onSearch: state._setQuery,
      onAdd: _skillActionHandler(state, .add),
      onUseNow: _skillActionHandler(state, .useNow),
      onRetry: (skill) => unawaited(state._retryContext(skill)),
      onRefresh: state._refreshSelector,
      onCredentialSetup: state._startCredentialSetup,
    );

ValueChanged<AvailableSkill> _skillActionHandler(
  _ConversationSkillSelectorModalState state,
  ConversationSkillAction action,
) =>
    (skill) => unawaited(state._apply(skill, action));

bool _refreshesSelector(ConversationSkillActionResult result) =>
    result == .added || result == .alreadyAdded || result == .used;

class const _SelectorActions({
  required final String workspaceId,
  required final ValueChanged<String> onSearch,
  required final ValueChanged<AvailableSkill> onAdd,
  required final ValueChanged<AvailableSkill> onUseNow,
  required final ValueChanged<AvailableSkill> onRetry,
  required final VoidCallback onRefresh,
  required final ValueChanged<AvailableSkill> onCredentialSetup,
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
      return const SizedBox(
        height: _selectorLoadingHeight,
        child: Center(child: AuraSpinner()),
      );
    }

    return const TextLocale(LocaleKeys.skills_selector_error);
  }
}

class const _SelectorContent({
  required final ConversationSkillSelectorState state,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _SelectorSearch(onChanged: actions.onSearch),
      _LoadedSkillSection(
        state: state,
        query: query,
        pendingSlugs: pendingSlugs,
        actionResults: actionResults,
        actions: actions,
      ),
      _AvailableSkillSection(
        skills: state.loadable,
        query: query,
        pendingSlugs: pendingSlugs,
        actionResults: actionResults,
        actions: actions,
      ),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class const _LoadedSkillSection({
  required final ConversationSkillSelectorState state,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final skills = _matchingSkills(state.loaded, query);

    return _SkillSection(
      titleKey: LocaleKeys.skills_selector_loaded_title,
      emptyKey: _emptySkillKey(query, LocaleKeys.skills_selector_loaded_empty),
      children: skills.isEmpty
          ? const []
          : [
              _LoadedSkillTiles(
                skills: skills,
                state: state,
                pendingSlugs: pendingSlugs,
                actionResults: actionResults,
                actions: actions,
              ),
            ],
    );
  }
}

class const _LoadedSkillTiles({
  required final List<AvailableSkill> skills,
  required final ConversationSkillSelectorState state,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final skill in skills)
        _LoadedSkillTile(
          skill: skill,
          contextStatus: state.contextStatusBySlug[skill.slug],
          contextFailure: state.failureBySlug[skill.slug],
          pending: pendingSlugs.contains(skill.slug),
          actionResult: actionResults[skill.slug],
          actions: actions,
        ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _AvailableSkillSection({
  required final List<AvailableSkill> skills,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final filteredSkills = _matchingSkills(skills, query);

    return _SkillSection(
      titleKey: LocaleKeys.skills_selector_available_title,
      emptyKey: _emptySkillKey(
        query,
        LocaleKeys.skills_selector_available_empty,
      ),
      children: [
        for (final skill in filteredSkills)
          _AvailableSkillTile(
            skill: skill,
            pending: pendingSlugs.contains(skill.slug),
            actionResult: actionResults[skill.slug],
            actions: actions,
          ),
      ],
    );
  }
}

String _emptySkillKey(String query, String emptyKey) =>
    query.trim().isEmpty ? emptyKey : LocaleKeys.skills_selector_search_empty;

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
    onChanged: onChanged,
  );
}

class const _SkillSection({
  required final String titleKey,
  required final String emptyKey,
  required final List<Widget> children,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: TextLocale(titleKey), style: .heading4),
      if (children.isEmpty)
        AuraText(child: TextLocale(emptyKey))
      else
        ...children,
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _LoadedSkillTile({
  required final AvailableSkill skill,
  required final ConversationSkillContextStatus? contextStatus,
  required final ConversationSkillContextFailure? contextFailure,
  required final bool pending,
  required final ConversationSkillActionResult? actionResult,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _SkillTileContents(
      skill: skill,
      actions: actions,
      pending: pending,
      contextStatus: contextStatus,
      contextFailure: contextFailure,
      actionResult: actionResult,
    ),
    variant: .ghost,
    trailing: _LoadedSkillActions(
      skill: skill,
      pending: pending,
      contextStatus: contextStatus,
      contextFailure: contextFailure,
      actionResult: actionResult,
      actions: actions,
    ),
  );
}

class const _AvailableSkillTile({
  required final AvailableSkill skill,
  required final bool pending,
  required final ConversationSkillActionResult? actionResult,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _SkillTileContents(
      skill: skill,
      actions: actions,
      pending: pending,
      actionResult: actionResult,
    ),
    variant: .ghost,
    trailing: _AvailableSkillActions(
      skill: skill,
      pending: pending,
      actionResult: actionResult,
      actions: actions,
    ),
  );
}

class const _SkillTileContents({
  required final AvailableSkill skill,
  required final _SelectorActions actions,
  required final bool pending,
  final ConversationSkillContextStatus? contextStatus,
  final ConversationSkillContextFailure? contextFailure,
  final ConversationSkillActionResult? actionResult,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _SkillTileIdentity(skill: skill, contextStatus: contextStatus),
      _SkillTileAccessStatus(skill: skill, actions: actions, pending: pending),
      _SkillTileMessages(
        description: skill.description,
        contextFailure: contextFailure,
        actionResult: actionResult,
      ),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
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
  );
}

class const _SkillTileIdentity({
  required final AvailableSkill skill,
  final ConversationSkillContextStatus? contextStatus,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: Text(skill.title)),
      _SkillCredentialBadge(readiness: skill.credentialReadiness),
      if (contextStatus case final status?) _SkillContextBadge(status: status),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _SkillTileMessages({
  required final String description,
  final ConversationSkillContextFailure? contextFailure,
  final ConversationSkillActionResult? actionResult,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final result = actionResult;
    final resultKey = result == null ? null : _actionResultKey(result);

    return AuraColumn(
      children: [
        AuraText(child: Text(description)),
        if (contextFailure case final failure?)
          _SkillContextFailureMessage(failure: failure),
        if (resultKey != null) TextLocale(resultKey),
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
  Widget build(BuildContext context) => TextLocale(_contextFailureKey(failure));
}

class const _LoadedSkillActions({
  required final AvailableSkill skill,
  required final bool pending,
  required final ConversationSkillContextStatus? contextStatus,
  required final ConversationSkillContextFailure? contextFailure,
  required final ConversationSkillActionResult? actionResult,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: _skillActionSpacing,
    runSpacing: _skillActionSpacing,
    children: [
      _UseNowButton(
        skill: skill,
        pending: pending,
        onPressed: actions.onUseNow,
      ),
      if (_showsRecovery(contextStatus, contextFailure, actionResult))
        _RecoveryButton(
          skill: skill,
          contextFailure: contextFailure,
          actionResult: actionResult,
          disabled: pending,
          actions: actions,
        ),
    ],
  );
}

class const _AvailableSkillActions({
  required final AvailableSkill skill,
  required final bool pending,
  required final ConversationSkillActionResult? actionResult,
  required final _SelectorActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: _skillActionSpacing,
    children: [
      _AddSkillButton(skill: skill, pending: pending, onPressed: actions.onAdd),
      if (skill.credentialReadiness == .missing ||
          actionResult == .credentialsMissing)
        _CredentialSetupButton(
          onPressed: pending ? null : () => actions.onCredentialSetup(skill),
        ),
    ],
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
  Widget build(BuildContext context) {
    final action = _recoveryAction(contextFailure, actionResult);
    if (action == .credentials) {
      return _CredentialSetupButton(
        onPressed: disabled ? null : () => actions.onCredentialSetup(skill),
      );
    }

    return _RecoveryActionButton(
      textKey: _recoveryTextKey(action),
      onPressed: disabled ? null : _recoveryCallback(action, skill, actions),
    );
  }
}

String _recoveryTextKey(_RecoveryAction action) => switch (action) {
  .credentials => LocaleKeys.skills_selector_credential_setup,
  .refresh => LocaleKeys.skills_selector_refresh,
  .retry => LocaleKeys.skills_selector_retry,
};

VoidCallback _recoveryCallback(
  _RecoveryAction action,
  AvailableSkill skill,
  _SelectorActions actions,
) => action == .refresh ? actions.onRefresh : () => actions.onRetry(skill);

enum _RecoveryAction { credentials, refresh, retry }

_RecoveryAction _recoveryAction(
  ConversationSkillContextFailure? contextFailure,
  ConversationSkillActionResult? actionResult,
) {
  if (contextFailure == .missingCredentials ||
      actionResult == .credentialsMissing) {
    return .credentials;
  }
  if (contextFailure == .unavailableMetadata || actionResult == .stale) {
    return .refresh;
  }

  return .retry;
}

class const _RecoveryActionButton({
  required final String textKey,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => onPressed?.call(),
    child: TextLocale(textKey),
    variant: .outlined,
    size: .small,
    disabled: onPressed == null,
  );
}

class const _CredentialSetupButton({required final VoidCallback? onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => onPressed?.call(),
    child: const TextLocale(LocaleKeys.skills_selector_credential_setup),
    variant: .outlined,
    size: .small,
    disabled: onPressed == null,
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

class const _SkillCredentialBadge({
  required final SkillCredentialReadiness readiness,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraBadge.text(
    child: TextLocale(switch (readiness) {
      .ready => LocaleKeys.skills_selector_credentials_ready,
      .missing => LocaleKeys.skills_selector_credentials_missing,
      .unknown => LocaleKeys.skills_selector_credentials_unknown,
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
    result == .credentialsMissing ||
    result == .credentialsUnknown;

String _contextFailureKey(ConversationSkillContextFailure failure) =>
    switch (failure) {
      .missingCredentials => LocaleKeys.skills_selector_error_credentials,
      .unavailableMetadata => LocaleKeys.skills_selector_error_metadata,
      .preparationFailed => LocaleKeys.skills_selector_error_preparation,
    };

String? _actionResultKey(ConversationSkillActionResult result) =>
    switch (result) {
      .added || .alreadyAdded || .inProgress || .used => null,
      .stale => LocaleKeys.skills_selector_error_stale,
      .unavailable => LocaleKeys.skills_selector_error_unavailable,
      .unauthorized => LocaleKeys.skills_selector_error_unauthorized,
      .credentialsMissing => LocaleKeys.skills_selector_error_credentials,
      .credentialsUnknown =>
        LocaleKeys.skills_selector_error_credentials_unknown,
    };
