import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const LegalLinksSection({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => const AuraCard(
    child: AuraColumn(
      children: [
        AuraText(
          child: TextLocale(LocaleKeys.settings_screen_legal_title),
          style: .heading6,
        ),
        _LegalLinkTile(
          document: 'privacy',
          titleKey: LocaleKeys.settings_screen_legal_privacy,
        ),
        _LegalLinkTile(
          document: 'terms',
          titleKey: LocaleKeys.settings_screen_legal_terms,
        ),
      ],
      spacing: .none,
      crossAxisAlignment: .start,
    ),
  );
}

class const _LegalLinkTile({
  required final String document,
  required final String titleKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey<String>('settings_$document'),
    child: AuraTile(
      child: TextLocale(titleKey),
      onTap: () => _open(context),
      variant: .ghost,
      trailing: const Icon(Icons.open_in_new),
    ),
    identifier: 'settings_$document',
  );

  Future<void> _open(BuildContext context) async {
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
