import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesignTokens', () {
    test('class exists and is private-constructed', () {
      // DesignTokens has a private constructor; verify it compiles.
      expect(DesignTokens, isA<Type>());
    });
  });

  group('HueColorValues', () {
    test('has expected hue constants', () {
      expect(HueColorValues.success, 149.04);
      expect(HueColorValues.error, 25.33);
      expect(HueColorValues.warning, 70.08);
      expect(HueColorValues.info, 259.32);
    });
  });

  group('DesignColors', () {
    test('has expected color constants', () {
      expect(DesignColors.primaryBase, const Color(0xFF2563EB));
      expect(DesignColors.primaryLight, const Color(0xFF60A5FA));
      expect(DesignColors.primaryDark, const Color(0xFF1E40AF));
      expect(DesignColors.primaryContrast, const Color(0xFFFFFFFF));
      expect(DesignColors.secondaryBase, const Color(0xFFEC4899));
      expect(DesignColors.accentBase, const Color(0xFF8B5CF6));
      expect(DesignColors.transparent, const Color(0x00000000));
    });

    test('has expected neutral colors', () {
      expect(DesignColors.neutral50, const Color(0xFFF8FAFC));
      expect(DesignColors.neutral900, const Color(0xFF0F172A));
    });
  });

  group('DesignTypography', () {
    test('has expected font families', () {
      expect(DesignTypography.headingFontFamily, 'Inter');
      expect(DesignTypography.bodyFontFamily, 'Inter');
      expect(DesignTypography.monoFontFamily, 'JetBrains Mono');
    });

    test('has expected font sizes', () {
      expect(DesignTypography.fontSizeXs, 12);
      expect(DesignTypography.fontSizeSm, 14);
      expect(DesignTypography.fontSizeBase, 16);
      expect(DesignTypography.fontSizeLg, 18);
      expect(DesignTypography.fontSizeXl, 20);
      expect(DesignTypography.fontSize2Xl, 24);
      expect(DesignTypography.fontSize3Xl, 30);
      expect(DesignTypography.fontSize4Xl, 36);
      expect(DesignTypography.fontSize5Xl, 48);
    });

    test('has expected font weights', () {
      expect(DesignTypography.fontWeightLight, FontWeight.w300);
      expect(DesignTypography.fontWeightRegular, FontWeight.w400);
      expect(DesignTypography.fontWeightMedium, FontWeight.w500);
      expect(DesignTypography.fontWeightSemibold, FontWeight.w600);
      expect(DesignTypography.fontWeightBold, FontWeight.w700);
    });

    test('has expected line heights', () {
      expect(DesignTypography.lineHeightXs, 1.2);
      expect(DesignTypography.lineHeightSm, 1.25);
      expect(DesignTypography.lineHeightBase, 1.5);
      expect(DesignTypography.lineHeightLg, 1.55);
      expect(DesignTypography.lineHeightXl, 1.6);
      expect(DesignTypography.lineHeight2Xl, 1.3);
      expect(DesignTypography.lineHeight3Xl, 1.2);
      expect(DesignTypography.lineHeight4Xl, 1.1);
      expect(DesignTypography.lineHeight5Xl, 1);
    });

    test('has expected letter spacing', () {
      expect(DesignTypography.letterSpacingTight, -0.025);
      expect(DesignTypography.letterSpacingNormal, 0);
      expect(DesignTypography.letterSpacingWide, 0.025);
    });
  });

  group('DesignSpacing', () {
    test('has expected spacing values', () {
      expect(DesignSpacing.base, 16);
      expect(DesignSpacing.xs, 4);
      expect(DesignSpacing.sm, 8);
      expect(DesignSpacing.md, 16);
      expect(DesignSpacing.lg, 24);
      expect(DesignSpacing.xl, 32);
      expect(DesignSpacing.xl2, 48);
      expect(DesignSpacing.xl3, 64);
    });

    test('has expected layout spacing', () {
      expect(DesignSpacing.contentPadding, 24);
      expect(DesignSpacing.sectionSpacing, 64);
      expect(DesignSpacing.componentSpacing, 16);
    });
  });

  group('DesignBorderRadius', () {
    test('has expected border radius values', () {
      expect(DesignBorderRadius.none, 0);
      expect(DesignBorderRadius.sm, 2);
      expect(DesignBorderRadius.md, 6);
      expect(DesignBorderRadius.lg, 8);
      expect(DesignBorderRadius.xl, 16);
      expect(DesignBorderRadius.full, 9999);
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

  group('DesignZIndex', () {
    test('has expected z-index values', () {
      expect(DesignZIndex.dropdown, 1000);
      expect(DesignZIndex.sticky, 1020);
      expect(DesignZIndex.fixed, 1030);
      expect(DesignZIndex.modal, 1040);
      expect(DesignZIndex.popover, 1050);
      expect(DesignZIndex.toast, 1060);
    });
  });

  group('DesignButtonSizes', () {
    test('has expected button size values', () {
      expect(DesignButtonSizes.heightSm, 32);
      expect(DesignButtonSizes.heightMd, 40);
      expect(DesignButtonSizes.heightLg, 48);
    });

    test('has expected button padding', () {
      expect(
        DesignButtonSizes.paddingSm,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
      expect(
        DesignButtonSizes.paddingMd,
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );
      expect(
        DesignButtonSizes.paddingLg,
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      );
    });
  });

  group('DesignInputSizes', () {
    test('has expected input size values', () {
      expect(DesignInputSizes.heightSm, 32);
      expect(DesignInputSizes.heightMd, 40);
      expect(DesignInputSizes.heightLg, 48);
    });
  });

  group('DesignNavigationSizes', () {
    test('has expected navigation size values', () {
      expect(DesignNavigationSizes.desktopHeight, 64);
      expect(DesignNavigationSizes.mobileHeight, 56);
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
