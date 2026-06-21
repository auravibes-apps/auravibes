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
      expect(theme.fromSpacing(AuraSpacing.base), DesignSpacing.base);
      expect(theme.fromSpacing(AuraSpacing.xs), DesignSpacing.xs);
      expect(theme.fromSpacing(AuraSpacing.sm), DesignSpacing.sm);
      expect(theme.fromSpacing(AuraSpacing.md), DesignSpacing.md);
      expect(theme.fromSpacing(AuraSpacing.lg), DesignSpacing.lg);
      expect(theme.fromSpacing(AuraSpacing.xl), DesignSpacing.xl);
      expect(theme.fromSpacing(AuraSpacing.xl2), DesignSpacing.xl2);
      expect(theme.fromSpacing(AuraSpacing.xl3), DesignSpacing.xl3);
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
