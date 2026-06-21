// Required: Existing test and UI helpers keep compact return flow.
// Required: UI package exposes top-level helpers and constants.

import 'package:auravibes_ui/src/colors/value_color.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Aura theme extension that provides theme-aware design tokens.
///
/// Only theme-aware tokens (colors) live here. Spacing, border radius, and
/// typography are constant across themes, so they are accessed directly from
/// [DesignSpacing], [DesignBorderRadius], and [DesignTypography].
@immutable
class AuraTheme extends ThemeExtension<AuraTheme> {
  /// Creates a Aura theme extension.
  const AuraTheme({required this.colors, required this.animation});

  /// Light theme variant.
  static final light = AuraTheme(
    colors: _lightColors,
    animation: _standardAnimation,
  );

  /// Dark theme variant.
  static final dark = AuraTheme(
    colors: _darkColors,
    animation: _standardAnimation,
  );

  static final _lightColors = AuraColorScheme._light();
  static final _darkColors = AuraColorScheme._dark();
  static const _standardAnimation = AuraAnimationTheme._standard();

  /// Color scheme for the theme.
  final AuraColorScheme colors;

  /// Animation theme.
  final AuraAnimationTheme animation;

  @override
  AuraTheme copyWith({
    AuraColorScheme? colors,
    AuraAnimationTheme? animation,
  }) {
    return AuraTheme(
      colors: colors ?? this.colors,
      animation: animation ?? this.animation,
    );
  }

  @override
  AuraTheme lerp(AuraTheme? other, double t) {
    if (other == null) return this;

    return AuraTheme(
      colors: colors.lerp(other.colors, t),
      animation: animation.lerp(other.animation, t),
    );
  }

  /// Resolve an [AuraSpacing] enum to its concrete pixel value.
  double fromSpacing(AuraSpacing value) {
    return switch (value) {
      AuraSpacing.none => 0,
      AuraSpacing.base => DesignSpacing.base,
      AuraSpacing.xs => DesignSpacing.xs,
      AuraSpacing.sm => DesignSpacing.sm,
      AuraSpacing.md => DesignSpacing.md,
      AuraSpacing.lg => DesignSpacing.lg,
      AuraSpacing.xl => DesignSpacing.xl,
      AuraSpacing.xl2 => DesignSpacing.xl2,
      AuraSpacing.xl3 => DesignSpacing.xl3,
    };
  }
}

/// Color scheme that adapts to light and dark themes.
@immutable
class AuraColorScheme {
  /// Creates a [AuraColorScheme] with the specified colors.
  const AuraColorScheme({
    required this.primary,
    required this.primaryVariant,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryVariant,
    required this.onSecondary,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.warning,
    required this.onWarning,
    required this.success,
    required this.onSuccess,
    required this.info,
    required this.onInfo,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
  });

  /// Creates a light color scheme.
  AuraColorScheme._light()
    : primary = DesignColors.primaryBase,
      primaryVariant = DesignColors.primaryDark,
      onPrimary = DesignColors.primaryContrast,
      secondary = DesignColors.secondaryBase,
      secondaryVariant = DesignColors.secondaryDark,
      onSecondary = DesignColors.secondaryContrast,
      surface = DesignColors.neutral50,
      surfaceVariant = const Color(0xFFFFFFFF),
      onSurface = DesignColors.neutral900,
      onSurfaceVariant = DesignColors.neutral700,
      background = DesignColors.neutral100,
      onBackground = DesignColors.neutral900,
      error = OKLCHColor(
        hue: HueColorValues.error,
        lightness: 0.6,
        chroma: 0.2,
      ).toColor(),
      onError = const Color(0xFFFFFFFF),
      warning = OKLCHColor(
        hue: HueColorValues.warning,
        lightness: 0.6,
        chroma: 0.2,
      ).toColor(),
      onWarning = const Color(0xFFFFFFFF),
      success = OKLCHColor(
        hue: HueColorValues.success,
        lightness: 0.6,
        chroma: 0.2,
      ).toColor(),
      onSuccess = const Color(0xFFFFFFFF),
      info = OKLCHColor(
        hue: HueColorValues.info,
        lightness: 0.6,
        chroma: 0.2,
      ).toColor(),
      onInfo = const Color(0xFFFFFFFF),
      outline = DesignColors.neutral300,
      outlineVariant = DesignColors.neutral200,
      shadow = DesignColors.neutral900,
      scrim = const Color(0x80000000);

  /// Creates a dark color scheme.
  AuraColorScheme._dark()
    : primary = DesignColors.primaryLight,
      primaryVariant = DesignColors.primaryBase,
      onPrimary = Colors.black,
      secondary = DesignColors.secondaryLight,
      secondaryVariant = DesignColors.secondaryBase,
      onSecondary = Colors.black,
      surface = DesignColors.neutral800,
      surfaceVariant = DesignColors.neutral700,
      onSurface = DesignColors.neutral100,
      onSurfaceVariant = DesignColors.neutral300,
      background = Colors.black,
      onBackground = DesignColors.neutral100,
      error = OKLCHColor(
        hue: HueColorValues.error,
        lightness: 0.4,
        chroma: 0.2,
      ).toColor(),
      onError = Colors.black,
      warning = OKLCHColor(
        hue: HueColorValues.warning,
        lightness: 0.4,
        chroma: 0.2,
      ).toColor(),
      onWarning = Colors.black,
      success = OKLCHColor(
        hue: HueColorValues.success,
        lightness: 0.4,
        chroma: 0.2,
      ).toColor(),
      onSuccess = Colors.black,
      info = OKLCHColor(
        hue: HueColorValues.info,
        lightness: 0.4,
        chroma: 0.2,
      ).toColor(),
      onInfo = Colors.black,
      outline = DesignColors.neutral600,
      outlineVariant = DesignColors.neutral700,
      shadow = const Color(0xFF000000),
      scrim = const Color(0xB3000000);

  /// Primary color for main UI elements.
  final Color primary;

  /// Variant of the primary color for highlights.
  final Color primaryVariant;

  /// Color for text/icons on primary color.
  final Color onPrimary;

  /// Secondary color for accents.
  final Color secondary;

  /// Variant of the secondary color.
  final Color secondaryVariant;

  /// Color for text/icons on secondary color.
  final Color onSecondary;

  /// Background color for cards, sheets.
  final Color surface;

  /// Variant surface color.
  final Color surfaceVariant;

  /// Color for text/icons on surface.
  final Color onSurface;

  /// Color for text/icons on surface variants.
  final Color onSurfaceVariant;

  /// Background color for the app.
  final Color background;

  /// Color for text/icons on background.
  final Color onBackground;

  /// Error color.
  final Color error;

  /// Color for text/icons on error color.
  final Color onError;

  /// Warning color.
  final Color warning;

  /// Color for text/icons on warning color.
  final Color onWarning;

  /// Success color.
  final Color success;

  /// Color for text/icons on success color.
  final Color onSuccess;

  /// Info color.
  final Color info;

  /// Color for text/icons on info color.
  final Color onInfo;

  /// Outline color for borders.
  final Color outline;

  /// Variant outline color.
  final Color outlineVariant;

  /// Shadow color.
  final Color shadow;

  /// Scrim color for overlays.
  final Color scrim;

  /// Linearly interpolate between two color schemes.
  AuraColorScheme lerp(AuraColorScheme other, double t) {
    return AuraColorScheme(
      primary: _lerpColor(primary, other.primary, t),
      primaryVariant: _lerpColor(primaryVariant, other.primaryVariant, t),
      onPrimary: _lerpColor(onPrimary, other.onPrimary, t),
      secondary: _lerpColor(secondary, other.secondary, t),
      secondaryVariant: _lerpColor(
        secondaryVariant,
        other.secondaryVariant,
        t,
      ),
      onSecondary: _lerpColor(onSecondary, other.onSecondary, t),
      surface: _lerpColor(surface, other.surface, t),
      surfaceVariant: _lerpColor(surfaceVariant, other.surfaceVariant, t),
      onSurface: _lerpColor(onSurface, other.onSurface, t),
      onSurfaceVariant: _lerpColor(
        onSurfaceVariant,
        other.onSurfaceVariant,
        t,
      ),
      background: _lerpColor(background, other.background, t),
      onBackground: _lerpColor(onBackground, other.onBackground, t),
      error: _lerpColor(error, other.error, t),
      onError: _lerpColor(onError, other.onError, t),
      warning: _lerpColor(warning, other.warning, t),
      onWarning: _lerpColor(onWarning, other.onWarning, t),
      success: _lerpColor(success, other.success, t),
      onSuccess: _lerpColor(onSuccess, other.onSuccess, t),
      info: _lerpColor(info, other.info, t),
      onInfo: _lerpColor(onInfo, other.onInfo, t),
      outline: _lerpColor(outline, other.outline, t),
      outlineVariant: _lerpColor(outlineVariant, other.outlineVariant, t),
      shadow: _lerpColor(shadow, other.shadow, t),
      scrim: _lerpColor(scrim, other.scrim, t),
    );
  }

  Color _lerpColor(Color begin, Color end, double t) {
    return Color.lerp(begin, end, t) ?? begin;
  }

  /// Get color by variant nullable.
  Color? getColorOrNull(AuraColorVariant? variant) {
    if (variant == null) return null;

    return getColor(variant);
  }

  /// Get color by variant.
  Color getColor(AuraColorVariant variant) {
    return switch (variant) {
      AuraColorVariant.primary => primary,
      AuraColorVariant.onSurface => onSurface,
      AuraColorVariant.error => error,
      AuraColorVariant.onSurfaceVariant => onSurfaceVariant,
      AuraColorVariant.surfaceVariant => surfaceVariant,
      AuraColorVariant.onPrimary => onPrimary,
      AuraColorVariant.secondary => secondary,
      AuraColorVariant.success => success,
      AuraColorVariant.warning => warning,
      AuraColorVariant.info => info,
    };
  }
}

/// Animation theme that provides consistent timing values.
///
/// Defines animation durations (fast, normal, slow) to ensure
/// cohesive motion design across the application.
@immutable
class AuraAnimationTheme {
  /// Creates an animation theme with the specified values.
  const AuraAnimationTheme({
    this.fast = DesignDuration.fast,
    this.normal = DesignDuration.normal,
    this.slow = DesignDuration.slow,
  });

  /// Creates the standard animation theme.
  const AuraAnimationTheme._standard()
    : fast = DesignDuration.fast,
      normal = DesignDuration.normal,
      slow = DesignDuration.slow;

  /// Fast animation duration (150ms) for quick transitions and
  /// micro-interactions.
  final Duration fast;

  /// Normal animation duration (200ms) for standard transitions and
  /// state changes.
  final Duration normal;

  /// Slow animation duration (300ms) for deliberate animations and
  /// page transitions.
  final Duration slow;

  /// Linearly interpolate between two animation themes.
  AuraAnimationTheme lerp(AuraAnimationTheme other, double t) {
    // Animation durations don't interpolate, return this or other based on t.
    return t < 0.5 ? this : other;
  }
}

/// Extension to get Aura theme from BuildContext.
extension AuraThemeExtension on BuildContext {
  /// Get the current Aura theme.
  AuraTheme get auraTheme =>
      Theme.of(this).extension<AuraTheme>() ?? AuraTheme.light;

  /// Get the current Aura color scheme.
  AuraColorScheme get auraColors => auraTheme.colors;
}
