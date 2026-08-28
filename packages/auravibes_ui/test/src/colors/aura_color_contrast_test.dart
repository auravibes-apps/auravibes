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
      final pairs = <String, (Color, Color)>{
        'primary': (colors.onPrimary, colors.primary),
        'secondary': (colors.onSecondary, colors.secondary),
        'tertiary': (colors.onTertiary, colors.tertiary),
        'error': (colors.onError, colors.error),
        'warning': (colors.onWarning, colors.warning),
        'success': (colors.onSuccess, colors.success),
        'info': (colors.onInfo, colors.info),
        'surface': (colors.onSurface, colors.surface),
        'surface variant': (colors.onSurfaceVariant, colors.surfaceVariant),
        'background': (colors.onBackground, colors.background),
      };

      for (final pair in pairs.entries) {
        final ratio = ColorContrast.wcagContrastRatio(
          pair.value.$1,
          pair.value.$2,
        );
        if (ratio < 4.5) failures.add('${pair.key}: $ratio');
      }

      expect(failures, isEmpty, reason: '${entry.key}: ${failures.join(', ')}');
    }
  });
}
