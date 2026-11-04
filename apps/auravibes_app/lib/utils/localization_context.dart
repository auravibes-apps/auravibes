import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Access to the app's installed translations.
abstract final class LocalizationContext {
  /// Whether this context has the app's translations and delegate installed.
  static bool hasAppLocalizations(BuildContext context) {
    final localization = EasyLocalization.of(context);
    if (localization == null) return false;

    return Localizations.of<Object>(context, localization.delegate.type) !=
        null;
  }
}
