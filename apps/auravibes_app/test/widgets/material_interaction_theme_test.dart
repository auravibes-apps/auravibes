import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/main.dart' as app_main;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('removes fallback tap overlays and retains keyboard focus color', () {
    final theme = app_main.auraThemeDataForTesting(
      AccentHue.defaultValue,
      .light,
    );
    final focusColor = theme.colorScheme.surfaceContainerHighest;

    final defaultSplashFactory = ThemeData().splashFactory;
    expect(theme.splashFactory, isNot(same(defaultSplashFactory)));
    expect(
      theme.textButtonTheme.style?.splashFactory,
      isNot(same(defaultSplashFactory)),
    );
    expect(
      theme.iconButtonTheme.style?.splashFactory,
      isNot(same(defaultSplashFactory)),
    );
    expect(theme.splashColor, Colors.transparent);
    expect(theme.highlightColor, Colors.transparent);
    expect(theme.hoverColor, Colors.transparent);
    expect(theme.focusColor, focusColor);
    expect(theme.floatingActionButtonTheme.splashColor, Colors.transparent);

    final textButtonOverlay = theme.textButtonTheme.style?.overlayColor;
    expect(textButtonOverlay?.resolve({WidgetState.focused}), focusColor);
    expect(
      textButtonOverlay?.resolve({WidgetState.hovered}),
      Colors.transparent,
    );
    expect(
      textButtonOverlay?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );

    final iconButtonOverlay = theme.iconButtonTheme.style?.overlayColor;
    expect(iconButtonOverlay?.resolve({WidgetState.focused}), focusColor);
    expect(
      iconButtonOverlay?.resolve({WidgetState.hovered}),
      Colors.transparent,
    );
    expect(
      iconButtonOverlay?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
  });
}
