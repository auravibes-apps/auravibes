// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/settings/usecases/save_workspace_compaction_settings_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _minUsagePercentage = 5;
const _maxUsagePercentage = 100;
const _compactionSettingsTitle = AuraText(
  child: TextLocale(LocaleKeys.compaction_settings_title),
  style: .heading6,
);
const _compactionSettingsSubtitle = AuraText(
  child: TextLocale(LocaleKeys.compaction_settings_subtitle),
  style: .bodySmall,
);
const _compactionSettingsUsageLabel = AuraText(
  child: TextLocale(LocaleKeys.compaction_settings_usage_threshold),
);
const _compactionSettingsHeader = AuraColumn(
  children: [_compactionSettingsTitle, _compactionSettingsSubtitle],
  crossAxisAlignment: .start,
);
const _compactionAutoCompactionDescription = AuraColumn(
  children: [
    AuraText(child: TextLocale(LocaleKeys.compaction_settings_auto_enabled)),
    AuraText(
      child: TextLocale(LocaleKeys.compaction_settings_auto_enabled_hint),
      style: .bodySmall,
    ),
  ],
  spacing: .xs,
  crossAxisAlignment: .start,
);

class const CompactionSettingsSection({
  required final String workspaceId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<CompactionSettingsSection> createState() =>
      _CompactionSettingsSectionState();
}

class _CompactionSettingsSectionState
    extends ConsumerState<CompactionSettingsSection> {
  final _remainingController = TextEditingController();
  int _usagePercentageThreshold =
      CompactionSettings.defaults.usagePercentageThreshold;
  bool _autoEnabled = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final settings =
        ref
            .read(compactionSettingsProvider(widget.workspaceId))
            .asData
            ?.value ??
        CompactionSettings.defaults;
    _applyCompactionSettings(this, settings);
    _remainingController.text = '${settings.remainingTokenThreshold}';
  }

  @override
  void dispose() {
    _remainingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _listenForCompactionSettings(ref, widget.workspaceId, this);

    return AuraCard(child: _CompactionSettingsColumn(state: this));
  }

  void _handleSettingsChange(CompactionSettings? settings) {
    if (settings == null) return;
    _remainingController.text = '${settings.remainingTokenThreshold}';
    setState(() => _applyCompactionSettings(this, settings));
  }

  Future<void> _save() => _saveCompactionSettingsForm(this);

  Future<void> _resetDefaults() => _resetCompactionSettingsForm(this);

  void _setUsagePercentage(double value) {
    setState(() => _usagePercentageThreshold = value.round());
  }

  void _updateState(VoidCallback update) {
    setState(update);
  }
}

void _listenForCompactionSettings(
  WidgetRef ref,
  String workspaceId,
  _CompactionSettingsSectionState state,
) {
  ref.listen(
    compactionSettingsProvider(workspaceId),
    (_, next) => state._handleSettingsChange(next.asData?.value),
  );
}

Future<void> _saveCompactionSettingsForm(
  _CompactionSettingsSectionState state,
) async {
  _clearCompactionValidationError(state);
  final settings = _compactionSettingsFromState(state);
  if (settings == null) {
    _showInvalidCompactionSettings(state);

    return;
  }

  await _submitCompactionSettings(state, settings);
}

Future<void> _submitCompactionSettings(
  _CompactionSettingsSectionState state,
  CompactionSettings settings,
) async {
  try {
    await _persistCompactionSettingsForState(state, settings);
  } on Exception catch (error) {
    _showCompactionSaveError(state, error);

    return;
  }

  _showCompactionMessage(
    state,
    LocaleKeys.compaction_settings_save_success,
    .success,
  );
}

void _showCompactionSaveError(
  _CompactionSettingsSectionState state,
  Exception error,
) {
  if (error case final CompactionSettingsValidationException validationError) {
    _setCompactionValidationError(state, validationError.localeKey);

    return;
  }

  _showCompactionMessage(
    state,
    LocaleKeys.compaction_settings_save_error,
    .error,
  );
}

void _setCompactionValidationError(
  _CompactionSettingsSectionState state,
  String localeKey,
) {
  if (!state.mounted) return;
  state._updateState(() => state._validationError = localeKey.tr());
}

void _clearCompactionValidationError(_CompactionSettingsSectionState state) {
  state._updateState(() => state._validationError = null);
}

void _showInvalidCompactionSettings(_CompactionSettingsSectionState state) {
  _setCompactionValidationError(
    state,
    LocaleKeys.compaction_settings_validation_settings_invalid,
  );
}

Future<void> _resetCompactionSettingsForm(
  _CompactionSettingsSectionState state,
) async {
  if (!await _tryResetStoredCompactionSettings(state)) return;
  if (!state.mounted) return;
  _resetCompactionForm(state);
  _showCompactionMessage(
    state,
    LocaleKeys.compaction_settings_reset_success,
    .success,
  );
}

Future<bool> _tryResetStoredCompactionSettings(
  _CompactionSettingsSectionState state,
) async {
  try {
    await _resetStoredCompactionSettings(state.ref, state.widget.workspaceId);
  } on Exception {
    _showCompactionMessage(
      state,
      LocaleKeys.compaction_settings_reset_error,
      .error,
    );

    return false;
  }

  return true;
}

void _resetCompactionForm(_CompactionSettingsSectionState state) {
  const defaults = CompactionSettings.defaults;
  state._updateState(() {
    _applyCompactionSettings(state, defaults);
    state._remainingController.text = '${defaults.remainingTokenThreshold}';
    state._validationError = null;
  });
}

void _showCompactionMessage(
  _CompactionSettingsSectionState state,
  String localeKey,
  AuraSnackBarVariant variant,
) {
  if (!state.mounted) return;
  _showCompactionSnackBar(
    context: state.context,
    content: TextLocale(localeKey),
    variant: variant,
  );
}

CompactionSettings? _compactionSettingsFromState(
  _CompactionSettingsSectionState state,
) => _compactionSettingsFromForm(
  autoCompactionEnabled: state._autoEnabled,
  usagePercentageThreshold: state._usagePercentageThreshold,
  remainingTokenText: state._remainingController.text,
);

Future<void> _persistCompactionSettingsForState(
  _CompactionSettingsSectionState state,
  CompactionSettings settings,
) => _persistCompactionSettings(state.ref, state.widget.workspaceId, settings);

void _applyCompactionSettings(
  _CompactionSettingsSectionState state,
  CompactionSettings settings,
) {
  state
    .._usagePercentageThreshold = settings.usagePercentageThreshold.clamp(
      _minUsagePercentage,
      _maxUsagePercentage,
    )
    .._autoEnabled = settings.autoCompactionEnabled;
}

CompactionSettings? _compactionSettingsFromForm({
  required bool autoCompactionEnabled,
  required int usagePercentageThreshold,
  required String remainingTokenText,
}) {
  final remaining = int.tryParse(remainingTokenText);
  if (remaining == null) return null;

  return CompactionSettings(
    autoCompactionEnabled: autoCompactionEnabled,
    usagePercentageThreshold: usagePercentageThreshold,
    remainingTokenThreshold: remaining,
  );
}

Future<void> _persistCompactionSettings(
  WidgetRef ref,
  String workspaceId,
  CompactionSettings settings,
) async {
  final usecase = await ref.read(
    saveWorkspaceCompactionSettingsUsecaseProvider(workspaceId).future,
  );
  final _ = await usecase(workspaceId: workspaceId, settings: settings);
}

Future<void> _resetStoredCompactionSettings(
  WidgetRef ref,
  String workspaceId,
) async {
  final session = await ref.read(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (session.cloud != null) {
    await _resetCloudCompactionSettings(ref, workspaceId);

    return;
  }

  await _resetLocalCompactionSettings(ref, workspaceId);
}

Future<void> _resetCloudCompactionSettings(
  WidgetRef ref,
  String workspaceId,
) async {
  final usecase = await ref.read(
    saveWorkspaceCompactionSettingsUsecaseProvider(workspaceId).future,
  );
  await usecase.reset(workspaceId: workspaceId);
}

Future<void> _resetLocalCompactionSettings(
  WidgetRef ref,
  String workspaceId,
) async {
  final _ = await ref
      .read(workspaceCompactionSettingsRepositoryProvider)
      .resetOverrides(workspaceId);
}

void _showCompactionSnackBar({
  required BuildContext context,
  required Widget content,
  required AuraSnackBarVariant variant,
}) {
  final _ = AuraSnackBars.show(
    context: context,
    content: content,
    variant: variant,
  );
}

class const _CompactionSettingsColumn({
  required final _CompactionSettingsSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _compactionSettingsHeader,
      _CompactionAutoCompactionRow(state: state),
      if (state._validationError case final validationError?)
        _CompactionValidationError(message: validationError),
      _CompactionUsageThreshold(state: state),
      _CompactionRemainingTokenInput(controller: state._remainingController),
      _CompactionSettingsActions(state: state),
    ],
    crossAxisAlignment: .start,
  );
}

class const _CompactionValidationError({required final String message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      message,
      style: .new(color: Theme.of(context).colorScheme.error, fontSize: 12),
    ),
  );
}

class const _CompactionAutoCompactionRow({
  required final _CompactionSettingsSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraRow(
    children: [
      const Expanded(child: _compactionAutoCompactionDescription),
      AuraSwitch(
        value: state._autoEnabled,
        onChanged: (value) =>
            state._updateState(() => state._autoEnabled = value),
      ),
    ],
  );
}

class const _CompactionUsageThreshold({
  required final _CompactionSettingsSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      _CompactionUsageThresholdLabel(state: state),
      _CompactionUsageThresholdSlider(state: state),
    ],
    spacing: .xs,
    crossAxisAlignment: .stretch,
  );
}

class const _CompactionUsageThresholdLabel({
  required final _CompactionSettingsSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraRow(
    children: [
      const Expanded(child: _compactionSettingsUsageLabel),
      AuraText(
        child: Text('${state._usagePercentageThreshold}%'),
        style: .bodyLarge,
      ),
    ],
    mainAxisAlignment: .spaceBetween,
  );
}

class const _CompactionUsageThresholdSlider({
  required final _CompactionSettingsSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraSlider(
    value: state._usagePercentageThreshold.toDouble(),
    onChanged: state._setUsagePercentage,
    min: _minUsagePercentage.toDouble(),
    max: _maxUsagePercentage.toDouble(),
    semanticLabel: LocaleKeys.compaction_settings_usage_threshold.tr(),
  );
}

class const _CompactionRemainingTokenInput({
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraInput(
    controller: controller,
    placeholder: Text(
      LocaleKeys.compaction_settings_remaining_threshold_hint.tr(),
    ),
    label: Text(LocaleKeys.compaction_settings_remaining_threshold.tr()),
    keyboardType: .number,
  );
}

class const _CompactionSettingsActions({
  required final _CompactionSettingsSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Row(
    mainAxisAlignment: .end,
    children: [
      _CompactionResetButton(state: state),
      const SizedBox(width: 8),
      _CompactionSaveButton(state: state),
    ],
  );
}

class const _CompactionResetButton({
  required final _CompactionSettingsSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: () => unawaited(state._resetDefaults()),
    child: const TextLocale(LocaleKeys.compaction_settings_reset_defaults),
    variant: .ghost,
    size: .small,
  );
}

class const _CompactionSaveButton({
  required final _CompactionSettingsSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: () => unawaited(state._save()),
    child: const TextLocale(LocaleKeys.settings_screen_actions_save),
    size: .small,
  );
}
