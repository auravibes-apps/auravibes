import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:easy_localization/easy_localization.dart';

typedef TranslateFunc = String Function(String key, {List<String>? args});

class RelativeTimeFormatter {
  const RelativeTimeFormatter();

  String format(
    DateTime timestamp, {
    DateTime? now,
    TranslateFunc? translate,
  }) {
    final diff = (now ?? DateTime.now()).difference(timestamp);
    final tr = translate ?? _defaultTranslate;

    if (diff.isNegative) {
      return tr(LocaleKeys.home_screen_date_formatting_just_now);
    }
    if (diff.inMinutes < 1) {
      return tr(LocaleKeys.home_screen_date_formatting_just_now);
    }
    if (diff.inHours < 1) {
      return tr(
        LocaleKeys.home_screen_date_formatting_minutes_ago,
        args: [diff.inMinutes.toString()],
      );
    }
    if (diff.inDays < 1) {
      return tr(
        LocaleKeys.home_screen_date_formatting_hours_ago,
        args: [diff.inHours.toString()],
      );
    }
    return tr(
      LocaleKeys.home_screen_date_formatting_days_ago,
      args: [diff.inDays.toString()],
    );
  }

  static String _defaultTranslate(String key, {List<String>? args}) =>
      key.tr(args: args ?? const []);
}
