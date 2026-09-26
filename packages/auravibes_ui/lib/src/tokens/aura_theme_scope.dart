import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

/// Provides Aura theme data independently of the host Material theme.
class AuraThemeScope extends InheritedWidget {
  /// Creates an Aura theme scope.
  const new({required this.theme, required super.child, super.key});

  /// Theme made available to descendants.
  final AuraTheme theme;

  /// Returns the nearest Aura theme, if one exists.
  static AuraTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuraThemeScope>()?.theme;

  @override
  bool updateShouldNotify(AuraThemeScope oldWidget) =>
      !identical(theme, oldWidget.theme);
}
