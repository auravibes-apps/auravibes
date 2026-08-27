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

class CompactionSettingsSection extends ConsumerStatefulWidget {
  const CompactionSettingsSection({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  ConsumerState<CompactionSettingsSection> createState() =>
      _CompactionSettingsSectionState();
}

class _CompactionSettingsSectionState
    extends ConsumerState<CompactionSettingsSection> {
  TextEditingController? _remainingController;
  int _usagePercentageThreshold =
      CompactionSettings.defaults.usagePercentageThreshold;
  bool _autoEnabled = false;
  String? _validationError;

  TextEditingController get _requiredRemainingController {
    final controller = _remainingController;
    if (controller == null) {
      throw StateError('_remainingController is not initialized');
    }

    return controller;
  }

  @override
  void initState() {
    super.initState();
    final settingsAsync = ref.read(
      compactionSettingsProvider(widget.workspaceId),
    );
    final settings = settingsAsync.asData?.value ?? CompactionSettings.defaults;
    _usagePercentageThreshold = settings.usagePercentageThreshold.clamp(5, 100);
    _remainingController = TextEditingController(
      text: '${settings.remainingTokenThreshold}',
    );
    _autoEnabled = settings.autoCompactionEnabled;
  }

  @override
  void dispose() {
    _remainingController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(compactionSettingsProvider(widget.workspaceId), (_, next) {
      final settings = next.asData?.value;
      if (settings == null) return;
      _requiredRemainingController.text = '${settings.remainingTokenThreshold}';
      setState(() {
        _usagePercentageThreshold = settings.usagePercentageThreshold.clamp(
          5,
          100,
        );
        _autoEnabled = settings.autoCompactionEnabled;
      });
    });

    return AuraCard(
      child: AuraColumn(
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.compaction_settings_title),
            style: AuraTextStyle.heading6,
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.compaction_settings_subtitle),
            style: AuraTextStyle.bodySmall,
          ),
          AuraRow(
            children: [
              const Expanded(
                child: AuraColumn(
                  children: [
                    AuraText(
                      child: TextLocale(
                        LocaleKeys.compaction_settings_auto_enabled,
                      ),
                    ),
                    AuraText(
                      child: TextLocale(
                        LocaleKeys.compaction_settings_auto_enabled_hint,
                      ),
                      style: AuraTextStyle.bodySmall,
                    ),
                  ],
                  spacing: .xs,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
              ),
              AuraSwitch(
                value: _autoEnabled,
                onChanged: (value) => setState(() => _autoEnabled = value),
              ),
            ],
          ),
          if (_validationError case final validationError?)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                validationError,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          AuraColumn(
            children: [
              AuraRow(
                children: [
                  const Expanded(
                    child: AuraText(
                      child: TextLocale(
                        LocaleKeys.compaction_settings_usage_threshold,
                      ),
                    ),
                  ),
                  AuraText(
                    child: Text('$_usagePercentageThreshold%'),
                    style: AuraTextStyle.bodyLarge,
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
              AuraSlider(
                value: _usagePercentageThreshold.toDouble(),
                onChanged: (value) =>
                    setState(() => _usagePercentageThreshold = value.round()),
                min: 5,
                max: 100,
                semanticLabel: LocaleKeys.compaction_settings_usage_threshold
                    .tr(),
              ),
            ],
            spacing: .xs,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          ),
          AuraInput(
            controller: _requiredRemainingController,
            placeholder: Text(
              LocaleKeys.compaction_settings_remaining_threshold_hint.tr(),
            ),
            label: Text(
              LocaleKeys.compaction_settings_remaining_threshold.tr(),
            ),
            keyboardType: TextInputType.number,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AuraButton(
                onPressed: () => unawaited(_resetDefaults()),
                child: const TextLocale(
                  LocaleKeys.compaction_settings_reset_defaults,
                ),
                variant: AuraButtonVariant.ghost,
                size: AuraButtonSize.small,
              ),
              const SizedBox(width: 8),
              AuraButton(
                onPressed: () => unawaited(_save()),
                child: const TextLocale(
                  LocaleKeys.settings_screen_actions_save,
                ),
                size: AuraButtonSize.small,
              ),
            ],
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _validationError = null);

    final remaining = int.tryParse(_requiredRemainingController.text);

    if (remaining == null) {
      setState(() {
        _validationError = LocaleKeys
            .compaction_settings_validation_settings_invalid
            .tr();
      });

      return;
    }

    final settings = CompactionSettings(
      autoCompactionEnabled: _autoEnabled,
      usagePercentageThreshold: _usagePercentageThreshold,
      remainingTokenThreshold: remaining,
    );

    try {
      final usecase = await ref.read(
        saveWorkspaceCompactionSettingsUsecaseProvider(
          widget.workspaceId,
        ).future,
      );
      final _ = await usecase(
        workspaceId: widget.workspaceId,
        settings: settings,
      );
      if (mounted) {
        final _ = AuraSnackBars.show(
          context: context,
          content: const TextLocale(
            LocaleKeys.compaction_settings_save_success,
          ),
          variant: AuraSnackBarVariant.success,
        );
      }
    } on CompactionSettingsValidationException catch (e) {
      if (!mounted) return;
      setState(() => _validationError = e.localeKey.tr());
    } on Exception {
      if (mounted) {
        final _ = AuraSnackBars.show(
          context: context,
          content: const TextLocale(LocaleKeys.compaction_settings_save_error),
          variant: AuraSnackBarVariant.error,
        );
      }
    }
  }

  Future<void> _resetDefaults() async {
    try {
      var isCloud = false;
      isCloud =
          (await ref.read(
            workspaceSessionForRouteProvider(widget.workspaceId).future,
          )).cloud !=
          null;
      if (isCloud) {
        final usecase = await ref.read(
          saveWorkspaceCompactionSettingsUsecaseProvider(
            widget.workspaceId,
          ).future,
        );
        await usecase.reset(workspaceId: widget.workspaceId);
      } else {
        final _ = await ref
            .read(workspaceCompactionSettingsRepositoryProvider)
            .resetOverrides(widget.workspaceId);
      }
    } on Exception {
      if (mounted) {
        final _ = AuraSnackBars.show(
          context: context,
          content: const TextLocale(LocaleKeys.compaction_settings_reset_error),
          variant: AuraSnackBarVariant.error,
        );
      }

      return;
    }
    const defaults = CompactionSettings.defaults;
    if (!mounted) return;
    setState(() {
      _usagePercentageThreshold = defaults.usagePercentageThreshold;
      _autoEnabled = defaults.autoCompactionEnabled;
      _requiredRemainingController.text = '${defaults.remainingTokenThreshold}';
      _validationError = null;
    });
    if (mounted) {
      final _ = AuraSnackBars.show(
        context: context,
        content: const TextLocale(LocaleKeys.compaction_settings_reset_success),
        variant: AuraSnackBarVariant.success,
      );
    }
  }
}
