import 'package:auravibes_app/features/settings/providers/theme_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeControllerProvider);
    final currentTheme = themeAsync.asData?.value ?? AppTheme.system;

    return AuraScreen(
      appBar: const AuraAppBar(
        title: TextLocale(LocaleKeys.settings_screen_title),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AuraColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Settings Section
            AuraCard(
              child: AuraColumn(
                spacing: .none,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuraText(
                    style: AuraTextStyle.heading6,
                    color: AuraColorVariant.onSurface,
                    child: TextLocale(
                      LocaleKeys.settings_screen_app_settings_title,
                    ),
                  ),
                  const AuraText(
                    style: AuraTextStyle.bodySmall,
                    color: AuraColorVariant.onSurfaceVariant,
                    child: TextLocale(
                      LocaleKeys.settings_screen_app_settings_subtitle,
                    ),
                  ),
                  AuraTile(
                    variant: AuraTileVariant.ghost,
                    leading: Icon(
                      Icons.palette_outlined,
                      color: context.auraColors.secondary,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextLocale(
                          _getThemeName(currentTheme),
                          style: TextStyle(
                            color: context.auraColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: context.auraColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () {
                      _showThemeDialog(context, ref, currentTheme);
                    },
                    child: const AuraText(
                      style: AuraTextStyle.bodyLarge,
                      child: TextLocale(LocaleKeys.settings_screen_theme_title),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return LocaleKeys.settings_screen_theme_light;
      case AppTheme.dark:
        return LocaleKeys.settings_screen_theme_dark;
      case AppTheme.system:
        return LocaleKeys.settings_screen_theme_system;
    }
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppTheme currentTheme,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TextLocale(LocaleKeys.settings_screen_theme_title),
        content: RadioGroup(
          groupValue: currentTheme,
          onChanged: (value) {
            if (value != null) {
              ref.read(themeControllerProvider.notifier).setTheme(value);
              Navigator.pop(context);
            }
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppTheme>(
                title: TextLocale(
                  LocaleKeys.settings_screen_theme_system_default,
                ),
                value: AppTheme.system,
              ),
              RadioListTile<AppTheme>(
                title: TextLocale(LocaleKeys.settings_screen_theme_light),
                value: AppTheme.light,
              ),
              RadioListTile<AppTheme>(
                title: TextLocale(LocaleKeys.settings_screen_theme_dark),
                value: AppTheme.dark,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TextLocale(LocaleKeys.settings_screen_actions_cancel),
          ),
        ],
      ),
    );
  }
}
