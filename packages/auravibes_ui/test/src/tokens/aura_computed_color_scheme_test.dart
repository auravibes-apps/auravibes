import 'package:auravibes_ui/src/colors/aura_brightness.dart';
import 'package:auravibes_ui/src/colors/aura_color_range.dart';
import 'package:auravibes_ui/src/colors/color_contrast.dart';
import 'package:auravibes_ui/src/colors/value_color.dart';
import 'package:auravibes_ui/src/tokens/aura_computed_color_scheme.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double hueDelta(double a, double b) {
  final d = (a - b).abs() % 360;

  return d > 180 ? 360 - d : d;
}

void main() {
  group('AuraComputedColorScheme', () {
    test('hue changes reuse brightness-specific foregrounds', () {
      for (final brightness in AuraBrightness.values) {
        final first = AuraComputedColorScheme(
          primaryHue: 0,
          brightness: brightness,
        );
        final second = AuraComputedColorScheme(
          primaryHue: 121,
          brightness: brightness,
        );
        expect(identical(first.onError, second.onError), isTrue);
        expect(identical(first.onSurface, second.onSurface), isTrue);
        expect(first.primary, isNot(second.primary));
      }
    });

    test('bright brand fills keep dark labels readable across every hue', () {
      for (final brightness in AuraBrightness.values) {
        for (var hue = 0.0; hue <= 360; hue++) {
          final colors = AuraComputedColorScheme(
            primaryHue: hue,
            brightness: brightness,
          );
          for (final tint in [
            AuraTint.primary,
            AuraTint.secondary,
            AuraTint.tertiary,
          ]) {
            final fill = colors.fillFor(tint);
            final foreground = Color(colors.onFill(tint).toARGB32());
            final background = Color(fill.toARGB32());
            expect(
              AuraColorRange.actionFill.contains(.fromColor(fill)),
              isTrue,
            );
            expect(foreground, DesignColors.neutral900);
            expect(
              ColorContrast.wcagContrastRatio(foreground, background),
              greaterThanOrEqualTo(4.5),
              reason: '${brightness.name}, h=$hue, ${tint.name}',
            );
            expect(
              ColorContrast.apcaLc(
                foreground: foreground,
                background: background,
              ).abs(),
              greaterThanOrEqualTo(60),
              reason: '${brightness.name}, h=$hue, ${tint.name}',
            );
          }
          for (final tint in [
            AuraTint.error,
            AuraTint.warning,
            AuraTint.success,
            AuraTint.info,
          ]) {
            expect(colors.fillFor(tint), colors.colorFor(tint));
            expect(colors.onFill(tint), colors.onTint(tint));
          }
        }
      }
    });

    test('constructs AuraColorScheme and exposes key color roles', () {
      final s = AuraComputedColorScheme(primaryHue: 180, brightness: .light);
      expect(s, isA<AuraColorScheme>());
      expect(s.primary, isA<Color>());
      expect(s.surface, isA<Color>());
      expect(s.scrim, isA<Color>());
    });

    test('light scheme: on* meet APCA Lc 60 against their surface', () {
      final s = AuraComputedColorScheme(primaryHue: 200, brightness: .light);
      // The on color must clear the perceptual target regardless of polarity.
      expect(
        ColorContrast.apcaLc(
          foreground: s.onPrimary,
          background: s.primary,
        ).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
      expect(
        ColorContrast.apcaLc(
          foreground: s.onSurface,
          background: s.surface,
        ).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
      expect(
        ColorContrast.apcaLc(
          foreground: s.onBackground,
          background: s.background,
        ).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
      expect(
        ColorContrast.apcaLc(foreground: s.onError, background: s.error).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
    });

    test('dark scheme: on* meet APCA Lc 60 against their surface', () {
      final s = AuraComputedColorScheme(primaryHue: 200, brightness: .dark);
      expect(
        ColorContrast.apcaLc(
          foreground: s.onPrimary,
          background: s.primary,
        ).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
      expect(
        ColorContrast.apcaLc(
          foreground: s.onSurface,
          background: s.surface,
        ).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
    });

    test('all integer hues meet text targets on base and reused surfaces', () {
      for (final brightness in AuraBrightness.values) {
        for (var hue = 0.0; hue <= 360; hue++) {
          final s = AuraComputedColorScheme(
            primaryHue: hue,
            brightness: brightness,
          );
          final pairs = {
            'primary': (foreground: s.onPrimary, background: s.primary),
            'primary variant': (
              foreground: s.onPrimary,
              background: s.primaryVariant,
            ),
            'secondary': (foreground: s.onSecondary, background: s.secondary),
            'secondary variant': (
              foreground: s.onSecondary,
              background: s.secondaryVariant,
            ),
            'tertiary': (foreground: s.onTertiary, background: s.tertiary),
            'tertiary variant': (
              foreground: s.onTertiary,
              background: s.tertiaryVariant,
            ),
            'surface': (foreground: s.onSurface, background: s.surface),
            'surface variant': (
              foreground: s.onSurfaceVariant,
              background: s.surfaceVariant,
            ),
            'background': (
              foreground: s.onBackground,
              background: s.background,
            ),
            'error': (foreground: s.onError, background: s.error),
            'warning': (foreground: s.onWarning, background: s.warning),
            'success': (foreground: s.onSuccess, background: s.success),
            'info': (foreground: s.onInfo, background: s.info),
            'bubble on variant': (
              foreground: s.onSurface,
              background: s.surfaceVariant,
            ),
            'muted on surface': (
              foreground: s.onSurfaceVariant,
              background: s.surface,
            ),
            'muted on canvas': (
              foreground: s.onSurfaceVariant,
              background: s.background,
            ),
            'accent on canvas': (
              foreground: s.primary,
              background: s.background,
            ),
            'accent on surface': (foreground: s.primary, background: s.surface),
            'accent on variant': (
              foreground: s.primary,
              background: s.surfaceVariant,
            ),
          };
          for (final entry in pairs.entries) {
            final foreground = Color(entry.value.foreground.toARGB32());
            final background = Color(entry.value.background.toARGB32());
            final reason = '${brightness.name}, h=$hue, ${entry.key}';
            expect(
              ColorContrast.wcagContrastRatio(foreground, background),
              greaterThanOrEqualTo(4.5),
              reason: reason,
            );
            expect(
              ColorContrast.apcaLc(
                foreground: foreground,
                background: background,
              ).abs(),
              greaterThanOrEqualTo(60),
              reason: reason,
            );
          }
        }
      }
    });

    test('rendered colors stay within their role ranges across all hues', () {
      for (final brightness in AuraBrightness.values) {
        final isLight = brightness == AuraBrightness.light;
        final canvas = isLight
            ? AuraColorRange.lightCanvas
            : AuraColorRange.darkCanvas;
        final group = isLight
            ? AuraColorRange.lightGroup
            : AuraColorRange.darkGroup;
        final accent = isLight
            ? AuraColorRange.lightAction
            : AuraColorRange.darkPastel;
        for (var hue = 0.0; hue < 360; hue++) {
          final colors = AuraComputedColorScheme(
            primaryHue: hue,
            brightness: brightness,
          );
          final roles = [
            (range: canvas, color: colors.background),
            (range: group, color: colors.surface),
            (range: group, color: colors.surfaceVariant),
            (range: accent, color: colors.primary),
            (range: accent, color: colors.primaryVariant),
            (range: accent, color: colors.secondary),
            (range: accent, color: colors.secondaryVariant),
            (range: accent, color: colors.tertiary),
            (range: accent, color: colors.tertiaryVariant),
            (range: accent, color: colors.error),
            (range: accent, color: colors.warning),
            (range: accent, color: colors.success),
            (range: accent, color: colors.info),
          ];
          for (final (:range, :color) in roles) {
            expect(
              range.contains(.fromColor(color)),
              isTrue,
              reason: '${brightness.name}, h=$hue, $color',
            );
          }
        }
      }
    });

    test('secondary hue is primary + 180 (complement)', () {
      const hue = 60.0;
      final s = AuraComputedColorScheme(primaryHue: hue, brightness: .light);
      final secondaryHue = OKLCHColor.fromColor(s.secondary).hue;
      // Allow sRGB round-trip drift, worst at blue hues (gamut clamping).
      expect(hueDelta(secondaryHue, hue + 180), lessThan(16));
    });

    test('control outlines meet 3:1 on each neutral background', () {
      for (final brightness in AuraBrightness.values) {
        final colors = AuraComputedColorScheme(
          primaryHue: 180,
          brightness: brightness,
        );
        for (final outline in [colors.outline, colors.outlineVariant]) {
          for (final background in [
            colors.background,
            colors.surface,
            colors.surfaceVariant,
          ]) {
            expect(
              ColorContrast.wcagContrastRatio(
                .new(outline.toARGB32()),
                .new(background.toARGB32()),
              ),
              greaterThanOrEqualTo(3),
              reason: brightness.name,
            );
          }
        }
      }
    });

    test('semantic colors carry HueColorValues hues', () {
      final s = AuraComputedColorScheme(primaryHue: 0, brightness: .light);
      expect(
        hueDelta(OKLCHColor.fromColor(s.error).hue, HueColorValues.error),
        lessThan(8),
      );
      expect(
        hueDelta(OKLCHColor.fromColor(s.success).hue, HueColorValues.success),
        lessThan(8),
      );
    });

    test('light surfaces stay achromatic', () {
      final s = AuraComputedColorScheme(primaryHue: 180, brightness: .light);
      final surface = OKLCHColor.fromColor(s.surface);
      final surfaceVariant = OKLCHColor.fromColor(s.surfaceVariant);
      final background = OKLCHColor.fromColor(s.background);

      expect(surface.chroma, lessThan(0.001));
      expect(surfaceVariant.chroma, lessThan(0.001));
      expect(background.chroma, lessThan(0.001));
    });

    test('light groups are darker than the near-white canvas', () {
      final s = AuraComputedColorScheme(primaryHue: 180, brightness: .light);
      final background = OKLCHColor.fromColor(s.background);
      final surface = OKLCHColor.fromColor(s.surface);

      expect(background.lightness, greaterThan(surface.lightness));
      expect(
        surface.lightness,
        greaterThan(OKLCHColor.fromColor(s.surfaceVariant).lightness),
      );
    });

    test('dark surfaces stay achromatic and preserve elevation', () {
      final s = AuraComputedColorScheme(primaryHue: 180, brightness: .dark);
      final background = OKLCHColor.fromColor(s.background);
      final surface = OKLCHColor.fromColor(s.surface);
      final surfaceVariant = OKLCHColor.fromColor(s.surfaceVariant);

      expect(s.background, isNot(Colors.black));
      expect(background.chroma, lessThan(0.001));
      expect(surface.chroma, lessThan(0.001));
      expect(surfaceVariant.chroma, lessThan(0.001));
      expect(background.lightness, lessThan(surface.lightness));
      expect(surface.lightness, lessThan(surfaceVariant.lightness));
    });

    test('lerp from base AuraColorScheme still works (subclass unchanged)', () {
      final a = AuraComputedColorScheme(primaryHue: 180, brightness: .light);
      final b = AuraComputedColorScheme(primaryHue: 270, brightness: .dark);
      final mid = a.lerp(b, 0.5);
      expect(mid, isA<AuraColorScheme>());
      expect(mid.primary, isA<Color>());
    });
  });
}
