import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

export 'package:easy_localization/easy_localization.dart'
    show BuildContextEasyLocalizationExtension;

class MainLocale extends StatelessWidget {
  const MainLocale({required this.child, super.key});
  final Widget child;

  static const supportedLocales = [Locale('en'), Locale('es')];
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

  static Future<void> ensureInitialized() {
    return EasyLocalization.ensureInitialized();
  }
}
