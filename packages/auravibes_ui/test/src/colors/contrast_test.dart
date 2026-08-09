import 'package:auravibes_ui/src/colors/contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('apcaLc', () {
    test('positive for dark foreground on light background', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      expect(apcaLc(foreground: black, background: white), greaterThan(90));
      expect(apcaLc(foreground: black, background: white), isPositive);
    });

    test('matches APCA black soft clamp reference values', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);

      expect(
        apcaLc(foreground: black, background: white),
        closeTo(106.04, 0.01),
      );
      expect(
        apcaLc(foreground: white, background: black),
        closeTo(-107.88, 0.01),
      );
    });

    test('negative for light foreground on dark background', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      // APCA black soft clamp yields a stronger reverse-polarity value.
      // Exact reference values are covered above.
      expect(apcaLc(foreground: white, background: black), lessThan(-90));
      expect(apcaLc(foreground: white, background: black), isNegative);
    });

    test('near zero when foreground equals background', () {
      const gray = Color(0xFF808080);
      expect(apcaLc(foreground: gray, background: gray).abs(), lessThan(1));
    });

    test('magnitude increases with contrast', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      const midGray = Color(0xFF777777);
      final high = apcaLc(foreground: black, background: white).abs();
      final low = apcaLc(foreground: midGray, background: white).abs();
      expect(high, greaterThan(low));
    });
  });

  group('wcagContrastRatio', () {
    test('black/white equals 21', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      expect(wcagContrastRatio(black, white), closeTo(21, 0.5));
    });

    test('identical colors equals 1', () {
      const gray = Color(0xFF808080);
      expect(wcagContrastRatio(gray, gray), closeTo(1, 1e-9));
    });

    test('symmetric: order-independent', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      expect(wcagContrastRatio(black, white), wcagContrastRatio(white, black));
    });

    test('AA 4.5 threshold for teal vs white', () {
      // Aura primary base teal, expects ~4.5+ against white.
      const teal = Color(0xFF0F766E);
      expect(
        wcagContrastRatio(teal, const Color(0xFFFFFFFF)),
        greaterThan(4.5),
      );
    });
  });
}
