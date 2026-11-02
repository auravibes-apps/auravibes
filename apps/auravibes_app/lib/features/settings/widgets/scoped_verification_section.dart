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
  final _errorAnchor = GlobalKey();
  ScopedVerificationFormDraft _draft = ScopedVerificationFormDraft(
    ScopedVerificationSettings(),
  );
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
    ref.listen(scopedVerificationSettingsProvider(widget.workspaceId), (
      _,
      next,
    ) {
      final value = next.asData?.value;
      if (value == null) return;
      _latest = value;
      if (!_draft.isDirty && !_saving) {
        setState(() => _replace(value));
        _publishGuard();
      }
    });
    final cloud = session.asData?.value?.cloud != null;
    final tools = cloud
        ? const AsyncData<List<ScopedVerificationToolOption>>([])
        : ref.watch(scopedVerificationToolsProvider(widget.workspaceId));

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
    _change(() {
      if (_draft.mcpServerId != tool?.serverId) _draft.editToolIds.clear();
      _draft.runnerToolId = tool?.id ?? '';
      _draft.mcpServerId = tool?.serverId ?? '';
      final _ = _draft.editToolIds.remove(_draft.runnerToolId);
    });
  }

  void _showError(String key) {
    setState(() => _error = key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final errorContext = _errorAnchor.currentContext;
      if (mounted && errorContext != null)
        unawaited(Scrollable.ensureVisible(errorContext));
    });
  }

  Future<void> _save() async {
    if (_saving || !_loaded || !_draft.isDirty) return;
    final ScopedVerificationSettings pending;
    try {
      pending = _draft.read();
    } on FormatException {
      _advanced = true;
      _showError(LocaleKeys.verification_errors_invalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    _publishGuard();
    try {
      await ref.read(
        saveScopedVerificationSettingsUsecaseProvider(widget.workspaceId),
      )(workspaceId: widget.workspaceId, settings: pending);
      final saved = await ref
          .read(workspaceVerificationRepositoryProvider)
          .getSettings(widget.workspaceId);
      if (!mounted) return;
      setState(() {
        _replace(saved);
        _notice = LocaleKeys.verification_saved;
      });
    } on ScopedVerificationSettingsException catch (error) {
      if (mounted) _showError(error.localeKey);
    } on Object {
      if (mounted) _showError(LocaleKeys.verification_errors_save_failed);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _publishGuard();
      }
    }
  }
}

class const _VerificationCard({
  required final _ScopedVerificationSectionState state,
  required final bool cloud,
  required final bool loadError,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: AuraColumn(
      crossAxisAlignment: .stretch,
      children: [
        AuraWrap(
          children: [
            const AuraText(
              child: TextLocale(LocaleKeys.verification_title),
              style: .heading6,
            ),
            if (cloud || loadError && !state._loaded)
              const AuraText(
                child: TextLocale(LocaleKeys.verification_unavailable),
                style: .bodySmall,
              )
            else if (state._saving)
              const AuraText(
                child: TextLocale(LocaleKeys.verification_saving),
                style: .bodySmall,
              )
            else if (!state._loaded)
              const AuraText(
                child: TextLocale(LocaleKeys.verification_loading),
                style: .bodySmall,
              )
            else if (state._draft.enabled)
              const AuraText(
                child: TextLocale(LocaleKeys.verification_enabled),
                style: .bodySmall,
              )
            else
              const AuraText(
                child: TextLocale(LocaleKeys.verification_disabled),
                style: .bodySmall,
              ),
            if (state._draft.isDirty)
              const TextLocale(LocaleKeys.verification_unsaved),
          ],
        ),
        const AuraText(
          child: TextLocale(LocaleKeys.verification_subtitle),
          style: .bodySmall,
        ),
        if (cloud)
          const TextLocale(LocaleKeys.verification_cloud_unavailable)
        else ...[
          if (loadError)
            _VerificationLoadError(workspaceId: state.widget.workspaceId),
          if (state._loaded)
            ExcludeFocus(
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
            ),
        ],
      ],
    ),
  );
}

class const _VerificationLoadError({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraColumn(
    crossAxisAlignment: .start,
    children: [
      const TextLocale(LocaleKeys.verification_errors_load_failed),
      AuraButton(
        onPressed: () {
          ref.invalidate(scopedVerificationSettingsProvider(workspaceId));
          ref.invalidate(scopedVerificationToolsProvider(workspaceId));
        },
        variant: .ghost,
        child: const TextLocale(LocaleKeys.route_state_retry),
      ),
    ],
  );
}

class const _VerificationForm({
  required final _ScopedVerificationSectionState state,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = state._draft;
    final runners = tools.where((tool) => tool.canRunUnattended).toList();

    return FocusTraversalGroup(
      child: AuraColumn(
        crossAxisAlignment: .stretch,
        children: [
          const TextLocale(LocaleKeys.verification_runner_requirement),
          AuraCheckboxListTile(
            key: const ValueKey('verification-enable'),
            value: draft.enabled,
            onChanged: (value) => state._change(() => draft.enabled = value),
            title: const TextLocale(LocaleKeys.verification_enable),
            subtitle: const TextLocale(LocaleKeys.verification_enable_hint),
            semanticLabel: LocaleKeys.verification_enable.tr(),
          ),
          if (runners.isEmpty)
            const TextLocale(LocaleKeys.verification_no_runner),
          AuraDropdownSelector<String>(
            options: [
              for (final tool in runners)
                AuraDropdownOption(value: tool.id, child: Text(tool.label)),
            ],
            value: runners.any((tool) => tool.id == draft.runnerToolId)
                ? draft.runnerToolId
                : null,
            onChanged: (id) => state._selectRunner(id, runners),
            label: const TextLocale(LocaleKeys.verification_runner),
            hint: const TextLocale(LocaleKeys.verification_runner_hint),
            semanticLabel: LocaleKeys.verification_runner.tr(),
          ),
          _VerificationInput(
            controller: draft.root,
            label: LocaleKeys.verification_root,
            hint: LocaleKeys.verification_root_hint,
            identifier: 'verification-root',
          ),
          _VerificationEditTools(state: state, tools: tools),
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
            disabled: draft.checks.length >= ScopedVerificationLimits.maxChecks,
            variant: .ghost,
            child: const TextLocale(LocaleKeys.verification_add_check),
          ),
          Semantics(
            expanded: state._advanced,
            child: AuraButton(
              onPressed: () =>
                  state.setState(() => state._advanced = !state._advanced),
              variant: .ghost,
              child: const TextLocale(LocaleKeys.verification_advanced),
            ),
          ),
          if (state._advanced) _VerificationLimits(draft: draft),
          if (state._error case final String error)
            Semantics(
              key: state._errorAnchor,
              liveRegion: true,
              child: TextLocale(error),
            ),
          AuraWrap(
            children: [
              AuraButton(
                key: const ValueKey('verification-save'),
                onPressed: () => unawaited(state._save()),
                disabled: !draft.isDirty || state._saving,
                isLoading: state._saving,
                child: const TextLocale(LocaleKeys.verification_save),
              ),
              AuraButton(
                key: const ValueKey('verification-discard'),
                onPressed: () {
                  final latest = state._latest;
                  if (latest != null) {
                    state.setState(() {
                      state._replace(latest);
                      state._error = null;
                      state._notice = null;
                    });
                    state._publishGuard();
                  }
                },
                disabled: !draft.isDirty || state._saving,
                variant: .ghost,
                child: const TextLocale(LocaleKeys.verification_discard),
              ),
            ],
          ),
          if (state._notice case final String notice)
            Semantics(liveRegion: true, child: TextLocale(notice)),
        ],
      ),
    );
  }
}

class const _VerificationEditTools({
  required final _ScopedVerificationSectionState state,
  required final List<ScopedVerificationToolOption> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = state._draft;
    final edits = tools
        .where(
          (tool) =>
              tool.serverId == draft.mcpServerId &&
              tool.id != draft.runnerToolId,
        )
        .toList();
    final eligible = edits.map((tool) => tool.id).toSet();

    return AuraColumn(
      crossAxisAlignment: .stretch,
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.verification_edit_tools),
          style: .heading6,
        ),
        const TextLocale(LocaleKeys.verification_edit_tools_hint),
        if (draft.editToolIds.any((id) => !eligible.contains(id))) ...[
          const TextLocale(LocaleKeys.verification_missing_selections),
          AuraButton(
            onPressed: () => state._change(
              () =>
                  draft.editToolIds.removeWhere((id) => !eligible.contains(id)),
            ),
            variant: .ghost,
            child: const TextLocale(LocaleKeys.verification_clear_missing),
          ),
        ],
        for (final tool in edits)
          AuraCheckboxListTile(
            value: draft.editToolIds.contains(tool.id),
            onChanged: (value) => state._change(() {
              final _ = value
                  ? draft.editToolIds.add(tool.id)
                  : draft.editToolIds.remove(tool.id);
            }),
            title: Text(tool.label),
            semanticLabel: tool.label,
          ),
      ],
    );
  }
}

class const _VerificationCheckFields({
  required final _ScopedVerificationSectionState state,
  required final ScopedVerificationCheckDraft check,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    crossAxisAlignment: .stretch,
    children: [
      _VerificationInput(
        controller: check.id,
        label: LocaleKeys.verification_check_id,
        identifier: 'verification-check-${identityHashCode(check)}',
      ),
      _VerificationInput(
        controller: check.executable,
        label: LocaleKeys.verification_executable,
        identifier: 'verification-executable-${identityHashCode(check)}',
      ),
      _VerificationInput(
        controller: check.arguments,
        label: LocaleKeys.verification_arguments,
        hint: LocaleKeys.verification_arguments_hint,
        identifier: 'verification-arguments-${identityHashCode(check)}',
        maxLines: 3,
      ),
      _VerificationInput(
        controller: check.suffixes,
        label: LocaleKeys.verification_suffixes,
        hint: LocaleKeys.verification_suffixes_hint,
        identifier: 'verification-suffixes-${identityHashCode(check)}',
        maxLines: 2,
      ),
      AuraButton(
        onPressed: () => state._removeCheck(check),
        variant: .ghost,
        child: const TextLocale(LocaleKeys.verification_remove_check),
      ),
    ],
  );
}

class const _VerificationLimits({
  required final ScopedVerificationFormDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    crossAxisAlignment: .stretch,
    children: [
      const TextLocale(LocaleKeys.verification_limits_hint),
      _VerificationInput(
        controller: draft.timeout,
        label: LocaleKeys.verification_timeout,
        identifier: 'verification-timeout',
        numeric: true,
      ),
      _VerificationInput(
        controller: draft.output,
        label: LocaleKeys.verification_output,
        identifier: 'verification-output',
        numeric: true,
      ),
      _VerificationInput(
        controller: draft.repairs,
        label: LocaleKeys.verification_repairs,
        identifier: 'verification-repairs',
        numeric: true,
      ),
    ],
  );
}

class const _VerificationInput({
  required final TextEditingController controller,
  required final String label,
  required final String identifier,
  final String? hint,
  final int maxLines = 1,
  final bool numeric = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: TextLocale(label),
    hint: hint == null ? null : TextLocale(hint!),
    maxLines: maxLines,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : null,
    identifier: identifier,
    semanticLabel: label.tr(),
  );
}
