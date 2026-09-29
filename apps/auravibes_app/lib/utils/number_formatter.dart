import 'dart:ui';

import 'package:intl/intl.dart';

abstract final class NumberFormatter {
  /// Formats a visible count using the active locale's grouping separators.
  static String count(num value, Locale locale) =>
      NumberFormat.decimalPattern(locale.toLanguageTag()).format(value);

  /// Formats a visible decimal with exactly [digits] fraction digits.
  static String decimal(num value, Locale locale, int digits) =>
      NumberFormat.decimalPatternDigits(
        locale: locale.toLanguageTag(),
        decimalDigits: digits,
      ).format(value);
}
