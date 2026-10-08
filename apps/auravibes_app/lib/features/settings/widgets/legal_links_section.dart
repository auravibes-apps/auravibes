import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const LegalLinksSection({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.settings_screen_legal_title),
          style: .heading6,
        ),
        Semantics(
          key: const ValueKey<String>('settings_privacy'),
          child: AuraTile(
            child: const TextLocale(LocaleKeys.settings_screen_legal_privacy),
            onTap: () => _open(context, 'privacy'),
            variant: .ghost,
            trailing: const Icon(Icons.open_in_new),
          ),
          identifier: 'settings_privacy',
        ),
        Semantics(
          key: const ValueKey<String>('settings_terms'),
          child: AuraTile(
            child: const TextLocale(LocaleKeys.settings_screen_legal_terms),
            onTap: () => _open(context, 'terms'),
            variant: .ghost,
            trailing: const Icon(Icons.open_in_new),
          ),
          identifier: 'settings_terms',
        ),
      ],
      spacing: .none,
      crossAxisAlignment: .start,
    ),
  );

  Future<void> _open(BuildContext context, String document) async {
    final language = context.locale.languageCode == 'es' ? 'es' : 'en';
    try {
      await OpenSystemBrowser.call(
        .https('auravibes.me', '/$language/$document'),
      );
    } on Exception {
      if (!context.mounted) return;
      final _ = AuraSnackBars.show(
        context: context,
        content: const TextLocale(LocaleKeys.settings_screen_legal_open_error),
        variant: .error,
      );
    }
  }
}
