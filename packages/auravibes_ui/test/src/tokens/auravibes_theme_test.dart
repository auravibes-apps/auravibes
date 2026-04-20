import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
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
        spacing: const AuraSpacingTheme(xs: 99),
      );
      expect(theme.spacing.xs, 99);
      expect(theme.colors, AuraTheme.light.colors);
    });

    test('copyWith keeps original values when null', () {
      final theme = AuraTheme.light.copyWith();
      expect(theme.colors, AuraTheme.light.colors);
      expect(theme.spacing, AuraTheme.light.spacing);
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
      expect(theme.fromSpacing(AuraSpacing.none), 0);
      expect(theme.fromSpacing(AuraSpacing.base), theme.spacing.md);
      expect(theme.fromSpacing(AuraSpacing.xs), theme.spacing.xs);
      expect(theme.fromSpacing(AuraSpacing.sm), theme.spacing.sm);
      expect(theme.fromSpacing(AuraSpacing.md), theme.spacing.md);
      expect(theme.fromSpacing(AuraSpacing.lg), theme.spacing.lg);
      expect(theme.fromSpacing(AuraSpacing.xl), theme.spacing.xl);
      expect(theme.fromSpacing(AuraSpacing.xl2), theme.spacing.xl2);
      expect(theme.fromSpacing(AuraSpacing.xl3), theme.spacing.xl3);
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

  group('AuraTypographyTheme', () {
    test('standard theme has font families', () {
      final typography = AuraTheme.light.typography;
      expect(typography.fontFamily, isNotEmpty);
      expect(typography.monoFontFamily, isNotEmpty);
    });

    test('lerp returns this when t < 0.5', () {
      final typography = AuraTheme.light.typography;
      final other = AuraTheme.dark.typography;
      expect(typography.lerp(other, 0.3), typography);
    });

    test('lerp returns other when t >= 0.5', () {
      final typography = AuraTheme.light.typography;
      final other = AuraTheme.dark.typography;
      expect(typography.lerp(other, 0.5), other);
    });
  });

  group('AuraFontSizes', () {
    test('has all size values', () {
      final sizes = AuraTheme.light.typography.sizes;
      expect(sizes.xs, greaterThan(0));
      expect(sizes.sm, greaterThan(sizes.xs));
      expect(sizes.base, greaterThan(0));
      expect(sizes.lg, greaterThan(sizes.base));
      expect(sizes.xl, greaterThan(sizes.lg));
      expect(sizes.xl2, greaterThan(sizes.xl));
      expect(sizes.xl3, greaterThan(sizes.xl2));
      expect(sizes.xl4, greaterThan(sizes.xl3));
      expect(sizes.xl5, greaterThan(sizes.xl4));
    });
  });

  group('AuraFontWeights', () {
    test('has all weight values', () {
      final weights = AuraTheme.light.typography.weights;
      expect(weights.light, FontWeight.w300);
      expect(weights.regular, FontWeight.w400);
      expect(weights.medium, FontWeight.w500);
      expect(weights.semibold, FontWeight.w600);
      expect(weights.bold, FontWeight.w700);
    });
  });

  group('AuraLineHeights', () {
    test('has all line height values', () {
      final heights = AuraTheme.light.typography.lineHeights;
      expect(heights.xs, greaterThan(0));
      expect(heights.sm, greaterThan(0));
      expect(heights.base, greaterThan(0));
      expect(heights.lg, greaterThan(0));
      expect(heights.xl, greaterThan(0));
      expect(heights.xl2, greaterThan(0));
      expect(heights.xl3, greaterThan(0));
      expect(heights.xl4, greaterThan(0));
      expect(heights.xl5, greaterThan(0));
    });
  });

  group('AuraLetterSpacings', () {
    test('has all letter spacing values', () {
      final spacings = AuraTheme.light.typography.letterSpacings;
      expect(spacings.tight, lessThan(spacings.normal));
      expect(spacings.normal, lessThan(spacings.wide));
    });
  });

  group('AuraSpacingTheme', () {
    test('standard theme has spacing values', () {
      final spacing = AuraTheme.light.spacing;
      expect(spacing.xs, greaterThan(0));
      expect(spacing.sm, greaterThan(spacing.xs));
      expect(spacing.md, greaterThan(spacing.sm));
      expect(spacing.lg, greaterThan(spacing.md));
      expect(spacing.xl, greaterThan(spacing.lg));
      expect(spacing.xl2, greaterThan(spacing.xl));
      expect(spacing.xl3, greaterThan(spacing.xl2));
    });

    test('lerp interpolates spacing', () {
      final a = AuraTheme.light.spacing;
      const b = AuraSpacingTheme(xs: 99);
      final result = a.lerp(b, 0.5);
      expect(result.xs, greaterThan(a.xs));
      expect(result.xs, lessThan(b.xs));
    });
  });

  group('AuraBorderRadiusTheme', () {
    test('standard theme has radius values', () {
      final radii = AuraTheme.light.borderRadius;
      expect(radii.none, 0);
      expect(radii.sm, greaterThan(0));
      expect(radii.md, greaterThan(radii.sm));
      expect(radii.lg, greaterThan(radii.md));
      expect(radii.xl, greaterThan(radii.lg));
      expect(radii.full, greaterThan(radii.xl));
    });

    test('lerp interpolates border radius', () {
      final a = AuraTheme.light.borderRadius;
      const b = AuraBorderRadiusTheme(sm: 99);
      final result = a.lerp(b, 0.5);
      expect(result.sm, greaterThan(a.sm));
      expect(result.sm, lessThan(b.sm));
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
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: Builder(
            builder: (context) {
              expect(context.auraTheme, AuraTheme.light);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('auraColors returns colors from context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: Builder(
            builder: (context) {
              expect(context.auraColors, AuraTheme.light.colors);
              return const SizedBox();
            },
          ),
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

  group('lerpDouble', () {
    test('interpolates between two values', () {
      expect(lerpDouble(0, 10, 0.5), 5);
    });

    test('returns null when both are null', () {
      expect(lerpDouble(null, null, 0.5), isNull);
    });

    test('uses 0 when a is null', () {
      expect(lerpDouble(null, 10, 0.5), 5);
    });

    test('uses 0 when b is null', () {
      expect(lerpDouble(10, null, 0.5), 5);
    });

    test('returns a when t is 0', () {
      expect(lerpDouble(5, 10, 0), 5);
    });

    test('returns b when t is 1', () {
      expect(lerpDouble(5, 10, 1), 10);
    });
  });
}
