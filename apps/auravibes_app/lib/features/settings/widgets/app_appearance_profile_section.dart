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
      const _AppearanceProfileHeading(),
      _AppearanceProfileActions(
        onExport: () => _exportProfile(context, ref),
        onImport: () => _importProfile(context, ref),
      ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _AppearanceProfileHeading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
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
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _AppearanceProfileActions({
  required final VoidCallback onExport,
  required final VoidCallback onImport,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraWrap(
    children: [
      _AppearanceProfileActionButton(
        label: const TextLocale(
          LocaleKeys.settings_screen_appearance_profile_export,
        ),
        onPressed: onExport,
        identifier: 'settings_appearance_profile_export',
      ),
      _AppearanceProfileActionButton(
        label: const TextLocale(
          LocaleKeys.settings_screen_appearance_profile_import,
        ),
        onPressed: onImport,
        identifier: 'settings_appearance_profile_import',
      ),
    ],
  );
}

class const _AppearanceProfileActionButton({
  required final Widget label,
  required final VoidCallback onPressed,
  required final String identifier,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: label,
    variant: .outlined,
    identifier: identifier,
  );
}

Future<void> _exportProfile(BuildContext context, WidgetRef ref) async {
  try {
    final saved = await ref
        .read(appAppearanceProfileUsecaseProvider)
        .exportProfile(_currentAppearanceProfile(ref));
    if (saved) _showExportSuccess(context);
  } on Object catch (_) {
    _showActionFailure(context);
  }
}

AppAppearanceProfile _currentAppearanceProfile(WidgetRef ref) {
  final theme = ref.read(themeProvider).asData?.value ?? AppTheme.system;
  final accentHue =
      ref.read(accentHueProvider).asData?.value ?? AccentHue.defaultValue;

  return .new(themeMode: theme.name, accentHue: accentHue);
}

Future<void> _importProfile(BuildContext context, WidgetRef ref) async {
  try {
    await _startAppearanceImport(context, ref);
  } on AppAppearanceProfileException catch (error) {
    _showImportError(context, error);
  } on Object catch (_) {
    _showActionFailure(context);
  }
}

Future<void> _startAppearanceImport(BuildContext context, WidgetRef ref) async {
  final profile = await ref
      .read(appAppearanceProfileUsecaseProvider)
      .pickProfilePreview();
  if (profile == null || !context.mounted) return;

  final shouldApply = await _confirmAppearanceProfile(context, profile);
  if (!shouldApply || !context.mounted) return;

  await _applyAppearanceProfile(context, ref, profile);
}

Future<bool> _confirmAppearanceProfile(
  BuildContext context,
  AppAppearanceProfile profile,
) async {
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

  return shouldApply == true;
}

Future<void> _applyAppearanceProfile(
  BuildContext context,
  WidgetRef ref,
  AppAppearanceProfile profile,
) async {
  await ref
      .read(themeProvider.notifier)
      .setTheme(AppTheme.values.byName(profile.themeMode));
  await ref.read(accentHueProvider.notifier).setHue(profile.accentHue);
  _showImportSuccess(context);
}

void _showImportError(
  BuildContext context,
  AppAppearanceProfileException error,
) {
  if (!context.mounted) return;
  final message = switch (error.localizationKey) {
    'settings_screen.appearance_profile.unsupported_version' =>
      const TextLocale(
        LocaleKeys.settings_screen_appearance_profile_unsupported_version,
      ),
    _ => const TextLocale(
      LocaleKeys.settings_screen_appearance_profile_invalid_file,
    ),
  };
  _showProfileFeedback(context, message, variant: .error);
}

void _showExportSuccess(BuildContext context) {
  if (!context.mounted) return;
  _showProfileFeedback(
    context,
    const TextLocale(
      LocaleKeys.settings_screen_appearance_profile_export_success,
    ),
    variant: .success,
  );
}

void _showImportSuccess(BuildContext context) {
  if (!context.mounted) return;
  _showProfileFeedback(
    context,
    const TextLocale(
      LocaleKeys.settings_screen_appearance_profile_import_success,
    ),
    variant: .success,
  );
}

void _showActionFailure(BuildContext context) {
  if (!context.mounted) return;
  _showProfileFeedback(
    context,
    const TextLocale(
      LocaleKeys.settings_screen_appearance_profile_action_failed,
    ),
    variant: .error,
  );
}

class const _AppearanceProfilePreview({
  required final AppAppearanceProfile profile,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraText(
        child: TextLocale(
          LocaleKeys.settings_screen_appearance_profile_preview_scope,
        ),
        style: .bodySmall,
      ),
      _AppearanceProfileThemePreview(themeMode: profile.themeMode),
      _AppearanceProfileAccentPreview(accentHue: profile.accentHue),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class const _AppearanceProfileThemePreview({required final String themeMode})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraText(
        child: TextLocale(LocaleKeys.settings_screen_appearance_profile_theme),
        style: .bodySmall,
      ),
      _AppearanceProfileThemeValue(themeMode: themeMode),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _AppearanceProfileThemeValue({required final String themeMode})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (themeMode) {
    'light' => const TextLocale(LocaleKeys.settings_screen_theme_light),
    'dark' => const TextLocale(LocaleKeys.settings_screen_theme_dark),
    _ => const TextLocale(LocaleKeys.settings_screen_theme_system),
  };
}

class const _AppearanceProfileAccentPreview({required final double accentHue})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraText(
        child: TextLocale(
          LocaleKeys.settings_screen_appearance_profile_accent_color,
        ),
        style: .bodySmall,
      ),
      AuraRow(
        children: [
          _AppearanceProfileAccentSwatch(accentHue: accentHue),
          _AppearanceProfileAccentHueValue(accentHue: accentHue),
        ],
        spacing: .sm,
      ),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _AppearanceProfileAccentSwatch({required final double accentHue})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _AppearanceProfileColorDot(
      accent: _appearanceProfileAccentColor(context, accentHue),
      outline: context.auraColors.outlineVariant,
    ),
    label: LocaleKeys.settings_screen_appearance_profile_accent_color.tr(),
    value: _appearanceProfileHueLabel(accentHue),
  );
}

class const _AppearanceProfileColorDot({
  required final Color accent,
  required final Color outline,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: accent,
      border: Border.all(color: outline),
      shape: .circle,
    ),
    child: const SizedBox(width: 24, height: 24),
  );
}

class const _AppearanceProfileAccentHueValue({required final double accentHue})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text(_appearanceProfileHueLabel(accentHue));
}

Color _appearanceProfileAccentColor(BuildContext context, double hue) {
  final brightness = Theme.of(context).brightness == Brightness.dark
      ? AuraBrightness.dark
      : AuraBrightness.light;

  return AuraComputedColorScheme(
    primaryHue: hue,
    brightness: brightness,
  ).primary;
}

String _appearanceProfileHueLabel(double hue) => LocaleKeys
    .settings_screen_appearance_profile_accent_hue_value
    .tr(namedArgs: {'hue': hue.toStringAsFixed(1)});

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
