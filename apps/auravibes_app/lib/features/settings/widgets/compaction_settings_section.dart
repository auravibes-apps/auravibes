// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: avoid-non-null-assertion
// Required: Existing nullable API contracts still use explicit assertions.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/usecases/reset_workspace_compaction_settings_usecase.dart';
import 'package:auravibes_app/features/settings/usecases/save_workspace_compaction_settings_usecase.dart';
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
  TextEditingController _usageController = throw StateError(
    '_usageController is not initialized',
  );
  TextEditingController _remainingController = throw StateError(
    '_remainingController is not initialized',
  );
  bool _autoEnabled = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final settingsAsync = ref.read(
      compactionSettingsProvider(widget.workspaceId),
    );
    final settings = settingsAsync.asData?.value ?? CompactionSettings.defaults;
    _usageController = TextEditingController(
      text: '${settings.usagePercentageThreshold}',
    );
    _remainingController = TextEditingController(
      text: '${settings.remainingTokenThreshold}',
    );
    _autoEnabled = settings.autoCompactionEnabled;
  }

  @override
  void dispose() {
    _usageController.dispose();
    _remainingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(compactionSettingsProvider(widget.workspaceId), (_, next) {
      final settings = next.asData?.value;
      if (settings == null) return;
      _usageController.text = '${settings.usagePercentageThreshold}';
      _remainingController.text = '${settings.remainingTokenThreshold}';
      setState(() => _autoEnabled = settings.autoCompactionEnabled);
    });

    return AuraCard(
      child: AuraColumn(
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.compaction_settings_title),
            style: AuraTextStyle.heading6,
            color: AuraColorVariant.onSurface,
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.compaction_settings_subtitle),
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurfaceVariant,
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: _autoEnabled,
              onChanged: (value) => setState(() => _autoEnabled = value),
              title: const TextLocale(
                LocaleKeys.compaction_settings_auto_enabled,
              ),
              subtitle: const TextLocale(
                LocaleKeys.compaction_settings_auto_enabled_hint,
              ),
            ),
          ),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _validationError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          TextField(
            controller: _usageController,
            decoration: InputDecoration(
              labelText: LocaleKeys.compaction_settings_usage_threshold.tr(),
              hintText: LocaleKeys.compaction_settings_usage_threshold_hint
                  .tr(),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _remainingController,
            decoration: InputDecoration(
              labelText: LocaleKeys.compaction_settings_remaining_threshold
                  .tr(),
              hintText: LocaleKeys.compaction_settings_remaining_threshold_hint
                  .tr(),
              border: const OutlineInputBorder(),
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

    final usage = int.tryParse(_usageController.text);
    final remaining = int.tryParse(_remainingController.text);

    if (usage == null || remaining == null) {
      setState(() {
        _validationError = LocaleKeys
            .compaction_settings_validation_settings_invalid
            .tr();
      });
      return;
    }

    final settings = CompactionSettings(
      autoCompactionEnabled: _autoEnabled,
      usagePercentageThreshold: usage,
      remainingTokenThreshold: remaining,
    );

    try {
      final _ = await ref.read(saveWorkspaceCompactionSettingsUsecaseProvider)(
        workspaceId: widget.workspaceId,
        settings: settings,
      );
      if (mounted) {
        final _ = ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TextLocale(LocaleKeys.compaction_settings_save_success),
          ),
        );
      }
    } on CompactionSettingsValidationException catch (e) {
      if (!mounted) return;
      setState(() => _validationError = e.localeKey.tr());
    } on Exception {
      if (mounted) {
        final _ = ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TextLocale(LocaleKeys.compaction_settings_save_error),
          ),
        );
      }
    }
  }

  Future<void> _resetDefaults() async {
    try {
      final _ = await ref.read(resetWorkspaceCompactionSettingsUsecaseProvider)(
        workspaceId: widget.workspaceId,
      );
    } on Exception {
      if (mounted) {
        final _ = ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TextLocale(LocaleKeys.compaction_settings_reset_error),
          ),
        );
      }
      return;
    }
    const defaults = CompactionSettings.defaults;
    if (!mounted) return;
    setState(() {
      _autoEnabled = defaults.autoCompactionEnabled;
      _usageController.text = '${defaults.usagePercentageThreshold}';
      _remainingController.text = '${defaults.remainingTokenThreshold}';
      _validationError = null;
    });
    if (mounted) {
      final _ = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextLocale(LocaleKeys.compaction_settings_reset_success),
        ),
      );
    }
  }
}
