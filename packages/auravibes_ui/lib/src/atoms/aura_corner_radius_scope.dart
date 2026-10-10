import 'dart:math' as math;

import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// Provides a resolved corner radius to descendant Aura widgets.
///
/// Use [select] to establish a themed radius and [adjust] to change the
/// nearest scope by a logical-pixel delta.
class const AuraCornerRadiusScope._({
  required final double radius,
  required super.child,
}) extends InheritedTheme {
  /// Selects a radius level using the active theme's numeric scale.
  static Widget select({
    required AuraBorderRadius level,
    required Widget child,
  }) => Builder(
    builder: (context) => AuraCornerRadiusScope._(
      radius: context.auraTheme.borderRadius.resolve(level),
      child: child,
    ),
  );

  /// Subtracts [delta] from the nearest radius; negative values increase it.
  ///
  /// Throws [FlutterError] when no parent scope exists.
  static Widget adjust({required double delta, required Widget child}) =>
      Builder(
        builder: (context) {
          final parentRadius = maybeOf(context);
          if (parentRadius == null) {
            throw FlutterError(
              'AuraCornerRadiusScope.adjust requires a parent radius scope.',
            );
          }

          return AuraCornerRadiusScope._(
            radius: math.max(parentRadius - delta, 0),
            child: child,
          );
        },
      );

  /// Returns the nearest scoped radius.
  ///
  /// Throws [FlutterError] when no radius scope exists.
  static double of(BuildContext context) =>
      maybeOf(context) ??
      (throw FlutterError('No AuraCornerRadiusScope found in context.'));

  /// Returns the nearest scoped radius, if one exists.
  static double? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AuraCornerRadiusScope>()
      ?.radius;

  /// Resolves an explicit radius, local scope, global theme level, or fallback.
  static double resolve(
    BuildContext context, {
    required AuraBorderRadius fallback,
    AuraBorderRadius? explicit,
  }) {
    final theme = context.auraTheme;
    if (explicit != null) return theme.borderRadius.resolve(explicit);

    final scopedRadius = maybeOf(context);
    if (scopedRadius != null) return scopedRadius;

    return theme.fromBorderRadius(fallback);
  }

  @override
  Widget wrap(BuildContext context, Widget child) =>
      AuraCornerRadiusScope._(radius: radius, child: child);

  @override
  bool updateShouldNotify(AuraCornerRadiusScope oldWidget) =>
      radius != oldWidget.radius;
}
