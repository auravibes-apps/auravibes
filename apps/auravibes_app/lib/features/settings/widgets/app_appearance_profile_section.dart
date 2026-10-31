import 'package:auravibes_app/features/settings/models/app_appearance_profile.dart';
import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/features/settings/usecases/app_appearance_profile_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const AppAppearanceProfileSection({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraColumn(
    children: [
      const AuraText(
        child: TextLocale(LocaleKeys.settings_screen_appearance_profile_title),
        style: .bodyLarge,
      ),
      const AuraText(
        child: TextLocale(
          LocaleKeys.settings_screen_appearance_profile_description,
        ),
        style: .bodySmall,
      ),
      AuraWrap(
        children: [
          AuraButton(
            onPressed: () => _exportProfile(context, ref),
            child: const TextLocale(
              LocaleKeys.settings_screen_appearance_profile_export,
            ),
            variant: .outlined,
            identifier: 'settings_appearance_profile_export',
          ),
          AuraButton(
            onPressed: () => _importProfile(context, ref),
            child: const TextLocale(
              LocaleKeys.settings_screen_appearance_profile_import,
            ),
            variant: .outlined,
            identifier: 'settings_appearance_profile_import',
          ),
        ],
      ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

Future<void> _exportProfile(BuildContext context, WidgetRef ref) async {
  try {
    final theme = ref.read(themeProvider).asData?.value ?? AppTheme.system;
    final accentHue =
        ref.read(accentHueProvider).asData?.value ?? AccentHue.defaultValue;
    final saved = await ref
        .read(appAppearanceProfileUsecaseProvider)
        .exportProfile(.new(themeMode: theme.name, accentHue: accentHue));
    if (!context.mounted || !saved) return;

    _showProfileFeedback(
      context,
      const TextLocale(
        LocaleKeys.settings_screen_appearance_profile_export_success,
      ),
      variant: .success,
    );
  } on Object catch (_) {
    if (!context.mounted) return;
    _showProfileFeedback(
      context,
      const TextLocale(
        LocaleKeys.settings_screen_appearance_profile_action_failed,
      ),
      variant: .error,
    );
  }
}

Future<void> _importProfile(BuildContext context, WidgetRef ref) async {
  try {
    final profile = await ref
        .read(appAppearanceProfileUsecaseProvider)
        .pickProfilePreview();
    if (profile == null || !context.mounted) return;

    final shouldApply = await AuraDialogs.confirm(
      context: context,
      title: const TextLocale(
        LocaleKeys.settings_screen_appearance_profile_preview_title,
      ),
      message: _AppearanceProfilePreview(profile: profile),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(
          LocaleKeys.settings_screen_appearance_profile_apply,
        ),
        cancelLabel: TextLocale(LocaleKeys.settings_screen_actions_cancel),
      ),
    );
    if (shouldApply != true || !context.mounted) return;

    await ref
        .read(themeProvider.notifier)
        .setTheme(AppTheme.values.byName(profile.themeMode));
    await ref.read(accentHueProvider.notifier).setHue(profile.accentHue);
    if (!context.mounted) return;

    _showProfileFeedback(
      context,
      const TextLocale(
        LocaleKeys.settings_screen_appearance_profile_import_success,
      ),
      variant: .success,
    );
  } on AppAppearanceProfileException catch (error) {
    if (!context.mounted) return;
    final errorContent = switch (error.localizationKey) {
      'settings_screen.appearance_profile.unsupported_version' =>
        const TextLocale(
          LocaleKeys.settings_screen_appearance_profile_unsupported_version,
        ),
      _ => const TextLocale(
        LocaleKeys.settings_screen_appearance_profile_invalid_file,
      ),
    };
    _showProfileFeedback(context, errorContent, variant: .error);
  } on Object catch (_) {
    if (!context.mounted) return;
    _showProfileFeedback(
      context,
      const TextLocale(
        LocaleKeys.settings_screen_appearance_profile_action_failed,
      ),
      variant: .error,
    );
  }
}

class const _AppearanceProfilePreview({
  required final AppAppearanceProfile profile,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeLabel = switch (profile.themeMode) {
      'light' => const TextLocale(LocaleKeys.settings_screen_theme_light),
      'dark' => const TextLocale(LocaleKeys.settings_screen_theme_dark),
      _ => const TextLocale(LocaleKeys.settings_screen_theme_system),
    };
    final brightness = Theme.of(context).brightness == Brightness.dark
        ? AuraBrightness.dark
        : AuraBrightness.light;
    final accent = AuraComputedColorScheme(
      primaryHue: profile.accentHue,
      brightness: brightness,
    ).primary;

    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(
            LocaleKeys.settings_screen_appearance_profile_preview_scope,
          ),
          style: .bodySmall,
        ),
        AuraColumn(
          children: [
            const AuraText(
              child: TextLocale(
                LocaleKeys.settings_screen_appearance_profile_theme,
              ),
              style: .bodySmall,
            ),
            themeLabel,
          ],
          spacing: .xs,
          crossAxisAlignment: .start,
        ),
        AuraColumn(
          children: [
            const AuraText(
              child: TextLocale(
                LocaleKeys.settings_screen_appearance_profile_accent_color,
              ),
              style: .bodySmall,
            ),
            AuraRow(
              children: [
                Semantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      border: Border.all(
                        color: context.auraColors.outlineVariant,
                      ),
                      shape: .circle,
                    ),
                    child: const SizedBox(width: 24, height: 24),
                  ),
                  label: LocaleKeys
                      .settings_screen_appearance_profile_accent_color
                      .tr(),
                  value: LocaleKeys
                      .settings_screen_appearance_profile_accent_hue_value
                      .tr(
                        namedArgs: {
                          'hue': profile.accentHue.toStringAsFixed(1),
                        },
                      ),
                ),
                Text(
                  LocaleKeys.settings_screen_appearance_profile_accent_hue_value
                      .tr(
                        namedArgs: {
                          'hue': profile.accentHue.toStringAsFixed(1),
                        },
                      ),
                ),
              ],
              spacing: .sm,
            ),
          ],
          spacing: .xs,
          crossAxisAlignment: .start,
        ),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

void _showProfileFeedback(
  BuildContext context,
  Widget content, {
  required AuraSnackBarVariant variant,
}) {
  final _ = AuraSnackBars.show(
    context: context,
    content: content,
    variant: variant,
  );
}
