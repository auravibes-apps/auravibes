// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/features/settings/widgets/compaction_settings_section.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);
    final currentTheme = themeAsync.asData?.value ?? AppTheme.system;

    return AuraScreen(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AuraColumn(
          children: [
            AuraCard(
              child: AuraColumn(
                children: [
                  const AuraText(
                    child: TextLocale(
                      LocaleKeys.settings_screen_app_settings_title,
                    ),
                    style: AuraTextStyle.heading6,
                    color: AuraColorVariant.onSurface,
                  ),
                  const AuraText(
                    child: TextLocale(
                      LocaleKeys.settings_screen_app_settings_subtitle,
                    ),
                    style: AuraTextStyle.bodySmall,
                    color: AuraColorVariant.onSurfaceVariant,
                  ),
                  AuraTile(
                    child: const AuraText(
                      child: TextLocale(LocaleKeys.settings_screen_theme_title),
                      style: AuraTextStyle.bodyLarge,
                    ),
                    onTap: () {
                      _showThemeDialog(context, ref, currentTheme);
                    },
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
                  ),
                ],
                spacing: .none,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
            CompactionSettingsSection(workspaceId: workspaceId),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.settings_screen_title),
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
    showAuraAlertDialog(
      context: context,
      title: const TextLocale(LocaleKeys.settings_screen_theme_title),
      message: AuraRadioGroup<AppTheme>(
        value: currentTheme,
        onChanged: (value) {
          if (value != null) {
            ref.read(themeProvider.notifier).setTheme(value);
            Navigator.pop(context);
          }
        },
        options: const [
          AuraRadioOption(
            value: AppTheme.system,
            label: TextLocale(
              LocaleKeys.settings_screen_theme_system_default,
            ),
          ),
          AuraRadioOption(
            value: AppTheme.light,
            label: TextLocale(LocaleKeys.settings_screen_theme_light),
          ),
          AuraRadioOption(
            value: AppTheme.dark,
            label: TextLocale(LocaleKeys.settings_screen_theme_dark),
          ),
        ],
      ),
      dismissLabel: const TextLocale(
        LocaleKeys.settings_screen_actions_cancel,
      ),
    );
  }
}
