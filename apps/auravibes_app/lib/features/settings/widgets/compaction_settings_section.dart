// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/settings/usecases/save_workspace_compaction_settings_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
  Map<String, CompactionModelOverride> _modelOverrides = const {};
  final _budgetControllers = <String, TextEditingController>{};
  final _invalidModelBudgets = <String>{};
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
    for (final controller in _budgetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _listenForCompactionSettings(ref, widget.workspaceId, this);

    final models = ref.watch(
      listWorkspaceModelSelectionsProvider(workspaceId: widget.workspaceId),
    );

    return AuraCard(
      child: _CompactionSettingsColumn(state: this, models: models),
    );
  }

  void _handleSettingsChange(CompactionSettings? settings) {
    if (settings == null) return;
    _remainingController.text = '${settings.remainingTokenThreshold}';
    setState(() {
      _applyCompactionSettings(this, settings);
      _invalidModelBudgets.clear();
    });
  }

  Future<void> _save() => _saveCompactionSettingsForm(this);

  Future<void> _resetDefaults() => _resetCompactionSettingsForm(this);

  void _setUsagePercentage(double value) {
    setState(() => _usagePercentageThreshold = value.round());
  }

  void _updateState(VoidCallback update) {
    setState(update);
  }

  TextEditingController _budgetController({
    required String modelKey,
    required bool reserveTokens,
  }) {
    final override = _modelOverrides[modelKey];
    final value = reserveTokens
        ? override?.reserveTokens
        : override?.keepRecentTokens;

    return _budgetControllers.putIfAbsent(
      _compactionModelBudgetFieldKey(modelKey, reserveTokens),
      () => TextEditingController(text: value?.toString() ?? ''),
    );
  }

  void _updateModelBudget({
    required String modelKey,
    required bool reserveTokens,
    required String value,
  }) {
    final update = _parseCompactionModelBudgetUpdate(
      modelKey,
      reserveTokens,
      value,
    );
    if (update == null) {
      _markInvalidCompactionModelBudget(this, modelKey, reserveTokens);

      return;
    }
    _updateState(() {
      final _ = _invalidModelBudgets.remove(update.fieldKey);
      _applyCompactionModelBudget(this, update);
    });
  }
}

typedef _CompactionModelBudgetUpdate = ({
  String fieldKey,
  String modelKey,
  bool reserveTokens,
  int? tokens,
});

String _compactionModelBudgetFieldKey(String modelKey, bool reserveTokens) =>
    '$modelKey/${reserveTokens ? 'reserve' : 'recent'}';

void _markInvalidCompactionModelBudget(
  _CompactionSettingsSectionState state,
  String modelKey,
  bool reserveTokens,
) => state._updateState(() {
  final _ = state._invalidModelBudgets.add(
    _compactionModelBudgetFieldKey(modelKey, reserveTokens),
  );
});

_CompactionModelBudgetUpdate? _parseCompactionModelBudgetUpdate(
  String modelKey,
  bool reserveTokens,
  String value,
) {
  final tokens = value.isEmpty ? null : int.tryParse(value);
  if (value.isNotEmpty && (tokens == null || tokens < 0)) return null;

  return (
    fieldKey: _compactionModelBudgetFieldKey(modelKey, reserveTokens),
    modelKey: modelKey,
    reserveTokens: reserveTokens,
    tokens: tokens,
  );
}

void _applyCompactionModelBudget(
  _CompactionSettingsSectionState state,
  _CompactionModelBudgetUpdate update,
) {
  final previous =
      state._modelOverrides[update.modelKey] ?? const CompactionModelOverride();
  final updated = update.reserveTokens
      ? previous.copyWith(reserveTokens: update.tokens)
      : previous.copyWith(keepRecentTokens: update.tokens);
  _applyCompactionModelOverride(state, update.modelKey, updated);
}

void _applyCompactionModelOverride(
  _CompactionSettingsSectionState state,
  String modelKey,
  CompactionModelOverride updated,
) {
  final overrides = {...state._modelOverrides};
  if (updated.reserveTokens == null && updated.keepRecentTokens == null) {
    final _ = overrides.remove(modelKey);
  } else {
    overrides[modelKey] = updated;
  }
  state._modelOverrides = overrides;
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
    state._invalidModelBudgets.clear();
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
) {
  final remaining = int.tryParse(state._remainingController.text);
  if (remaining == null || state._invalidModelBudgets.isNotEmpty) return null;

  return CompactionSettings(
    autoCompactionEnabled: state._autoEnabled,
    usagePercentageThreshold: state._usagePercentageThreshold,
    remainingTokenThreshold: remaining,
    modelOverrides: state._modelOverrides,
  );
}

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
    .._autoEnabled = settings.autoCompactionEnabled
    .._modelOverrides = settings.modelOverrides;
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
  required final AsyncValue<List<WorkspaceModelSelectionWithConnectionEntity>>
  models,
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
      _CompactionModelBudgets(state: state, models: models),
      _CompactionSettingsActions(state: state),
    ],
    crossAxisAlignment: .start,
  );
}

class const _CompactionModelBudgets({
  required final _CompactionSettingsSectionState state,
  required final AsyncValue<List<WorkspaceModelSelectionWithConnectionEntity>>
  models,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (models) {
    AsyncData(:final value) when value.isEmpty => const TextLocale(
      LocaleKeys.compaction_settings_models_empty,
    ),
    AsyncData(:final value) => _CompactionModelBudgetData(
      state: state,
      selections: value,
    ),
    AsyncError() => const TextLocale(
      LocaleKeys.compaction_settings_models_unavailable,
    ),
    AsyncLoading() => const TextLocale(
      LocaleKeys.compaction_settings_models_loading,
    ),
  };
}

class const _CompactionModelBudgetData({
  required final _CompactionSettingsSectionState state,
  required final List<WorkspaceModelSelectionWithConnectionEntity> selections,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      const TextLocale(LocaleKeys.compaction_settings_model_budgets_title),
      const TextLocale(LocaleKeys.compaction_settings_model_budgets_hint),
      for (final selection in selections)
        _CompactionModelBudgetFields(state: state, selection: selection),
    ],
    crossAxisAlignment: .stretch,
  );
}

class const _CompactionModelBudgetFields({
  required final _CompactionSettingsSectionState state,
  required final WorkspaceModelSelectionWithConnectionEntity selection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = selection.workspaceModelSelection;
    final modelKey = '${selection.modelsProvider.id}/${model.modelId}';

    return AuraColumn(
      children: [
        _CompactionModelBudgetTitle(selection: selection),
        for (final reserveTokens in const [true, false])
          _CompactionModelBudgetInput(
            state: state,
            modelKey: modelKey,
            reserveTokens: reserveTokens,
          ),
      ],
      crossAxisAlignment: .stretch,
    );
  }
}

class const _CompactionModelBudgetTitle({
  required final WorkspaceModelSelectionWithConnectionEntity selection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final model = selection.workspaceModelSelection;

    return AuraText(
      child: Text(
        '${selection.modelsProvider.name} / ${model.modelName ?? model.modelId}',
      ),
    );
  }
}

class const _CompactionModelBudgetInput({
  required final _CompactionSettingsSectionState state,
  required final String modelKey,
  required final bool reserveTokens,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CompactionBudgetTextInput(
    controller: state._budgetController(
      modelKey: modelKey,
      reserveTokens: reserveTokens,
    ),
    label: reserveTokens
        ? LocaleKeys.compaction_settings_reserve_tokens
        : LocaleKeys.compaction_settings_keep_recent_tokens,
    onChanged: (value) => state._updateModelBudget(
      modelKey: modelKey,
      reserveTokens: reserveTokens,
      value: value,
    ),
  );
}

class const _CompactionBudgetTextInput({
  required final TextEditingController controller,
  required final String label,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    placeholder: Text(LocaleKeys.compaction_settings_budget_optional.tr()),
    label: Text(label.tr()),
    keyboardType: .number,
    onChanged: onChanged,
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
  Widget build(BuildContext _) => Semantics(
    key: const ValueKey<String>('settings_compaction_reset'),
    child: AuraButton(
      onPressed: () => unawaited(state._resetDefaults()),
      child: const TextLocale(LocaleKeys.compaction_settings_reset_defaults),
      variant: .ghost,
      size: .small,
    ),
    identifier: 'settings_compaction_reset',
  );
}

class const _CompactionSaveButton({
  required final _CompactionSettingsSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Semantics(
    key: const ValueKey<String>('settings_compaction_save'),
    child: AuraButton(
      onPressed: () => unawaited(state._save()),
      child: const TextLocale(LocaleKeys.settings_screen_actions_save),
      size: .small,
    ),
    identifier: 'settings_compaction_save',
  );
}
