// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.

import 'dart:async';

import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/settings/models/app_language_preference.dart';
import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/features/settings/providers/app_language_preference_provider.dart';
import 'package:auravibes_app/features/settings/widgets/accent_color_section.dart';
import 'package:auravibes_app/features/settings/widgets/app_appearance_profile_section.dart';
import 'package:auravibes_app/features/settings/widgets/app_version_indicator.dart';
import 'package:auravibes_app/features/settings/widgets/legal_links_section.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _settingsAppBar = AuraAppBarWithDrawer(
  title: TextLocale(LocaleKeys.settings_screen_title),
);
const _appearanceHeader = AuraColumn(
  children: [
    AuraText(
      child: TextLocale(LocaleKeys.settings_screen_app_settings_title),
      style: .heading6,
    ),
    AuraText(
      child: TextLocale(LocaleKeys.settings_screen_app_settings_subtitle),
      style: .bodySmall,
    ),
  ],
  spacing: .none,
  crossAxisAlignment: .start,
);
const _themeOptions = <AuraChoiceOption<AppTheme>>[
  AuraChoiceOption(
    value: AppTheme.system,
    label: TextLocale(LocaleKeys.settings_screen_theme_system),
  ),
  AuraChoiceOption(
    value: AppTheme.light,
    label: TextLocale(LocaleKeys.settings_screen_theme_light),
  ),
  AuraChoiceOption(
    value: AppTheme.dark,
    label: TextLocale(LocaleKeys.settings_screen_theme_dark),
  ),
];
const _settingsScreenPadding = 16.0;
const _themeTileArrowSize = 16.0;
const _languageTitleKey = 'settings_screen.language.title';
const _languageDialogTitleKey = 'settings_screen.language.dialog_title';
const _languageEnglishKey = 'settings_screen.language.english';
const _languageSpanishKey = 'settings_screen.language.spanish';
const _languageDeviceKey = 'settings_screen.language.device';
const _languageOptions = <AuraChoiceOption<AppLanguagePreference>>[
  AuraChoiceOption(
    value: AppLanguagePreference.system,
    label: TextLocale(_languageDeviceKey),
  ),
  AuraChoiceOption(
    value: AppLanguagePreference.english,
    label: TextLocale(_languageEnglishKey),
  ),
  AuraChoiceOption(
    value: AppLanguagePreference.spanish,
    label: TextLocale(_languageSpanishKey),
  ),
];

class const SettingsScreen({required final String workspaceId, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SettingsPage(workspaceId: workspaceId);
}

class const _SettingsPage({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme =
        ref.watch(themeProvider).asData?.value ?? AppTheme.system;

    return _SettingsPageSurface(
      workspaceId: workspaceId,
      currentTheme: currentTheme,
      onThemeTap: () => _showThemeDialog(context, ref, currentTheme),
      onAppearanceReset: () => _resetAppearance(ref),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppTheme currentTheme,
  ) {
    AuraDialogs.alert(
      context: context,
      title: const TextLocale(LocaleKeys.settings_screen_theme_title),
      message: _ThemeChoicePicker(
        currentTheme: currentTheme,
        onChanged: (values) => _handleThemeChanged(context, ref, values),
      ),
      dismissLabel: const TextLocale(LocaleKeys.settings_screen_actions_cancel),
    );
  }

  void _handleThemeChanged(
    BuildContext context,
    WidgetRef ref,
    List<AppTheme> values,
  ) {
    final selected = values.firstOrNull;
    if (selected == null) return;
    Navigator.of(context, rootNavigator: true).pop();
    ref.read(themeProvider.notifier).setTheme(selected);
  }
}

void _resetAppearance(WidgetRef ref) {
  ref.read(themeProvider.notifier).setTheme(.system);
  ref.read(accentHueProvider.notifier).setHue(AccentHue.defaultValue);
}

bool _hasAppearanceChanges(WidgetRef ref, AppTheme theme) {
  final accentHue =
      ref.watch(accentHueProvider).asData?.value ?? AccentHue.defaultValue;

  return theme != AppTheme.system || accentHue != AccentHue.defaultValue;
}

class const _SettingsPageSurface({
  required final String workspaceId,
  required final AppTheme currentTheme,
  required final VoidCallback onThemeTap,
  required final VoidCallback onAppearanceReset,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: _SettingsBody(
      workspaceId: workspaceId,
      currentTheme: currentTheme,
      onThemeTap: onThemeTap,
      onAppearanceReset: onAppearanceReset,
    ),
    appBar: _settingsAppBar,
  );
}

class const _ThemeChoicePicker({
  required final AppTheme currentTheme,
  required final ValueChanged<List<AppTheme>> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraChoicePicker<AppTheme>(
    options: _themeOptions,
    value: [currentTheme],
    onChanged: onChanged,
  );
}

class const _SettingsBody({
  required final String workspaceId,
  required final AppTheme currentTheme,
  required final VoidCallback onThemeTap,
  required final VoidCallback onAppearanceReset,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_settingsScreenPadding)
          .copyWith(bottom: BottomPadding.of(context)),
      child: AuraColumn(
        children: [
          _AppearanceCard(
            currentTheme: currentTheme,
            onThemeTap: onThemeTap,
            onReset: onAppearanceReset,
          ),
          const LegalLinksSection(),
          const AppVersionIndicator(),
        ],
        crossAxisAlignment: .start,
      ),
      keyboardDismissBehavior: .onDrag,
    );
  }
}

class const _AppearanceCard({
  required final AppTheme currentTheme,
  required final VoidCallback onThemeTap,
  required final VoidCallback onReset,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraCard(
      child: AuraColumn(
        children: [
          _appearanceHeader,
          _ThemeTile(theme: currentTheme, onTap: onThemeTap),
          _LanguageTile(
            preference:
                ref.watch(appLanguagePreferenceProvider).asData?.value ??
                AppLanguagePreference.system,
            onTap: () => _showLanguageDialog(context, ref),
          ),
          const AccentColorSection(),
          if (_hasAppearanceChanges(ref, currentTheme))
            _AppearanceResetButton(onPressed: onReset),
          const AuraSizedBox(height: .md),
          const AppAppearanceProfileSection(),
        ],
        spacing: .none,
        crossAxisAlignment: .start,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final preference =
        ref.read(appLanguagePreferenceProvider).asData?.value ??
        AppLanguagePreference.system;
    AuraDialogs.alert(
      context: context,
      title: const TextLocale(_languageDialogTitleKey),
      message: _LanguageChoicePicker(
        preference: preference,
        onChanged: (values) => _handleLanguageChanged(context, ref, values),
      ),
      dismissLabel: const TextLocale(LocaleKeys.settings_screen_actions_cancel),
    );
  }

  void _handleLanguageChanged(
    BuildContext context,
    WidgetRef ref,
    List<AppLanguagePreference> values,
  ) {
    final preference = values.firstOrNull;
    if (preference == null) return;
    Navigator.of(context, rootNavigator: true).pop();
    unawaited(_applyLanguagePreference(context, ref, preference));
  }
}

Future<void> _applyLanguagePreference(
  BuildContext context,
  WidgetRef ref,
  AppLanguagePreference preference,
) async {
  final locale = preference.locale;
  if (locale == null) {
    await context.resetLocale();
    await context.deleteSaveLocale();
  } else {
    await context.setLocale(locale);
  }

  await ref.read(appLanguagePreferenceProvider.notifier).save(preference);
}

class const _AppearanceResetButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Align(
    alignment: .centerRight,
    child: AuraButton(
      onPressed: onPressed,
      child: const TextLocale(
        LocaleKeys.settings_screen_actions_reset_appearance,
      ),
      variant: .ghost,
      size: .small,
      identifier: 'settings_appearance_reset',
    ),
  );
}

class const _ThemeTile({
  required final AppTheme theme,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: const AuraText(
      child: TextLocale(LocaleKeys.settings_screen_theme_title),
      style: .bodyLarge,
    ),
    onTap: onTap,
    variant: .ghost,
    leading: _ThemeTileIcon(color: context.auraColors.secondary),
    trailing: _ThemeTileTrailing(theme: theme),
    identifier: 'settings_theme',
  );
}

class const _ThemeTileTrailing({required final AppTheme theme})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      _ThemeTileLabel(theme: theme, color: context.auraColors.onSurfaceVariant),
      const SizedBox(width: 8),
      _ThemeTileArrow(color: context.auraColors.onSurfaceVariant),
    ],
  );
}

class const _ThemeTileLabel({
  required final AppTheme theme,
  required final Color color,
}) extends StatelessWidget {
  static const _fontSize = 14.0;

  @override
  Widget build(BuildContext context) => TextLocale(
    _themeName(theme),
    style: .new(color: color, fontSize: _fontSize),
  );
}

class const _ThemeTileArrow({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.arrow_forward_ios, size: _themeTileArrowSize, color: color);
}

class const _ThemeTileIcon({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.brightness_6_outlined, color: color);
}

class const _LanguageTile({
  required final AppLanguagePreference preference,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: const AuraText(
      child: TextLocale(_languageTitleKey),
      style: .bodyLarge,
    ),
    onTap: onTap,
    variant: .ghost,
    leading: Icon(Icons.language, color: context.auraColors.secondary),
    trailing: _LanguageTileTrailing(
      preference: preference,
      color: context.auraColors.onSurfaceVariant,
    ),
    identifier: 'settings_language',
  );
}

class const _LanguageTileTrailing({
  required final AppLanguagePreference preference,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      TextLocale(preference.labelKey, style: .new(color: color, fontSize: 14)),
      const SizedBox(width: 8),
      _ThemeTileArrow(color: color),
    ],
  );
}

class const _LanguageChoicePicker({
  required final AppLanguagePreference preference,
  required final ValueChanged<List<AppLanguagePreference>> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraChoicePicker<AppLanguagePreference>(
    options: _languageOptions,
    value: [preference],
    onChanged: onChanged,
  );
}

String _themeName(AppTheme theme) => switch (theme) {
  .light => LocaleKeys.settings_screen_theme_light,
  .dark => LocaleKeys.settings_screen_theme_dark,
  .system => LocaleKeys.settings_screen_theme_system,
};
