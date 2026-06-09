// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

export 'package:easy_localization/easy_localization.dart'
    show BuildContextEasyLocalizationExtension;

const supportedLocales = [Locale('en'), Locale('es')];

class MainLocale extends StatelessWidget {
  const MainLocale({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      child: child,
      supportedLocales: supportedLocales,
      path: 'assets/i18n',
      fallbackLocale: supportedLocales.firstOrNull,
      useOnlyLangCode: true,
      useFallbackTranslations: true,
      useFallbackTranslationsForEmptyResources: true,
    );
  }

  static Future<void> ensureInitialized() {
    return EasyLocalization.ensureInitialized();
  }
}
