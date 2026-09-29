import 'dart:ui';

import 'package:auravibes_app/utils/number_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats grouped counts for English and Spanish', () {
    expect(NumberFormatter.count(1234567, const Locale('en')), '1,234,567');
    expect(NumberFormatter.count(1234567, const Locale('es')), '1.234.567');
    expect(NumberFormatter.count(-1234, const Locale('es')), '-1.234');
    expect(NumberFormatter.count(0, const Locale('en')), '0');
  });

  test('formats fixed decimals for English and Spanish', () {
    expect(NumberFormatter.decimal(1234.5, const Locale('en'), 1), '1,234.5');
    expect(NumberFormatter.decimal(1234.5, const Locale('es'), 1), '1.234,5');
    expect(NumberFormatter.decimal(1234.5, const Locale('en'), 2), '1,234.50');
  });
}
