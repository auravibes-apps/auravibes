// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/features/settings/widgets/accent_color_section.dart';
import 'package:auravibes_app/features/settings/widgets/compaction_settings_section.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _settingsAppBar = AuraAppBarWithDrawer(
  title: TextLocale(LocaleKeys.settings_screen_title),
);
const _appSettingsHeader = AuraColumn(
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
    label: TextLocale(LocaleKeys.settings_screen_theme_system_default),
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

class const _SettingsPageSurface({
  required final String workspaceId,
  required final AppTheme currentTheme,
  required final VoidCallback onThemeTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: _SettingsBody(
      workspaceId: workspaceId,
      currentTheme: currentTheme,
      onThemeTap: onThemeTap,
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
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_settingsScreenPadding),
      child: AuraColumn(
        children: [
          _AppSettingsCard(currentTheme: currentTheme, onThemeTap: onThemeTap),
          CompactionSettingsSection(workspaceId: workspaceId),
          const AccentColorSection(),
        ],
        crossAxisAlignment: .start,
      ),
    );
  }
}

class const _AppSettingsCard({
  required final AppTheme currentTheme,
  required final VoidCallback onThemeTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          _appSettingsHeader,
          _ThemeTile(theme: currentTheme, onTap: onThemeTap),
        ],
        spacing: .none,
        crossAxisAlignment: .start,
      ),
    );
  }
}

class const _ThemeTile({
  required final AppTheme theme,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: const AuraText(
        child: TextLocale(LocaleKeys.settings_screen_theme_title),
        style: .bodyLarge,
      ),
      onTap: onTap,
      variant: .ghost,
      leading: _ThemeTileIcon(color: context.auraColors.secondary),
      trailing: _ThemeTileTrailing(theme: theme),
    );
  }
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
      Icon(Icons.palette_outlined, color: color);
}

String _themeName(AppTheme theme) => switch (theme) {
  .light => LocaleKeys.settings_screen_theme_light,
  .dark => LocaleKeys.settings_screen_theme_dark,
  .system => LocaleKeys.settings_screen_theme_system,
};
