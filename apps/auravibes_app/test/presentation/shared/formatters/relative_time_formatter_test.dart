import 'package:auravibes_app/presentation/shared/formatters/relative_time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatRelativeTime', () {
    test('returns just now for less than a minute ago', () {
      final now = DateTime(2025, 1, 15, 12);
      final date = DateTime(2025, 1, 15, 11, 59, 30);
      expect(formatRelativeTime(date, now: now), 'Just now');
    });

    test('returns Xm ago for less than an hour ago', () {
      final now = DateTime(2025, 1, 15, 12);
      final date = DateTime(2025, 1, 15, 11, 50);
      expect(formatRelativeTime(date, now: now), '10m ago');
    });

    test('returns Xh ago for less than a day ago', () {
      final now = DateTime(2025, 1, 15, 12);
      final date = DateTime(2025, 1, 15, 9);
      expect(formatRelativeTime(date, now: now), '3h ago');
    });

    test('returns Xd ago for less than a week ago', () {
      final now = DateTime(2025, 1, 15, 12);
      final date = DateTime(2025, 1, 13, 12);
      expect(formatRelativeTime(date, now: now), '2d ago');
    });

    test('returns date for more than a week ago', () {
      final now = DateTime(2025, 1, 15);
      final date = DateTime(2025);
      expect(formatRelativeTime(date, now: now), '1/1/2025');
    });

    test('returns date for future dates', () {
      final now = DateTime(2025, 1, 10);
      final date = DateTime(2025, 1, 15);
      expect(formatRelativeTime(date, now: now), '15/1/2025');
    });

    test('uses DateTime.now() when now parameter is not provided', () {
      final result = formatRelativeTime(DateTime.now());
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });

    test('shows exact minute boundaries', () {
      final now = DateTime(2025, 1, 15, 12);
      final date = DateTime(2025, 1, 15, 11, 59);
      expect(formatRelativeTime(date, now: now), '1m ago');
    });

    test('shows 1h ago for exactly 1 hour', () {
      final now = DateTime(2025, 1, 15, 12);
      final date = DateTime(2025, 1, 15, 11);
      expect(formatRelativeTime(date, now: now), '1h ago');
    });

    test('shows 6d ago for 6 days within a week', () {
      final now = DateTime(2025, 1, 15, 12);
      final date = DateTime(2025, 1, 9, 12);
      expect(formatRelativeTime(date, now: now), '6d ago');
    });
  });
}
