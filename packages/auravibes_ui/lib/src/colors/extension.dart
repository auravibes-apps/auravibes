import 'package:flutter/widgets.dart';

/// Extension providing color manipulation utilities for [Color].
extension AuraColorExtension on Color {
  /// Returns the inverted version of this color.
  Color get invertColor => Color.from(
    red: 1 - r,
    green: 1 - g,
    blue: 1 - b,
    alpha: a,
    colorSpace: colorSpace,
  );

  /// Returns a color that is a ratio blend between this color and [color].
  ///
  /// The [ratio] parameter determines the interpolation (0.0 = this color,
  /// 1.0 = target color).
  Color incrementRelative(double ratio, Color color) => Color.from(
    red: r + ((color.r - r) * ratio),
    green: g + ((color.g - g) * ratio),
    blue: b + ((color.b - b) * ratio),
    alpha: a + ((color.a - a) * ratio),
    colorSpace: colorSpace,
  );
}
