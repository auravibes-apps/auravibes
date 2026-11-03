import 'dart:async';

import 'package:auravibes_app/domain/exceptions/scoped_verification_settings_exception.dart';
import 'package:auravibes_app/features/chats/providers/scoped_verification_provider.dart';
import 'package:auravibes_app/features/settings/models/scoped_verification_form_draft.dart';
import 'package:auravibes_app/features/settings/providers/scoped_verification_settings_provider.dart';
import 'package:auravibes_app/features/settings/services/scoped_verification_configuration.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ScopedVerificationSection({
  required final String workspaceId,
  required final DraftExitGuard guard,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ScopedVerificationSection> createState() =>
      _ScopedVerificationSectionState();
}

class _ScopedVerificationSectionState
    extends ConsumerState<ScopedVerificationSection> {
  final GlobalKey _errorAnchor = .new();
  ScopedVerificationFormDraft _draft = .new(.new());
  ScopedVerificationSettings? _latest;
  String _lastFingerprint = '';
  String? _error;
  String? _notice;
  bool _loaded = false;
  bool _saving = false;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    final initial = ref
        .read(scopedVerificationSettingsProvider(widget.workspaceId))
        .asData
        ?.value;
    if (initial != null) {
      _replace(initial);
    } else {
      _lastFingerprint = _draft.fingerprint;
      _draft.listen(_edited);
    }
    widget.guard.bind(
      readers: (isDirty: () => _draft.isDirty, isSaving: () => _saving),
    );
  }

  @override
  void dispose() {
    widget.guard.unbind();
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(
      workspaceSessionForRouteProvider(widget.workspaceId),
    );
    final settings = ref.watch(
      scopedVerificationSettingsProvider(widget.workspaceId),
    );
    final cloud = session.asData?.value.cloud != null;
    final tools = _watchVerificationTools(ref, widget.workspaceId, cloud);

    return _VerificationCard(
      state: this,
      cloud: cloud,
      loadError: session.hasError || settings.hasError || tools.hasError,
      tools: tools.asData?.value ?? const [],
    );
  }

  void _replace(ScopedVerificationSettings settings) {
    _draft.dispose();
    _draft = .new(settings);
    _latest = settings;
    _loaded = true;
    _lastFingerprint = _draft.fingerprint;
    _draft.listen(_edited);
  }

  void _edited() {
    if (!mounted || _draft.fingerprint == _lastFingerprint) return;
    _lastFingerprint = _draft.fingerprint;
    setState(() {
      _error = null;
      _notice = null;
    });
    _publishGuard();
  }

  void _change(VoidCallback update) {
    update();
    _edited();
  }

  void _publishGuard() {
    widget.guard.releaseApproval(restoreFocus: false);
    widget.guard.update(isDirty: _draft.isDirty, isSaving: _saving);
  }

  void _receiveSettings(ScopedVerificationSettings settings) {
    _latest = settings;
    if (!_draft.isDirty && !_saving) {
      setState(() => _replace(settings));
      _publishGuard();
    }
  }

  void _update(VoidCallback callback) => setState(callback);
}

AsyncValue<List<ScopedVerificationToolOption>> _watchVerificationTools(
  WidgetRef ref,
  String workspaceId,
  bool cloud,
) => cloud
    ? const AsyncData<List<ScopedVerificationToolOption>>([])
    : ref.watch(scopedVerificationToolsProvider(workspaceId));

void _listenForVerificationSettings(
  WidgetRef ref,
  _ScopedVerificationSectionState state,
  String workspaceId,
) {
  ref.listen(scopedVerificationSettingsProvider(workspaceId), (_, next) {
    final value = next.asData?.value;
    if (value != null) state._receiveSettings(value);
  });
}

extension _ScopedVerificationSectionStateActions
    on _ScopedVerificationSectionState {
  void _addCheck() {
    if (_draft.checks.length >= ScopedVerificationLimits.maxChecks) return;
    var number = _draft.checks.length + 1;
    while (_draft.checks.any((check) => check.id.text == 'check-$number')) {
      number++;
    }
    final check = ScopedVerificationCheckDraft.blank('check-$number')
      ..listen(_edited);
    _change(() => _draft.checks.add(check));
  }

  void _removeCheck(ScopedVerificationCheckDraft check) => _change(() {
    if (_draft.checks.remove(check)) check.dispose();
  });

  void _selectRunner(String? id, List<ScopedVerificationToolOption> tools) {
    final tool = tools.where((option) => option.id == id).firstOrNull;
    _change(() => _applyRunnerSelection(this, tool));
  }

  void _showError(String key) {
    _update(() => _error = key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final errorContext = _errorAnchor.currentContext;
      if (mounted && errorContext != null) {
        Scrollable.ensureVisible(errorContext);
      }
    });
  }

  void _discard() {
    final latest = _latest;
    if (latest == null) return;
    _update(() {
      _replace(latest);
      _error = null;
      _notice = null;
    });
    _publishGuard();
  }

  void _toggleAdvanced() {
    _update(() => _advanced = !_advanced);
  }

  Future<void> _save() async {
    if (_saving || !_loaded || !_draft.isDirty) return;
    final pending = _readPendingSettings(this);
    if (pending == null) return;
    _beginSaving();
    try {
      await _persistDraft(pending);
    } on ScopedVerificationSettingsException catch (error) {
      _showSaveFailure(this, error.localeKey);
    } on Object {
      _showSaveFailure(this, LocaleKeys.verification_errors_save_failed);
    } finally {
      _finishSaving();
    }
  }

  void _beginSaving() {
    _update(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    _publishGuard();
  }

  Future<void> _persistDraft(ScopedVerificationSettings pending) async {
    final saved = await _savePendingSettings(ref, widget.workspaceId, pending);
    if (!mounted) return;
    _update(() {
      _replace(saved);
      _notice = LocaleKeys.verification_saved;
    });
  }

  void _finishSaving() {
    if (!mounted) return;
    _update(() => _saving = false);
    _publishGuard();
  }
}

void _showSaveFailure(_ScopedVerificationSectionState state, String localeKey) {
  if (state.mounted) {
    state._showError(localeKey);
  }
}

void _applyRunnerSelection(
  _ScopedVerificationSectionState state,
  ScopedVerificationToolOption? tool,
) {
  final draft = state._draft;
  final runnerToolId = tool?.id ?? '';
  final mcpServerId = tool?.serverId ?? '';
  final serverChanged = draft.mcpServerId != mcpServerId;
  draft
    ..editToolIds.removeWhere((id) => serverChanged || id == runnerToolId)
    ..runnerToolId = runnerToolId
    ..mcpServerId = mcpServerId;
}

ScopedVerificationSettings? _readPendingSettings(
  _ScopedVerificationSectionState state,
) {
  try {
    return state._draft.read();
  } on FormatException {
    state
      .._advanced = true
      .._showError(LocaleKeys.verification_errors_invalid);

    return null;
  }
}

Future<ScopedVerificationSettings> _savePendingSettings(
  WidgetRef ref,
  String workspaceId,
  ScopedVerificationSettings settings,
) async {
  final saveSettings = ref.read(
    saveScopedVerificationSettingsUsecaseProvider(workspaceId),
  );
  final repository = ref.read(workspaceVerificationRepositoryProvider);

  await saveSettings(workspaceId: workspaceId, settings: settings);

  return await repository.getSettings(workspaceId);
}

class const _VerificationCard({
  required final _ScopedVerificationSectionState state,
  required final bool cloud,
  required final bool loadError,
  required final List<ScopedVerificationToolOption> tools,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listenForVerificationSettings(ref, state, state.widget.workspaceId);

    return AuraCard(
      child: AuraColumn(
        children: [
          _VerificationCardHeader(
            state: state,
            cloud: cloud,
            loadError: loadError,
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.verification_subtitle),
            style: .bodySmall,
          ),
          if (cloud)
            const TextLocale(LocaleKeys.verification_cloud_unavailable)
          else if (loadError || state._loaded)
            _VerificationCardContent(
              state: state,
              loadError: loadError,
              tools: tools,
            ),
        ],
        crossAxisAlignment: .stretch,
      ),
    );
  }
}

class const _VerificationCardHeader({
  required final _ScopedVerificationSectionState state,
  required final bool cloud,
  required final bool loadError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraWrap(
    children: [
      const AuraText(
        child: TextLocale(LocaleKeys.verification_title),
        style: .heading6,
      ),
      _VerificationStatus(state: state, cloud: cloud, loadError: loadError),
      if (state._draft.isDirty)
        const TextLocale(LocaleKeys.verification_unsaved),
    ],
  );
}

class const _VerificationStatus({
  required final _ScopedVerificationSectionState state,
  required final bool cloud,
  required final bool loadError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (cloud || loadError && !state._loaded) {
      return const _VerificationUnavailableStatus();
    }
    if (state._saving) {
      return const _VerificationSavingStatus();
    }
    if (!state._loaded) {
      return const _VerificationLoadingStatus();
    }
    if (state._draft.enabled) {
      return const _VerificationEnabledStatus();
    }

    return const _VerificationDisabledStatus();
  }
}

class const _VerificationUnavailableStatus() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.verification_unavailable),
    style: .bodySmall,
  );
}

class const _VerificationSavingStatus() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.verification_saving),
    style: .bodySmall,
  );
}

class const _VerificationLoadingStatus() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.verification_loading),
    style: .bodySmall,
  );
}

class const _VerificationEnabledStatus() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.verification_enabled),
    style: .bodySmall,
  );
}

class const _VerificationDisabledStatus() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.verification_disabled),
    style: .bodySmall,
  );
}

class const _VerificationCardContent({
  required final _ScopedVerificationSectionState state,
  required final bool loadError,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (loadError)
        _VerificationLoadError(workspaceId: state.widget.workspaceId),
      if (state._loaded) _VerificationAccordion(state: state, tools: tools),
    ],
    crossAxisAlignment: .stretch,
  );
}

class const _VerificationAccordion({
  required final _ScopedVerificationSectionState state,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExcludeFocus(
    excluding: state._saving,
    child: IgnorePointer(
      ignoring: state._saving,
      child: AuraAccordion(
        items: [
          AuraAccordionItem(
            title: LocaleKeys.verification_configure.tr(),
            child: _VerificationForm(state: state, tools: tools),
          ),
        ],
      ),
    ),
  );
}

class const _VerificationLoadError({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraColumn(
    children: [
      const TextLocale(LocaleKeys.verification_errors_load_failed),
      AuraButton(
        onPressed: () => _retry(ref),
        child: const TextLocale(LocaleKeys.route_state_retry),
        variant: .ghost,
      ),
    ],
    crossAxisAlignment: .start,
  );

  void _retry(WidgetRef ref) {
    ref
      ..invalidate(scopedVerificationSettingsProvider(workspaceId))
      ..invalidate(scopedVerificationToolsProvider(workspaceId));
  }
}

class const _VerificationForm({
  required final _ScopedVerificationSectionState state,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    child: AuraColumn(
      children: [
        _VerificationRunnerFields(state: state, tools: tools),
        _VerificationEditTools(state: state, tools: tools),
        _VerificationCheckList(state: state),
        _VerificationAdvancedFields(state: state),
        if (state._error case final String error)
          Semantics(
            key: state._errorAnchor,
            child: _VerificationErrorText(localeKey: error),
            liveRegion: true,
          ),
        if (state._notice != null)
          Semantics(
            child: const TextLocale(LocaleKeys.verification_saved),
            liveRegion: true,
          ),
        _VerificationFormActions(state: state),
      ],
    ),
  );
}

class const _VerificationRunnerFields({
  required final _ScopedVerificationSectionState state,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale(LocaleKeys.verification_runner_requirement),
      _VerificationEnableTile(state: state),
      _VerificationRunnerSelector(state: state, tools: tools),
      _VerificationWorkspaceRoot(state: state),
    ],
  );
}

class const _VerificationEnableTile({
  required final _ScopedVerificationSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: state._draft.enabled,
    onChanged: (value) => state._change(() => state._draft.enabled = value),
    title: const TextLocale(LocaleKeys.verification_enable),
    key: const ValueKey('verification-enable'),
    subtitle: const TextLocale(LocaleKeys.verification_enable_hint),
    semanticLabel: LocaleKeys.verification_enable.tr(),
  );
}

class const _VerificationRunnerSelector({
  required final _ScopedVerificationSectionState state,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [_VerificationRunnerOptions(state: state, tools: tools)],
  );
}

class const _VerificationRunnerOptions({
  required final _ScopedVerificationSectionState state,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final runners = _unattendedVerificationTools(tools);
    final selectedId = state._draft.runnerToolId;

    return AuraColumn(
      children: [
        if (runners.isEmpty)
          const TextLocale(LocaleKeys.verification_no_runner),
        _VerificationRunnerDropdown(
          state: state,
          runners: runners,
          selectedId: selectedId,
        ),
      ],
    );
  }
}

List<ScopedVerificationToolOption> _unattendedVerificationTools(
  List<ScopedVerificationToolOption> tools,
) => tools.where((tool) => tool.canRunUnattended).toList();

class const _VerificationRunnerDropdown({
  required final _ScopedVerificationSectionState state,
  required final List<ScopedVerificationToolOption> runners,
  required final String selectedId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [
      for (final tool in runners)
        AuraDropdownOption(value: tool.id, child: Text(tool.label)),
    ],
    value: _selectedVerificationRunner(runners, selectedId),
    onChanged: (id) => state._selectRunner(id, runners),
    label: const TextLocale(LocaleKeys.verification_runner),
    hint: const TextLocale(LocaleKeys.verification_runner_hint),
    semanticLabel: LocaleKeys.verification_runner.tr(),
  );
}

String? _selectedVerificationRunner(
  List<ScopedVerificationToolOption> runners,
  String selectedId,
) => runners.any((tool) => tool.id == selectedId) ? selectedId : null;

class const _VerificationWorkspaceRoot({
  required final _ScopedVerificationSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _VerificationInput(
    controller: state._draft.root,
    label: const TextLocale(LocaleKeys.verification_root),
    semanticLabel: LocaleKeys.verification_root.tr(),
    identifier: 'verification-root',
    hint: const TextLocale(LocaleKeys.verification_root_hint),
  );
}

class const _VerificationCheckList({
  required final _ScopedVerificationSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = state._draft;

    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.verification_checks),
          style: .heading6,
        ),
        for (final check in draft.checks)
          _VerificationCheckFields(
            state: state,
            check: check,
            key: ValueKey(check),
          ),
        AuraButton(
          onPressed: state._addCheck,
          child: const TextLocale(LocaleKeys.verification_add_check),
          variant: .ghost,
          disabled: draft.checks.length >= ScopedVerificationLimits.maxChecks,
        ),
      ],
    );
  }
}

class const _VerificationAdvancedFields({
  required final _ScopedVerificationSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      Semantics(
        child: AuraButton(
          onPressed: state._toggleAdvanced,
          child: const TextLocale(LocaleKeys.verification_advanced),
          variant: .ghost,
        ),
        expanded: state._advanced,
      ),
      if (state._advanced) _VerificationLimits(draft: state._draft),
    ],
  );
}

class const _VerificationFormActions({
  required final _ScopedVerificationSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDisabled = !state._draft.isDirty || state._saving;

    return AuraWrap(
      children: [
        _SaveVerificationButton(state: state, disabled: isDisabled),
        _DiscardVerificationButton(state: state, disabled: isDisabled),
      ],
    );
  }
}

class const _SaveVerificationButton({
  required final _ScopedVerificationSectionState state,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(state._save()),
    child: const TextLocale(LocaleKeys.verification_save),
    key: const ValueKey('verification-save'),
    isLoading: state._saving,
    disabled: disabled,
  );
}

class const _DiscardVerificationButton({
  required final _ScopedVerificationSectionState state,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: state._discard,
    child: const TextLocale(LocaleKeys.verification_discard),
    key: const ValueKey('verification-discard'),
    variant: .ghost,
    disabled: disabled,
  );
}

class const _VerificationEditTools({
  required final _ScopedVerificationSectionState state,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = state._draft;
    final edits = _availableEditTools(tools, draft);
    final eligible = edits.map((tool) => tool.id).toSet();

    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.verification_edit_tools),
          style: .heading6,
        ),
        const TextLocale(LocaleKeys.verification_edit_tools_hint),
        if (draft.editToolIds.any((id) => !eligible.contains(id))) ...[
          const TextLocale(LocaleKeys.verification_missing_selections),
          AuraButton(
            onPressed: () =>
                _clearMissingEditSelections(state, draft, eligible),
            child: const TextLocale(LocaleKeys.verification_clear_missing),
            variant: .ghost,
          ),
        ],
        for (final tool in edits)
          _VerificationEditToolToggle(state: state, draft: draft, tool: tool),
      ],
      crossAxisAlignment: .stretch,
    );
  }
}

List<ScopedVerificationToolOption> _availableEditTools(
  List<ScopedVerificationToolOption> tools,
  ScopedVerificationFormDraft draft,
) => tools
    .where(
      (tool) =>
          tool.serverId == draft.mcpServerId && tool.id != draft.runnerToolId,
    )
    .toList();

void _clearMissingEditSelections(
  _ScopedVerificationSectionState state,
  ScopedVerificationFormDraft draft,
  Set<String> eligibleIds,
) => state._change(
  () => draft.editToolIds.removeWhere((id) => !eligibleIds.contains(id)),
);

class const _VerificationEditToolToggle({
  required final _ScopedVerificationSectionState state,
  required final ScopedVerificationFormDraft draft,
  required final ScopedVerificationToolOption tool,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: draft.editToolIds.contains(tool.id),
    onChanged: (value) =>
        _toggleVerificationEditTool(state, draft, tool, value),
    title: Text(tool.label),
    semanticLabel: tool.label,
  );
}

void _toggleVerificationEditTool(
  _ScopedVerificationSectionState state,
  ScopedVerificationFormDraft draft,
  ScopedVerificationToolOption tool,
  bool value,
) => state._change(() {
  final _ = value
      ? draft.editToolIds.add(tool.id)
      : draft.editToolIds.remove(tool.id);
});

class const _VerificationCheckFields({
  required final _ScopedVerificationSectionState state,
  required final ScopedVerificationCheckDraft check,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final checkIdentity = identityHashCode(check);

    return AuraColumn(
      children: [
        _VerificationCheckIdInput(check: check, checkIdentity: checkIdentity),
        _VerificationCheckExecutableInput(
          check: check,
          checkIdentity: checkIdentity,
        ),
        _VerificationCheckArgumentsInput(
          check: check,
          checkIdentity: checkIdentity,
        ),
        _VerificationCheckSuffixesInput(
          check: check,
          checkIdentity: checkIdentity,
        ),
        AuraButton(
          onPressed: () => state._removeCheck(check),
          child: const TextLocale(LocaleKeys.verification_remove_check),
          variant: .ghost,
        ),
      ],
      crossAxisAlignment: .stretch,
    );
  }
}

class const _VerificationCheckIdInput({
  required final ScopedVerificationCheckDraft check,
  required final int checkIdentity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _VerificationInput(
    controller: check.id,
    label: const TextLocale(LocaleKeys.verification_check_id),
    semanticLabel: LocaleKeys.verification_check_id.tr(),
    identifier: 'verification-check-$checkIdentity',
  );
}

class const _VerificationCheckExecutableInput({
  required final ScopedVerificationCheckDraft check,
  required final int checkIdentity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _VerificationInput(
    controller: check.executable,
    label: const TextLocale(LocaleKeys.verification_executable),
    semanticLabel: LocaleKeys.verification_executable.tr(),
    identifier: 'verification-executable-$checkIdentity',
  );
}

class const _VerificationCheckArgumentsInput({
  required final ScopedVerificationCheckDraft check,
  required final int checkIdentity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _VerificationInput(
    controller: check.arguments,
    label: const TextLocale(LocaleKeys.verification_arguments),
    semanticLabel: LocaleKeys.verification_arguments.tr(),
    identifier: 'verification-arguments-$checkIdentity',
    hint: const TextLocale(LocaleKeys.verification_arguments_hint),
    maxLines: 3,
  );
}

class const _VerificationCheckSuffixesInput({
  required final ScopedVerificationCheckDraft check,
  required final int checkIdentity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _VerificationInput(
    controller: check.suffixes,
    label: const TextLocale(LocaleKeys.verification_suffixes),
    semanticLabel: LocaleKeys.verification_suffixes.tr(),
    identifier: 'verification-suffixes-$checkIdentity',
    hint: const TextLocale(LocaleKeys.verification_suffixes_hint),
    maxLines: 2,
  );
}

class const _VerificationLimits({
  required final ScopedVerificationFormDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale(LocaleKeys.verification_limits_hint),
      _VerificationTimeoutInput(draft: draft),
      _VerificationOutputInput(draft: draft),
      _VerificationRepairsInput(draft: draft),
    ],
    crossAxisAlignment: .stretch,
  );
}

class const _VerificationTimeoutInput({
  required final ScopedVerificationFormDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _VerificationInput(
    controller: draft.timeout,
    label: const TextLocale(LocaleKeys.verification_timeout),
    semanticLabel: LocaleKeys.verification_timeout.tr(),
    identifier: 'verification-timeout',
    numeric: true,
  );
}

class const _VerificationOutputInput({
  required final ScopedVerificationFormDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _VerificationInput(
    controller: draft.output,
    label: const TextLocale(LocaleKeys.verification_output),
    semanticLabel: LocaleKeys.verification_output.tr(),
    identifier: 'verification-output',
    numeric: true,
  );
}

class const _VerificationRepairsInput({
  required final ScopedVerificationFormDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _VerificationInput(
    controller: draft.repairs,
    label: const TextLocale(LocaleKeys.verification_repairs),
    semanticLabel: LocaleKeys.verification_repairs.tr(),
    identifier: 'verification-repairs',
    numeric: true,
  );
}

class const _VerificationInput({
  required final TextEditingController controller,
  required final Widget label,
  required final String semanticLabel,
  required final String identifier,
  final Widget? hint,
  final int maxLines = 1,
  final bool numeric = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: label,
    hint: hint,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : null,
    maxLines: maxLines,
    identifier: identifier,
    semanticLabel: semanticLabel,
  );
}

class const _VerificationErrorText({required final String localeKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (localeKey) {
    LocaleKeys.verification_cloud_unavailable => const TextLocale(
      LocaleKeys.verification_cloud_unavailable,
    ),
    LocaleKeys.verification_errors_bindings => const TextLocale(
      LocaleKeys.verification_errors_bindings,
    ),
    LocaleKeys.verification_errors_runner_unavailable => const TextLocale(
      LocaleKeys.verification_errors_runner_unavailable,
    ),
    LocaleKeys.verification_errors_unsupported_runner => const TextLocale(
      LocaleKeys.verification_errors_unsupported_runner,
    ),
    LocaleKeys.verification_errors_conflict => const TextLocale(
      LocaleKeys.verification_errors_conflict,
    ),
    LocaleKeys.verification_errors_invalid => const TextLocale(
      LocaleKeys.verification_errors_invalid,
    ),
    _ => const TextLocale(LocaleKeys.verification_errors_save_failed),
  };
}
