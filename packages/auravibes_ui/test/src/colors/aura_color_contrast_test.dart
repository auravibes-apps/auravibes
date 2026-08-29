import 'package:auravibes_ui/src/colors/contrast.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark foreground/background roles meet WCAG AA', () {
    final schemes = {
      'light': AuraTheme.light.colors,
      'dark': AuraTheme.dark.colors,
    };

    for (final entry in schemes.entries) {
      final colors = entry.value;
      final failures = <String>[];
      final pairs = <String, ({Color foreground, Color background})>{
        'primary': (foreground: colors.onPrimary, background: colors.primary),
        'secondary': (
          foreground: colors.onSecondary,
          background: colors.secondary,
        ),
        'tertiary': (
          foreground: colors.onTertiary,
          background: colors.tertiary,
        ),
        'error': (foreground: colors.onError, background: colors.error),
        'warning': (foreground: colors.onWarning, background: colors.warning),
        'success': (foreground: colors.onSuccess, background: colors.success),
        'info': (foreground: colors.onInfo, background: colors.info),
        'surface': (foreground: colors.onSurface, background: colors.surface),
        'surface variant': (
          foreground: colors.onSurfaceVariant,
          background: colors.surfaceVariant,
        ),
        'background': (
          foreground: colors.onBackground,
          background: colors.background,
        ),
      };

      for (final pair in pairs.entries) {
        final ratio = ColorContrast.wcagContrastRatio(
          pair.value.foreground,
          pair.value.background,
        );
        if (ratio < 4.5) failures.add('${pair.key}: $ratio');
      }

      expect(failures, isEmpty, reason: '${entry.key}: ${failures.join(', ')}');
    }
  });
}
