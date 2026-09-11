import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:easy_localization/easy_localization.dart';

typedef TranslateFunc = String Function(String key, {List<String>? args});

abstract final class RelativeTimeFormatter {
  static String format(
    DateTime timestamp, {
    DateTime? now,
    TranslateFunc translate = _defaultTranslate,
  }) => _translateDifference(
    (now ?? DateTime.now()).difference(timestamp),
    translate,
  );

  static String _translateDifference(Duration diff, TranslateFunc translate) {
    final bucket = _bucketFor(diff);
    final key = bucket.localizationKey;
    if (bucket == _RelativeTimeBucket.justNow) return translate(key);

    return _translateCount(translate, key, bucket.count(diff));
  }

  static _RelativeTimeBucket _bucketFor(Duration diff) {
    if (diff.isNegative || diff.inMinutes < 1) {
      return .justNow;
    }
    if (diff.inHours < 1) return .minutes;
    if (diff.inDays < 1) return .hours;

    return .days;
  }

  static String _translateCount(
    TranslateFunc translate,
    String key,
    int count,
  ) => translate(key, args: [count.toString()]);

  static String _defaultTranslate(String key, {List<String>? args}) =>
      key.tr(args: args ?? const []);
}

enum _RelativeTimeBucket { justNow, minutes, hours, days }

extension on _RelativeTimeBucket {
  String get localizationKey => switch (this) {
    .justNow => LocaleKeys.home_screen_date_formatting_just_now,
    .minutes => LocaleKeys.home_screen_date_formatting_minutes_ago,
    .hours => LocaleKeys.home_screen_date_formatting_hours_ago,
    .days => LocaleKeys.home_screen_date_formatting_days_ago,
  };

  int count(Duration duration) => switch (this) {
    .justNow => 0,
    .minutes => duration.inMinutes,
    .hours => duration.inHours,
    .days => duration.inDays,
  };
}
