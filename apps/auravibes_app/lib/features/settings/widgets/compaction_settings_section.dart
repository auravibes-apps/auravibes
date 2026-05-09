import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/usecases/reset_compaction_settings_usecase.dart';
import 'package:auravibes_app/features/settings/usecases/save_compaction_settings_usecase.dart';
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
  late TextEditingController _usageController;
  late TextEditingController _remainingController;
  late bool _autoEnabled;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuraText(
            style: AuraTextStyle.heading6,
            color: AuraColorVariant.onSurface,
            child: TextLocale(LocaleKeys.compaction_settings_title),
          ),
          const AuraText(
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurfaceVariant,
            child: TextLocale(LocaleKeys.compaction_settings_subtitle),
          ),
          SwitchListTile(
            title: const TextLocale(
              LocaleKeys.compaction_settings_auto_enabled,
            ),
            subtitle: const TextLocale(
              LocaleKeys.compaction_settings_auto_enabled_hint,
            ),
            value: _autoEnabled,
            onChanged: (value) => setState(() => _autoEnabled = value),
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
                variant: AuraButtonVariant.ghost,
                size: AuraButtonSize.small,
                onPressed: _resetDefaults,
                child: const TextLocale(
                  LocaleKeys.compaction_settings_reset_defaults,
                ),
              ),
              const SizedBox(width: 8),
              AuraButton(
                size: AuraButtonSize.small,
                onPressed: _save,
                child: const TextLocale(
                  LocaleKeys.settings_screen_actions_save,
                ),
              ),
            ],
          ),
        ],
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
      await ref.read(saveWorkspaceCompactionSettingsUsecaseProvider)(
        workspaceId: widget.workspaceId,
        settings: settings,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TextLocale(LocaleKeys.compaction_settings_save_success),
          ),
        );
      }
    } on CompactionSettingsValidationException catch (e) {
      setState(() => _validationError = e.localeKey.tr());
    }
  }

  Future<void> _resetDefaults() async {
    try {
      await ref.read(resetWorkspaceCompactionSettingsUsecaseProvider)(
        workspaceId: widget.workspaceId,
      );
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TextLocale(LocaleKeys.compaction_settings_reset_error),
          ),
        );
      }
      return;
    }
    const defaults = CompactionSettings.defaults;
    setState(() {
      _autoEnabled = defaults.autoCompactionEnabled;
      _usageController.text = '${defaults.usagePercentageThreshold}';
      _remainingController.text = '${defaults.remainingTokenThreshold}';
      _validationError = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextLocale(LocaleKeys.compaction_settings_reset_success),
        ),
      );
    }
  }
}
