import 'package:flutter/material.dart';

/// Design tokens for the Aura AI Assistant design system.
///
/// Color, motion, elevation, and layout raw tokens live here as consts.
/// Spacing, border radius, and typography values are intentionally
/// absent: they are theme-owned (see AuraTheme in `aura_theme.dart`) so a
/// subtree `Theme` override can rescale them. Call sites select them via the
/// AuraSpacing / AuraBorderRadius enums (and AuraTextStyle for type).

/// Hue color values for semantic colors.
///
/// These are the hue components (in degrees) for the success, error,
/// warning, and info semantic colors. The semantic colors themselves are
/// generated from these hues via OKLCH in `aura_theme.dart`
/// (`AuraColorScheme._light`/`._dark`), so the values below are the
/// canonical source for those colors.
///
/// When updating any semantic color in the design system, recalculate the
/// matching hue using the same HSL/HSB conversion instead of choosing an
/// arbitrary number, to keep the token set consistent and traceable back to
/// the source design.

/// Hue value (in degrees) for the success semantic color (green range).
const double hueSuccess = 149.04;

/// Hue value (in degrees) for the error semantic color (red range).
const double hueError = 25.33;

/// Hue value (in degrees) for the warning semantic color (yellow/orange range).
const double hueWarning = 70.08;

/// Hue value (in degrees) for the info semantic color (blue/purple range).
const double hueInfo = 259.32;

/// Color tokens based on the design system specification.
///
/// Provides a comprehensive color palette including primary, secondary,
/// accent, neutral, and semantic colors for consistent UI design.

// Primary colors.

/// Main primary color for primary actions and branding.
const Color designColorPrimaryBase = Color(0xFF0F766E);

/// Lighter shade of primary color for hover states and highlights.
const Color designColorPrimaryLight = Color(0xFF5EEAD4);

/// Darker shade of primary color for pressed states and emphasis.
const Color designColorPrimaryDark = Color(0xFF134E4A);

/// Contrast color for text and icons on primary backgrounds.
const Color designColorPrimaryContrast = Color(0xFFFFFFFF);

// Secondary colors.

/// Main secondary color for secondary actions and accents.
const Color designColorSecondaryBase = Color(0xFFBE123C);

/// Lighter shade of secondary color for hover states.
const Color designColorSecondaryLight = Color(0xFFFDA4AF);

/// Darker shade of secondary color for pressed states.
const Color designColorSecondaryDark = Color(0xFF881337);

/// Contrast color for text and icons on secondary backgrounds.
const Color designColorSecondaryContrast = Color(0xFFFFFFFF);

// Accent colors.

/// Main accent color for special highlights and features.
const Color designColorAccentBase = Color(0xFFB45309);

/// Lighter shade of accent color for hover states.
const Color designColorAccentLight = Color(0xFFFBBF24);

/// Darker shade of accent color for pressed states.
const Color designColorAccentDark = Color(0xFF78350F);

/// Contrast color for text and icons on accent backgrounds.
const Color designColorAccentContrast = Color(0xFFFFFFFF);

// Neutral colors.

/// Very light neutral color for backgrounds and subtle dividers.
const Color designColorNeutral50 = Color(0xFFF8FAFC);

/// Light neutral color for card backgrounds and subtle borders.
const Color designColorNeutral100 = Color(0xFFF1F5F9);

/// Light-medium neutral for disabled states and subtle fills.
const Color designColorNeutral200 = Color(0xFFE2E8F0);

/// Medium-light neutral for borders and subtle text.
const Color designColorNeutral300 = Color(0xFFCBD5E1);

/// Medium neutral for placeholder text and subtle icons.
const Color designColorNeutral400 = Color(0xFF94A3B8);

/// Medium-dark neutral for secondary text and icons.
const Color designColorNeutral500 = Color(0xFF64748B);

/// Dark neutral for tertiary text and muted elements.
const Color designColorNeutral600 = Color(0xFF475569);

/// Darker neutral for inactive states and subtle backgrounds.
const Color designColorNeutral700 = Color(0xFF334155);

/// Very dark neutral for dark mode backgrounds and heavy text.
const Color designColorNeutral800 = Color(0xFF1E293B);

/// Darkest neutral for primary text in dark mode.
const Color designColorNeutral900 = Color(0xFF0F172A);

// Semantic colors.

/// Transparent color.
const Color designColorTransparent = Color(0x00000000);

/// Border width tokens for consistent border styling.
///
/// All values are in logical pixels, providing a scale from subtle to
/// prominent borders.
class DesignBorderWidth {
  DesignBorderWidth._();

  /// Thin border width (1px) for subtle dividers and outlines.
  static const double thin = 1;

  /// Medium border width (2px) for standard borders and emphasis.
  static const double medium = 2;

  /// Thick border width (4px) for prominent borders and focus states.
  static const double thick = 4;
}

/// Elevation tokens for consistent shadow depth and layering.
///
/// Values represent the elevation height in logical pixels for shadow effects.
class DesignElevation {
  DesignElevation._();

  /// No elevation for flat elements and backgrounds.
  static const double none = 0;

  /// Small elevation (1px) for subtle depth and hover states.
  static const double sm = 1;

  /// Medium elevation (4px) for cards and standard components.
  static const double md = 4;

  /// Large elevation (8px) for floating elements and dropdowns.
  static const double lg = 8;

  /// Extra large elevation (16px) for modals and prominent overlays.
  static const double xl = 16;
}

/// Animation duration tokens for consistent motion timing.
///
/// Provides standard durations for different animation speeds and transitions.
class DesignDuration {
  DesignDuration._();

  /// Fast animation duration (150ms) for quick transitions and
  /// micro-interactions.
  static const Duration fast = Duration(milliseconds: 150);

  /// Normal animation duration (200ms) for standard transitions and
  /// state changes.
  static const Duration normal = Duration(milliseconds: 200);

  /// Slow animation duration (300ms) for deliberate animations and
  /// page transitions.
  static const Duration slow = Duration(milliseconds: 300);
}

/// Breakpoint tokens for responsive design.
///
/// All values are in logical pixels, defining screen width thresholds
/// for responsive layout adjustments.
class DesignBreakpoints {
  DesignBreakpoints._();

  /// Small breakpoint (640px) for mobile devices and narrow screens.
  static const double sm = 640;

  /// Medium breakpoint (768px) for tablets and medium screens.
  static const double md = 768;

  /// Large breakpoint (1024px) for desktop screens and wide displays.
  static const double lg = 1024;

  /// Extra large breakpoint (1280px) for large desktop screens.
  static const double xl = 1280;

  /// 2X large breakpoint (1536px) for ultra-wide displays and large monitors.
  static const double xl2 = 1536;
}

/// Input size tokens for consistent form input dimensions and spacing.
///
/// Defines heights and padding for small, medium, and large input variants.
class DesignInputSizes {
  DesignInputSizes._();

  /// Small input height (32px, 2rem) for compact input fields.
  static const double heightSm = 32;

  /// Medium input height (40px, 2.5rem) for standard input fields.
  static const double heightMd = 40;

  /// Large input height (48px, 3rem) for prominent input fields.
  static const double heightLg = 48;

  /// Small input padding for compact input fields.
  static const EdgeInsets paddingSm = EdgeInsets.symmetric(
    vertical: 6,
    horizontal: 8,
  );

  /// Medium input padding for standard input fields.
  static const EdgeInsets paddingMd = EdgeInsets.symmetric(
    vertical: 8,
    horizontal: 12,
  );

  /// Large input padding for prominent input fields.
  static const EdgeInsets paddingLg = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );
}

/// Shadow tokens for consistent elevation and depth effects.
///
/// Provides predefined BoxShadow objects for different elevation levels
/// and visual effects.
class DesignShadows {
  DesignShadows._();

  /// Small shadow for subtle elevation and hover states.
  static const BoxShadow sm = BoxShadow(
    color: Color(0x0D000000),
    offset: Offset(0, 1),
    blurRadius: 2,
  );

  /// Medium shadow for cards and standard components.
  static const BoxShadow md = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 4),
    blurRadius: 6,
    spreadRadius: -1,
  );

  /// Large shadow for floating elements and dropdowns.
  static const BoxShadow lg = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 10),
    blurRadius: 15,
    spreadRadius: -3,
  );

  /// Extra large shadow for modals and prominent overlays.
  static const BoxShadow xl = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 20),
    blurRadius: 25,
    spreadRadius: -5,
  );

  /// Inner shadow for inset effects and depth.
  static const BoxShadow inner = BoxShadow(
    color: Color(0x0F000000),
    offset: Offset(0, 2),
    blurRadius: 4,
  );

  /// Glass shadow for glassmorphism effects and translucent elements.
  static const BoxShadow glass = BoxShadow(
    color: Color(0x5F1F2687),
    offset: Offset(0, 8),
    blurRadius: 32,
  );
}

/// Spacing selector for layout gaps, padding, and sizing.
///
/// Selects a value from the theme-owned spacing scale
/// (`AuraTheme.spacing`, resolved via `context.auraTheme.fromSpacing`), so a
/// subtree `Theme` override can rescale spacing. Values are NOT on this enum.
enum AuraSpacing {
  /// No spacing.
  none,

  /// Common spacing.
  base,

  /// Extra small spacing.
  xs,

  /// Small spacing.
  sm,

  /// Medium spacing.
  md,

  /// Large spacing.
  lg,

  /// Extra large spacing.
  xl,

  /// 2X extra large spacing.
  xl2,

  /// 3X extra large spacing.
  xl3,
}

/// Border radius selector for corner rounding.
///
/// Selects a value from the theme-owned border-radius scale
/// (`AuraTheme.borderRadius`, resolved via `fromBorderRadius`), so a subtree
/// `Theme` override can rescale rounding. Values are NOT on this enum.
enum AuraBorderRadius {
  /// No border radius for sharp corners and square elements.
  none,

  /// Small border radius for subtle rounding.
  sm,

  /// Medium border radius for standard button rounding.
  md,

  /// Large border radius for card and container rounding.
  lg,

  /// Extra large border radius for prominent rounded elements.
  xl,

  /// Full border radius for perfectly circular elements.
  full,
}

/// Options for colors.
enum AuraColorVariant {
  /// Primary.
  primary,

  /// On surface option.
  onSurface,

  /// On surface variant option.
  onSurfaceVariant,

  /// Surface variant option.
  surfaceVariant,

  /// Error option.
  error,

  /// On primary option.
  onPrimary,

  /// Secondary option.
  secondary,

  /// Success option (semantic).
  success,

  /// Warning option (semantic).
  warning,

  /// Info option (semantic).
  info,
}
