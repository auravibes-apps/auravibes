import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

String mockTranslate(String key, {List<String>? args}) {
  if (args != null && args.isNotEmpty) {
    return '$key:${args.first}';
  }
  return key;
}

void main() {
  late RelativeTimeFormatter formatter;

  setUp(() {
    formatter = const RelativeTimeFormatter();
  });

  group('boundary conditions', () {
    final now = DateTime(2026, 4, 5, 12);

    test('0 seconds ago → just now', () {
      final result = formatter.format(now, now: now, translate: mockTranslate);
      expect(result, LocaleKeys.home_screen_date_formatting_just_now);
    });

    test('59 seconds ago → just now', () {
      final timestamp = now.subtract(const Duration(seconds: 59));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(result, LocaleKeys.home_screen_date_formatting_just_now);
    });

    test('60 seconds ago → minutes ago with value 1', () {
      final timestamp = now.subtract(const Duration(seconds: 60));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(
        result,
        '${LocaleKeys.home_screen_date_formatting_minutes_ago}:1',
      );
    });

    test('59 minutes ago → minutes ago with value 59', () {
      final timestamp = now.subtract(const Duration(minutes: 59));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(
        result,
        '${LocaleKeys.home_screen_date_formatting_minutes_ago}:59',
      );
    });

    test('60 minutes ago → hours ago with value 1', () {
      final timestamp = now.subtract(const Duration(minutes: 60));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(
        result,
        '${LocaleKeys.home_screen_date_formatting_hours_ago}:1',
      );
    });

    test('23 hours ago → hours ago with value 23', () {
      final timestamp = now.subtract(const Duration(hours: 23));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(
        result,
        '${LocaleKeys.home_screen_date_formatting_hours_ago}:23',
      );
    });

    test('24 hours ago → days ago with value 1', () {
      final timestamp = now.subtract(const Duration(hours: 24));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(
        result,
        '${LocaleKeys.home_screen_date_formatting_days_ago}:1',
      );
    });

    test('future timestamp → just now', () {
      final timestamp = now.add(const Duration(hours: 2));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(result, LocaleKeys.home_screen_date_formatting_just_now);
    });

    test('far future timestamp → just now', () {
      final timestamp = now.add(const Duration(days: 365));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(result, LocaleKeys.home_screen_date_formatting_just_now);
    });
  });

  group('argument interpolation', () {
    final now = DateTime(2026, 4, 5, 12);

    test('5 minutes ago includes 5', () {
      final timestamp = now.subtract(const Duration(minutes: 5));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(result, contains('5'));
    });

    test('3 hours ago includes 3', () {
      final timestamp = now.subtract(const Duration(hours: 3));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(result, contains('3'));
    });

    test('7 days ago includes 7', () {
      final timestamp = now.subtract(const Duration(days: 7));
      final result = formatter.format(
        timestamp,
        now: now,
        translate: mockTranslate,
      );
      expect(result, contains('7'));
    });
  });
}
