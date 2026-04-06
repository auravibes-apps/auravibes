import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:easy_localization/easy_localization.dart';

class RelativeTimeFormatter {
  const RelativeTimeFormatter();

  String format(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) {
      return LocaleKeys.home_screen_date_formatting_just_now.tr();
    }
    if (diff.inHours < 1) {
      return LocaleKeys.home_screen_date_formatting_minutes_ago.tr(
        args: [diff.inMinutes.toString()],
      );
    }
    if (diff.inDays < 1) {
      return LocaleKeys.home_screen_date_formatting_hours_ago.tr(
        args: [diff.inHours.toString()],
      );
    }
    return LocaleKeys.home_screen_date_formatting_days_ago.tr(
      args: [diff.inDays.toString()],
    );
  }
}
