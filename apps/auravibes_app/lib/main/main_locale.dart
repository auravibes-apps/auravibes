import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

export 'package:easy_localization/easy_localization.dart'
    show BuildContextEasyLocalizationExtension;

class const MainLocale({required final Widget child, super.key})
    extends StatelessWidget {
  static const supportedLocales = [Locale('en'), Locale('es')];
  static Future<void> ensureInitialized() async {
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      child: child,
      supportedLocales: MainLocale.supportedLocales,
      path: 'assets/i18n',
      fallbackLocale: MainLocale.supportedLocales.firstOrNull,
      useOnlyLangCode: true,
      useFallbackTranslations: true,
      useFallbackTranslationsForEmptyResources: true,
    );
  }
}
