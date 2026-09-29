import 'dart:async';

import 'package:auravibes_app/features/chats/models/skill_context_preparation_failure.dart';
import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/prepare_conversation_skill_context_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/models/conversation_skill_action.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/apply_conversation_skill_action_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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

    return AuraAlertDialog(
      title: const TextLocale(LocaleKeys.skills_selector_title),
      message: SizedBox(
        width: 520,
        child: _SelectorBody(
          selectorAsync: selectorAsync,
          query: _query,
          pendingSlugs: _pendingSlugs,
          actionResults: _actionResults,
          onSearch: (query) => setState(() => _query = query),
          onAdd: (skill) => unawaited(_apply(skill, .add)),
          onUseNow: (skill) => unawaited(_apply(skill, .useNow)),
          onRetry: (skill) => unawaited(_retryContext(skill)),
          onRefresh: _refreshSelector,
          onCredentialSetup: (skill) {
            final _ = _openCredentialSetup(skill);
          },
        ),
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_close),
    );
  }

  Future<void> _apply(
    AvailableSkill skill,
    ConversationSkillAction action,
  ) async {
    if (!_pendingSlugs.add(skill.slug)) return;
    setState(() {
      final _ = _actionResults.remove(skill.slug);
    });

    final ConversationSkillActionResult result;
    try {
      result = await ref
          .read(applyConversationSkillActionUsecaseProvider)
          .call(
            workspaceId: widget.workspaceId,
            conversationId: widget.conversationId,
            slug: skill.slug,
            action: action,
            userRequestForSkill: (title) => LocaleKeys
                .skills_selector_use_now_request
                .tr(namedArgs: {'skill': title}),
          );
    } on Object {
      if (!mounted) return;
      setState(() {
        final _ = _pendingSlugs.remove(skill.slug);
        _actionResults[skill.slug] = .unavailable;
      });

      return;
    }

    if (!mounted) return;
    setState(() {
      final _ = _pendingSlugs.remove(skill.slug);
      _actionResults[skill.slug] = result;
    });
    if (result == .added || result == .alreadyAdded || result == .used) {
      _invalidateSelector();
    }
    if (result == .used) {
      final _ = Navigator.of(context).maybePop();
    }
  }

  Future<void> _retryContext(AvailableSkill _) async {
    final runtime = ref.read(conversationSkillContextRuntimeProvider.notifier);
    final generation = runtime.begin(widget.conversationId);
    try {
      final result = await ref
          .read(prepareConversationSkillContextUsecaseProvider)
          .call(
            workspaceId: widget.workspaceId,
            conversationId: widget.conversationId,
          );
      final failure = result.failure;
      if (failure == null) {
        runtime.ready(
          widget.conversationId,
          generation,
          selectedRevisions: result.selectedRevisions,
          canActivate: result.canActivate,
        );
      } else {
        runtime.errorWithCause(
          widget.conversationId,
          generation,
          _runtimeFailure(failure),
        );
      }
    } on Object {
      runtime.errorWithCause(
        widget.conversationId,
        generation,
        .preparationFailed,
      );
    }
    if (!mounted) return;
    _invalidateSelector();
  }

  void _refreshSelector() {
    ref
        .read(conversationSkillContextRuntimeProvider.notifier)
        .markNeedsContext(widget.conversationId);
    _invalidateSelector();
  }

  Future<void> _openCredentialSetup(AvailableSkill skill) async {
    if (skill.source == .user) {
      final definitionId = skill.credentialDefinitionId;
      if (definitionId == null) return;
      final _ = await ServiceConnectionCreateRoute(
        workspaceId: widget.workspaceId,
        type: 'skillCredential',
        credentialDefinitionId: definitionId,
      ).push<bool>(context);
    } else {
      final appSkill = ref
          .read(appSkillRegistryProvider)
          .getByIdentifier(skill.id);
      if (appSkill == null) return;
      if (appSkill.compatibleModelProviderIds.isNotEmpty) {
        final _ = await ServiceConnectionCreateRoute(
          workspaceId: widget.workspaceId,
          type: 'modelProvider',
        ).push<bool>(context);
      } else {
        final _ = await context.push<bool>(
          '/workspaces/${widget.workspaceId}/more/service-connections/new'
          '?type=appSkillCredential&appSkillId=${skill.id}',
        );
      }
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
}

class const _SelectorBody({
  required final AsyncValue<ConversationSkillSelectorState> selectorAsync,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final ValueChanged<String> onSearch,
  required final ValueChanged<AvailableSkill> onAdd,
  required final ValueChanged<AvailableSkill> onUseNow,
  required final ValueChanged<AvailableSkill> onRetry,
  required final VoidCallback onRefresh,
  required final ValueChanged<AvailableSkill> onCredentialSetup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (selectorAsync) {
    AsyncData(:final value) => _SelectorContent(
      state: value,
      query: query,
      pendingSlugs: pendingSlugs,
      actionResults: actionResults,
      onSearch: onSearch,
      onAdd: onAdd,
      onUseNow: onUseNow,
      onRetry: onRetry,
      onRefresh: onRefresh,
      onCredentialSetup: onCredentialSetup,
    ),
    AsyncLoading(value: final value?, hasValue: true) => _SelectorContent(
      state: value,
      query: query,
      pendingSlugs: pendingSlugs,
      actionResults: actionResults,
      onSearch: onSearch,
      onAdd: onAdd,
      onUseNow: onUseNow,
      onRetry: onRetry,
      onRefresh: onRefresh,
      onCredentialSetup: onCredentialSetup,
    ),
    AsyncLoading() => const SizedBox(
      height: 120,
      child: Center(child: AuraSpinner()),
    ),
    AsyncError() => const TextLocale(LocaleKeys.skills_selector_error),
  };
}

class const _SelectorContent({
  required final ConversationSkillSelectorState state,
  required final String query,
  required final Set<String> pendingSlugs,
  required final Map<String, ConversationSkillActionResult> actionResults,
  required final ValueChanged<String> onSearch,
  required final ValueChanged<AvailableSkill> onAdd,
  required final ValueChanged<AvailableSkill> onUseNow,
  required final ValueChanged<AvailableSkill> onRetry,
  required final VoidCallback onRefresh,
  required final ValueChanged<AvailableSkill> onCredentialSetup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loaded = _matchingSkills(state.loaded, query);
    final available = _matchingSkills(state.loadable, query);

    return SingleChildScrollView(
      child: AuraColumn(
        children: [
          _SelectorSearch(onChanged: onSearch),
          _SkillSection(
            titleKey: LocaleKeys.skills_selector_loaded_title,
            emptyKey: query.trim().isEmpty
                ? LocaleKeys.skills_selector_loaded_empty
                : LocaleKeys.skills_selector_search_empty,
            children: [
              for (final skill in loaded)
                _LoadedSkillTile(
                  skill: skill,
                  contextStatus: state.contextStatusBySlug[skill.slug],
                  contextFailure: state.failureBySlug[skill.slug],
                  pending: pendingSlugs.contains(skill.slug),
                  actionResult: actionResults[skill.slug],
                  onUseNow: onUseNow,
                  onRetry: onRetry,
                  onRefresh: onRefresh,
                  onCredentialSetup: onCredentialSetup,
                ),
            ],
          ),
          _SkillSection(
            titleKey: LocaleKeys.skills_selector_available_title,
            emptyKey: query.trim().isEmpty
                ? LocaleKeys.skills_selector_available_empty
                : LocaleKeys.skills_selector_search_empty,
            children: [
              for (final skill in available)
                _AvailableSkillTile(
                  skill: skill,
                  pending: pendingSlugs.contains(skill.slug),
                  actionResult: actionResults[skill.slug],
                  onAdd: onAdd,
                  onCredentialSetup: onCredentialSetup,
                ),
            ],
          ),
        ],
        spacing: .md,
        crossAxisAlignment: .start,
      ),
    );
  }
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
  required final ValueChanged<AvailableSkill> onUseNow,
  required final ValueChanged<AvailableSkill> onRetry,
  required final VoidCallback onRefresh,
  required final ValueChanged<AvailableSkill> onCredentialSetup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = contextStatus;
    final failure = contextFailure;
    final result = actionResult;
    final resultKey = result == null ? null : _actionResultKey(result);

    return AuraTile(
      child: AuraColumn(
        children: [
          AuraText(child: Text(skill.title)),
          _SkillCredentialBadge(readiness: skill.credentialReadiness),
          if (status != null) _SkillContextBadge(status: status),
          AuraText(child: Text(skill.description)),
          if (failure != null) TextLocale(_contextFailureKey(failure)),
          if (resultKey != null) TextLocale(resultKey),
        ],
        spacing: .xs,
        crossAxisAlignment: .start,
      ),
      variant: .ghost,
      trailing: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          AuraButton(
            onPressed: () {
              if (!pending) onUseNow(skill);
            },
            child: TextLocale(
              pending
                  ? LocaleKeys.skills_selector_using
                  : LocaleKeys.skills_selector_use_now,
            ),
            size: .small,
            disabled: pending,
          ),
          if (_showsRecovery(status, failure, result))
            _RecoveryButton(
              skill: skill,
              contextFailure: failure,
              actionResult: result,
              disabled: pending,
              onRetry: onRetry,
              onRefresh: onRefresh,
              onCredentialSetup: onCredentialSetup,
            ),
        ],
      ),
    );
  }
}

class const _AvailableSkillTile({
  required final AvailableSkill skill,
  required final bool pending,
  required final ConversationSkillActionResult? actionResult,
  required final ValueChanged<AvailableSkill> onAdd,
  required final ValueChanged<AvailableSkill> onCredentialSetup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final result = actionResult;
    final resultKey = result == null ? null : _actionResultKey(result);

    return AuraTile(
      child: AuraColumn(
        children: [
          AuraText(child: Text(skill.title)),
          _SkillCredentialBadge(readiness: skill.credentialReadiness),
          AuraText(child: Text(skill.description)),
          if (resultKey != null) TextLocale(resultKey),
        ],
        spacing: .xs,
        crossAxisAlignment: .start,
      ),
      variant: .ghost,
      trailing: Wrap(
        spacing: 4,
        children: [
          AuraButton(
            onPressed: () {
              if (!pending) onAdd(skill);
            },
            child: TextLocale(
              pending
                  ? LocaleKeys.skills_selector_adding
                  : LocaleKeys.skills_selector_add,
            ),
            size: .small,
            disabled: pending,
          ),
          if (skill.credentialReadiness == .missing ||
              actionResult == .credentialsMissing)
            _CredentialSetupButton(
              onPressed: pending ? null : () => onCredentialSetup(skill),
            ),
        ],
      ),
    );
  }
}

class const _RecoveryButton({
  required final AvailableSkill skill,
  required final ConversationSkillContextFailure? contextFailure,
  required final ConversationSkillActionResult? actionResult,
  required final bool disabled,
  required final ValueChanged<AvailableSkill> onRetry,
  required final VoidCallback onRefresh,
  required final ValueChanged<AvailableSkill> onCredentialSetup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final needsCredentialSetup =
        contextFailure == .missingCredentials ||
        actionResult == .credentialsMissing;
    final refresh =
        contextFailure == .unavailableMetadata || actionResult == .stale;

    if (needsCredentialSetup) {
      return _CredentialSetupButton(
        onPressed: disabled ? null : () => onCredentialSetup(skill),
      );
    }

    final onPressed = refresh ? onRefresh : () => onRetry(skill);

    return AuraButton(
      onPressed: () {
        if (!disabled) onPressed();
      },
      child: TextLocale(
        refresh
            ? LocaleKeys.skills_selector_refresh
            : LocaleKeys.skills_selector_retry,
      ),
      variant: .outlined,
      size: .small,
      disabled: disabled,
    );
  }
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
    child: TextLocale(switch (status) {
      .added => LocaleKeys.skills_selector_context_added,
      .preparing => LocaleKeys.skills_selector_context_preparing,
      .ready => LocaleKeys.skills_selector_context_ready,
      .needsContext => LocaleKeys.skills_selector_context_needs_context,
      .error => LocaleKeys.skills_selector_context_error,
    }),
    variant: switch (status) {
      .ready => .success,
      .needsContext => .warning,
      .added || .preparing || .error => .neutral,
    },
    size: .small,
  );
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
