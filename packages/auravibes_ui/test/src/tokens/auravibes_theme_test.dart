// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraTheme', () {
    test('light theme is created', () {
      expect(AuraTheme.light, isA<AuraTheme>());
      expect(AuraTheme.light.colors, isA<AuraColorScheme>());
    });

    test('dark theme is created', () {
      expect(AuraTheme.dark, isA<AuraTheme>());
      expect(AuraTheme.dark.colors, isA<AuraColorScheme>());
    });

    test('copyWith replaces values', () {
      final theme = AuraTheme.light.copyWith(
        animation: AuraTheme.dark.animation,
      );
      expect(theme.animation, AuraTheme.dark.animation);
      expect(theme.colors, AuraTheme.light.colors);
    });

    test('copyWith keeps original values when null', () {
      final theme = AuraTheme.light.copyWith();
      expect(theme.colors, AuraTheme.light.colors);
      expect(theme.animation, AuraTheme.light.animation);
      expect(theme.spacing, AuraTheme.light.spacing);
      expect(theme.borderRadius, AuraTheme.light.borderRadius);
      expect(theme.typography, AuraTheme.light.typography);
    });

    test('lerp returns this when other is null', () {
      final result = AuraTheme.light.lerp(null, 0.5);
      expect(result, AuraTheme.light);
    });

    test('lerp returns interpolated theme', () {
      final result = AuraTheme.light.lerp(AuraTheme.dark, 0.5);
      expect(result, isA<AuraTheme>());
      expect(result.colors, isA<AuraColorScheme>());
    });

    test('fromSpacing returns correct values', () {
      final theme = AuraTheme.light;
      expect(theme.fromSpacing(.none), 0);
      expect(theme.fromSpacing(.base), 16);
      expect(theme.fromSpacing(.xs), 4);
      expect(theme.fromSpacing(.sm), 8);
      expect(theme.fromSpacing(.md), 16);
      expect(theme.fromSpacing(.lg), 24);
      expect(theme.fromSpacing(.xl), 32);
      expect(theme.fromSpacing(.xl2), 48);
      expect(theme.fromSpacing(.xl3), 64);
    });
  });

  group('AuraSpacingScale', () {
    test('standard scale has expected values', () {
      final spacing = AuraTheme.light.spacing;
      expect(spacing.none, 0);
      expect(spacing.base, 16);
      expect(spacing.xs, 4);
      expect(spacing.sm, 8);
      expect(spacing.md, 16);
      expect(spacing.lg, 24);
      expect(spacing.xl, 32);
      expect(spacing.xl2, 48);
      expect(spacing.xl3, 64);
    });

    test('resolve maps each AuraSpacing', () {
      final spacing = AuraTheme.light.spacing;
      expect(spacing.resolve(.none), spacing.none);
      expect(spacing.resolve(.base), spacing.base);
      expect(spacing.resolve(.xl3), spacing.xl3);
    });

    test('lerp interpolates spacing values', () {
      const a = AuraSpacingScale();
      const b = AuraSpacingScale(xl: 100);
      final result = a.lerp(b, 0.5);
      expect(result.xl, 66);
    });
  });

  group('AuraBorderRadiusScale', () {
    test('standard scale has expected values', () {
      final radius = AuraTheme.light.borderRadius;
      expect(radius.none, 0);
      expect(radius.sm, 2);
      expect(radius.md, 6);
      expect(radius.lg, 8);
      expect(radius.xl, 16);
      expect(radius.full, 9999);
    });

    test('fromBorderRadius resolves each AuraBorderRadius', () {
      final theme = AuraTheme.light;
      expect(theme.fromBorderRadius(.none), 0);
      expect(theme.fromBorderRadius(.sm), 2);
      expect(theme.fromBorderRadius(.md), 6);
      expect(theme.fromBorderRadius(.lg), 8);
      expect(theme.fromBorderRadius(.xl), 16);
      expect(theme.fromBorderRadius(.full), 9999);
    });

    test('lerp interpolates radius values', () {
      const a = AuraBorderRadiusScale();
      const b = AuraBorderRadiusScale(lg: 40);
      final result = a.lerp(b, 0.5);
      expect(result.lg, 24);
    });
  });

  group('AuraTypographyScale', () {
    test('has expected font families', () {
      final typography = AuraTheme.light.typography;
      expect(typography.headingFontFamily, 'Inter');
      expect(typography.bodyFontFamily, 'Inter');
      expect(typography.monoFontFamily, 'JetBrains Mono');
    });

    test('has expected font sizes', () {
      final typography = AuraTheme.light.typography;
      expect(typography.fontSizeXs, 12);
      expect(typography.fontSizeSm, 14);
      expect(typography.fontSizeBase, 16);
      expect(typography.fontSizeLg, 18);
      expect(typography.fontSizeXl, 20);
      expect(typography.fontSize2Xl, 24);
      expect(typography.fontSize3Xl, 30);
      expect(typography.fontSize4Xl, 36);
      expect(typography.fontSize5Xl, 48);
    });

    test('has expected font weights', () {
      final typography = AuraTheme.light.typography;
      expect(typography.fontWeightLight, FontWeight.w300);
      expect(typography.fontWeightRegular, FontWeight.w400);
      expect(typography.fontWeightMedium, FontWeight.w500);
      expect(typography.fontWeightSemibold, FontWeight.w600);
      expect(typography.fontWeightBold, FontWeight.w700);
    });

    test('has expected line heights', () {
      final typography = AuraTheme.light.typography;
      expect(typography.lineHeightXs, 1.2);
      expect(typography.lineHeightSm, 1.25);
      expect(typography.lineHeightBase, 1.5);
      expect(typography.lineHeightLg, 1.55);
      expect(typography.lineHeightXl, 1.6);
      expect(typography.lineHeight2Xl, 1.3);
      expect(typography.lineHeight3Xl, 1.2);
      expect(typography.lineHeight4Xl, 1.1);
      expect(typography.lineHeight5Xl, 1);
    });

    test('has expected letter spacing', () {
      final typography = AuraTheme.light.typography;
      expect(typography.letterSpacingTight, -0.025);
      expect(typography.letterSpacingNormal, 0);
      expect(typography.letterSpacingWide, 0.025);
    });

    test('lerp interpolates numeric values', () {
      const a = AuraTypographyScale();
      const b = AuraTypographyScale(fontSizeLg: 28);
      final result = a.lerp(b, 0.5);
      expect(result.fontSizeLg, 23);
    });
  });

  group('AuraColorScheme', () {
    test('light scheme has all colors', () {
      final colors = AuraTheme.light.colors;
      expect(colors.primary, isA<Color>());
      expect(colors.secondary, isA<Color>());
      expect(colors.surface, isA<Color>());
      expect(colors.background, isA<Color>());
      expect(colors.error, isA<Color>());
      expect(colors.warning, isA<Color>());
      expect(colors.success, isA<Color>());
      expect(colors.info, isA<Color>());
    });

    test('dark scheme has all colors', () {
      final colors = AuraTheme.dark.colors;
      expect(colors.primary, isA<Color>());
      expect(colors.surface, isA<Color>());
      expect(colors.background, isA<Color>());
    });

    test('lerp interpolates colors', () {
      final light = AuraTheme.light.colors;
      final dark = AuraTheme.dark.colors;
      final result = light.lerp(dark, 0.5);
      expect(result.primary, isA<Color>());
      expect(result.surface, isA<Color>());
    });

    test('getColor returns correct color for variant', () {
      final colors = AuraTheme.light.colors;
      expect(colors.getColor(AuraColorVariant.primary), colors.primary);
      expect(colors.getColor(AuraColorVariant.onSurface), colors.onSurface);
      expect(colors.getColor(AuraColorVariant.error), colors.error);
      expect(
        colors.getColor(AuraColorVariant.onSurfaceVariant),
        colors.onSurfaceVariant,
      );
      expect(
        colors.getColor(AuraColorVariant.surfaceVariant),
        colors.surfaceVariant,
      );
      expect(colors.getColor(AuraColorVariant.onPrimary), colors.onPrimary);
      expect(colors.getColor(AuraColorVariant.secondary), colors.secondary);
      expect(colors.getColor(AuraColorVariant.success), colors.success);
      expect(colors.getColor(AuraColorVariant.warning), colors.warning);
      expect(colors.getColor(AuraColorVariant.info), colors.info);
    });

    test('getColorOrNull returns null for null variant', () {
      final colors = AuraTheme.light.colors;
      expect(colors.getColorOrNull(null), isNull);
    });

    test('getColorOrNull returns color for non-null variant', () {
      final colors = AuraTheme.light.colors;
      expect(colors.getColorOrNull(AuraColorVariant.primary), colors.primary);
    });
  });

  group('AuraAnimationTheme', () {
    test('standard theme has durations', () {
      final animation = AuraTheme.light.animation;
      expect(animation.fast, isA<Duration>());
      expect(animation.normal, isA<Duration>());
      expect(animation.slow, isA<Duration>());
      expect(
        animation.fast.inMilliseconds,
        lessThan(animation.normal.inMilliseconds),
      );
      expect(
        animation.normal.inMilliseconds,
        lessThan(animation.slow.inMilliseconds),
      );
    });

    test('lerp returns this when t < 0.5', () {
      final animation = AuraTheme.light.animation;
      final other = AuraTheme.dark.animation;
      expect(animation.lerp(other, 0.3), animation);
    });

    test('lerp returns other when t >= 0.5', () {
      final animation = AuraTheme.light.animation;
      final other = AuraTheme.dark.animation;
      expect(animation.lerp(other, 0.5), other);
    });
  });

  group('AuraThemeExtension', () {
    testWidgets('auraTheme returns theme from context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.auraTheme, AuraTheme.light);

              return const SizedBox();
            },
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );
    });

    testWidgets('auraColors returns colors from context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.auraColors, AuraTheme.light.colors);

              return const SizedBox();
            },
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );
    });

    testWidgets('auraTheme falls back to light when not found', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.auraTheme, AuraTheme.light);

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
