import 'dart:async';

import 'package:auravibes_app/features/settings/models/app_language_preference.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:easy_localization/easy_localization.dart'
    show BuildContextEasyLocalizationExtension;

class const MainLocale({required final Widget child, super.key})
    extends StatelessWidget {
  static const supportedLocales = <Locale>[.new('en'), .new('es')];
  static AppLanguagePreference _languagePreference = .system;

  static Future<void> ensureInitialized() async {
    final preferences = await SharedPreferences.getInstance();
    _languagePreference = .fromStoredValue(
      preferences.getString(AppLanguagePreference.preferenceKey),
    );
    final _ = await preferences.remove(
      AppLanguagePreference.easyLocalizationPreferenceKey,
    );

    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      child: child,
      supportedLocales: MainLocale.supportedLocales,
      path: 'assets/i18n',
      startLocale: _languagePreference.locale,
      fallbackLocale: MainLocale.supportedLocales.firstOrNull,
      saveLocale: false,
      useOnlyLangCode: true,
      useFallbackTranslations: true,
      useFallbackTranslationsForEmptyResources: true,
    );
  }
}
