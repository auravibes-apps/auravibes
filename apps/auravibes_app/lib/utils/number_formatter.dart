import 'dart:ui';

import 'package:intl/intl.dart';

/// Formats a visible count using the active locale's grouping separators.
String formatCount(num value, Locale locale) =>
    NumberFormat.decimalPattern(locale.toLanguageTag()).format(value);

/// Formats a visible decimal with exactly [digits] fraction digits.
String formatDecimal(num value, Locale locale, int digits) =>
    NumberFormat.decimalPatternDigits(
      locale: locale.toLanguageTag(),
      decimalDigits: digits,
    ).format(value);
