import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraColorRange', () {
    test('includes boundaries and rejects L/C outside the role', () {
      const range = AuraColorRange.lightPastel;
      expect(
        range.contains(.new(hue: 0, lightness: 0.89, chroma: 0.02)),
        isTrue,
      );
      expect(
        range.contains(.new(hue: 200, lightness: 0.95, chroma: 0.08)),
        isTrue,
      );
      expect(
        range.contains(.new(hue: 0, lightness: 0.88, chroma: 0.04)),
        isFalse,
      );
      expect(
        range.contains(.new(hue: 0, lightness: 0.92, chroma: 0.09)),
        isFalse,
      );
      expect(
        range.contains(.new(hue: 0, lightness: .nan, chroma: 0.04)),
        isFalse,
      );
      expect(
        range.contains(.new(hue: 0, lightness: 0.92, chroma: double.infinity)),
        isFalse,
      );
    });

    test('neutral ranges reject chroma', () {
      expect(
        () => AuraColorRange.lightCanvas.resolve(
          hue: 180,
          lightness: 0.99,
          chroma: 0.02,
        ),
        throwsArgumentError,
      );
    });

    test('reports a minimum chroma that cannot fit the gamut', () {
      const range = AuraColorRange(0.98, 0.99, 0.3, 0.4);
      expect(
        () => range.resolve(hue: 180, lightness: 0.985, chroma: 0.35),
        throwsArgumentError,
      );
    });

    test('all role boundaries fit sRGB across the one-degree hue grid', () {
      const ranges = {
        'light canvas': AuraColorRange.lightCanvas,
        'dark canvas': AuraColorRange.darkCanvas,
        'light group': AuraColorRange.lightGroup,
        'dark group': AuraColorRange.darkGroup,
        'light action': AuraColorRange.lightAction,
        'action fill': AuraColorRange.actionFill,
        'light pastel': AuraColorRange.lightPastel,
        'dark pastel': AuraColorRange.darkPastel,
      };
      for (final entry in ranges.entries) {
        final range = entry.value;
        for (final lightness in [range.minLightness, range.maxLightness]) {
          for (var hue = 0.0; hue < 360; hue++) {
            final color = range.resolve(
              hue: hue,
              lightness: lightness,
              chroma: range.maxChroma,
            );
            final reason = '${entry.key}: L=$lightness, h=$hue';
            final linear = color.toOklab().toLrgb();
            for (final channel in [linear.red, linear.green, linear.blue]) {
              expect(
                channel,
                inInclusiveRange(-1e-6, 1 + 1e-6),
                reason: reason,
              );
            }
            expect(range.contains(color), isTrue, reason: reason);
            expect(
              range.contains(.fromColor(color.toColor())),
              isTrue,
              reason: reason,
            );
            expect(color.lightness, lightness, reason: reason);
            expect(color.hue, hue, reason: reason);
          }
        }
      }
    });
  });
}
