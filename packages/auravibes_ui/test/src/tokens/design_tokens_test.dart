import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HueColorValues', () {
    test('has expected hue constants', () {
      expect(hueSuccess, 149.04);
      expect(hueError, 25.33);
      expect(hueWarning, 70.08);
      expect(hueInfo, 259.32);
    });
  });

  group('DesignColors', () {
    test('has expected color constants', () {
      expect(designColorPrimaryBase, const Color(0xFF0F766E));
      expect(designColorPrimaryLight, const Color(0xFF5EEAD4));
      expect(designColorPrimaryDark, const Color(0xFF134E4A));
      expect(designColorPrimaryContrast, const Color(0xFFFFFFFF));
      expect(designColorSecondaryBase, const Color(0xFFBE123C));
      expect(designColorSecondaryLight, const Color(0xFFFDA4AF));
      expect(designColorSecondaryDark, const Color(0xFF881337));
      expect(designColorAccentBase, const Color(0xFFB45309));
      expect(designColorAccentLight, const Color(0xFFFBBF24));
      expect(designColorAccentDark, const Color(0xFF78350F));
      expect(designColorTransparent, const Color(0x00000000));
    });

    test('brand colors contrast with their theme foregrounds', () {
      final colorsWithWhiteForeground = <Color>[
        designColorPrimaryBase,
        designColorSecondaryBase,
        designColorAccentBase,
      ];
      final colorsWithBlackForeground = <Color>[
        designColorPrimaryLight,
        designColorSecondaryLight,
        designColorAccentLight,
      ];

      for (final color in colorsWithWhiteForeground) {
        expect(
          color.computeLuminance(),
          lessThan(0.1833),
          reason: '$color must keep 4.5:1 contrast with white foregrounds.',
        );
      }

      for (final color in colorsWithBlackForeground) {
        expect(
          color.computeLuminance(),
          greaterThan(0.175),
          reason: '$color must keep 4.5:1 contrast with black foregrounds.',
        );
      }
    });

    test('has expected neutral colors', () {
      expect(designColorNeutral50, const Color(0xFFF8FAFC));
      expect(designColorNeutral900, const Color(0xFF0F172A));
    });
  });

  group('DesignBorderWidth', () {
    test('has expected border width values', () {
      expect(DesignBorderWidth.thin, 1);
      expect(DesignBorderWidth.medium, 2);
      expect(DesignBorderWidth.thick, 4);
    });
  });

  group('DesignElevation', () {
    test('has expected elevation values', () {
      expect(DesignElevation.none, 0);
      expect(DesignElevation.sm, 1);
      expect(DesignElevation.md, 4);
      expect(DesignElevation.lg, 8);
      expect(DesignElevation.xl, 16);
    });
  });

  group('DesignDuration', () {
    test('has expected duration values', () {
      expect(DesignDuration.fast, const Duration(milliseconds: 150));
      expect(DesignDuration.normal, const Duration(milliseconds: 200));
      expect(DesignDuration.slow, const Duration(milliseconds: 300));
    });
  });

  group('DesignBreakpoints', () {
    test('has expected breakpoint values', () {
      expect(DesignBreakpoints.sm, 640);
      expect(DesignBreakpoints.md, 768);
      expect(DesignBreakpoints.lg, 1024);
      expect(DesignBreakpoints.xl, 1280);
      expect(DesignBreakpoints.xl2, 1536);
    });
  });

  group('DesignInputSizes', () {
    test('has expected input size values', () {
      expect(DesignInputSizes.heightSm, 32);
      expect(DesignInputSizes.heightMd, 40);
      expect(DesignInputSizes.heightLg, 48);
    });
  });

  group('DesignShadows', () {
    test('has expected shadow definitions', () {
      expect(DesignShadows.sm.color, const Color(0x0D000000));
      expect(DesignShadows.md.color, const Color(0x1A000000));
      expect(DesignShadows.lg.color, const Color(0x1A000000));
      expect(DesignShadows.xl.color, const Color(0x1A000000));
      expect(DesignShadows.inner.color, const Color(0x0F000000));
      expect(DesignShadows.glass.color, const Color(0x5F1F2687));
    });
  });

  group('AuraSpacing enum', () {
    test('has all expected values', () {
      expect(AuraSpacing.values, hasLength(9));
      expect(AuraSpacing.values, contains(AuraSpacing.none));
      expect(AuraSpacing.values, contains(AuraSpacing.base));
      expect(AuraSpacing.values, contains(AuraSpacing.xs));
      expect(AuraSpacing.values, contains(AuraSpacing.sm));
      expect(AuraSpacing.values, contains(AuraSpacing.md));
      expect(AuraSpacing.values, contains(AuraSpacing.lg));
      expect(AuraSpacing.values, contains(AuraSpacing.xl));
      expect(AuraSpacing.values, contains(AuraSpacing.xl2));
      expect(AuraSpacing.values, contains(AuraSpacing.xl3));
    });
  });

  group('AuraColorVariant enum', () {
    test('has all expected values', () {
      expect(AuraColorVariant.values, hasLength(10));
      expect(AuraColorVariant.values, contains(AuraColorVariant.primary));
      expect(AuraColorVariant.values, contains(AuraColorVariant.onSurface));
      expect(
        AuraColorVariant.values,
        contains(AuraColorVariant.onSurfaceVariant),
      );
      expect(
        AuraColorVariant.values,
        contains(AuraColorVariant.surfaceVariant),
      );
      expect(AuraColorVariant.values, contains(AuraColorVariant.error));
      expect(AuraColorVariant.values, contains(AuraColorVariant.onPrimary));
      expect(AuraColorVariant.values, contains(AuraColorVariant.secondary));
      expect(AuraColorVariant.values, contains(AuraColorVariant.success));
      expect(AuraColorVariant.values, contains(AuraColorVariant.warning));
      expect(AuraColorVariant.values, contains(AuraColorVariant.info));
    });
  });
}
