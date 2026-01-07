import 'package:flutter/material.dart';

/// Design tokens for the Aura AI Assistant design system.
///
/// This file contains all the design tokens extracted from the design system
/// specification, providing a single source of truth for colors, typography,
/// spacing, and other design properties.
class DesignTokens {
  DesignTokens._();
}

/// Hue color values for semantic colors.
///
/// These values are the hue components (in degrees) extracted from the
/// semantic brand colors defined in the design system. The original colors
/// are specified as hex/ARGB values in [DesignColors] (for example, the
/// success, error, warning, and info semantic colors), then converted to an
/// HSL/HSB color space and the resulting hue channel is recorded here.
///
/// When updating any of the underlying semantic colors in the design system,
/// recalculate these hue values using the same conversion process instead of
/// choosing arbitrary numbers, to keep the token set consistent and
/// traceable back to the source design.
class HueColorValues {
  HueColorValues._();

  /// Hue value (in degrees) for the success semantic color (green range).
  static const double success = 149.04;

  /// Hue value (in degrees) for the error semantic color (red range).
  static const double error = 25.33;

  /// Hue value (in degrees) for the warning semantic color (yellow/orange range).
  static const double warning = 70.08;

  /// Hue value (in degrees) for the info semantic color (blue/purple range).
  static const double info = 259.32;
}

/// Color tokens based on the design system specification.
///
/// Provides a comprehensive color palette including primary, secondary,
/// accent, neutral, and semantic colors for consistent UI design.
class DesignColors {
  DesignColors._();

  // Primary colors

  /// Main primary color for primary actions and branding.
  static const Color primaryBase = Color(0xFF2563EB);

  /// Lighter shade of primary color for hover states and highlights.
  static const Color primaryLight = Color(0xFF60A5FA);

  /// Darker shade of primary color for pressed states and emphasis.
  static const Color primaryDark = Color(0xFF1E40AF);

  /// Contrast color for text and icons on primary backgrounds.
  static const Color primaryContrast = Color(0xFFFFFFFF);

  // Secondary colors

  /// Main secondary color for secondary actions and accents.
  static const Color secondaryBase = Color(0xFFEC4899);

  /// Lighter shade of secondary color for hover states.
  static const Color secondaryLight = Color(0xFFF472B6);

  /// Darker shade of secondary color for pressed states.
  static const Color secondaryDark = Color(0xFFBE185D);

  /// Contrast color for text and icons on secondary backgrounds.
  static const Color secondaryContrast = Color(0xFFFFFFFF);

  // Accent colors

  /// Main accent color for special highlights and features.
  static const Color accentBase = Color(0xFF8B5CF6);

  /// Lighter shade of accent color for hover states.
  static const Color accentLight = Color(0xFFA78BFA);

  /// Darker shade of accent color for pressed states.
  static const Color accentDark = Color(0xFF6D28D9);

  /// Contrast color for text and icons on accent backgrounds.
  static const Color accentContrast = Color(0xFFFFFFFF);

  // Neutral colors

  /// Very light neutral color for backgrounds and subtle dividers.
  static const Color neutral50 = Color(0xFFF8FAFC);

  /// Light neutral color for card backgrounds and subtle borders.
  static const Color neutral100 = Color(0xFFF1F5F9);

  /// Light-medium neutral for disabled states and subtle fills.
  static const Color neutral200 = Color(0xFFE2E8F0);

  /// Medium-light neutral for borders and subtle text.
  static const Color neutral300 = Color(0xFFCBD5E1);

  /// Medium neutral for placeholder text and subtle icons.
  static const Color neutral400 = Color(0xFF94A3B8);

  /// Medium-dark neutral for secondary text and icons.
  static const Color neutral500 = Color(0xFF64748B);

  /// Dark neutral for tertiary text and muted elements.
  static const Color neutral600 = Color(0xFF475569);

  /// Darker neutral for inactive states and subtle backgrounds.
  static const Color neutral700 = Color(0xFF334155);

  /// Very dark neutral for dark mode backgrounds and heavy text.
  static const Color neutral800 = Color(0xFF1E293B);

  /// Darkest neutral for primary text in dark mode.
  static const Color neutral900 = Color(0xFF0F172A);

  // Semantic colors

  /// Transparent color
  static const Color transparent = Color(0x00000000);
}

/// Typography tokens for consistent text styling.
///
/// Defines font families, sizes, weights, line heights, and letter spacing
/// for all text elements in the design system.
class DesignTypography {
  DesignTypography._();

  // Font families

  /// Font family for headings and display text.
  static const String headingFontFamily = 'Inter';

  /// Font family for body text and content.
  static const String bodyFontFamily = 'Inter';

  /// Monospace font family for code and technical content.
  static const String monoFontFamily = 'JetBrains Mono';

  // Font sizes (in logical pixels)

  /// Extra small font size (12px, 0.75rem) for captions and fine print.
  static const double fontSizeXs = 12;

  /// Small font size (14px, 0.875rem) for secondary text and labels.
  static const double fontSizeSm = 14;

  /// Base font size (16px, 1rem) for body text and content.
  static const double fontSizeBase = 16;

  /// Large font size (18px, 1.125rem) for emphasized body text.
  static const double fontSizeLg = 18;

  /// Extra large font size (20px, 1.25rem) for small headings.
  static const double fontSizeXl = 20;

  /// 2X large font size (24px, 1.5rem) for medium headings.
  static const double fontSize2Xl = 24;

  /// 3X large font size (30px, 1.875rem) for large headings.
  static const double fontSize3Xl = 30;

  /// 4X large font size (36px, 2.25rem) for display headings.
  static const double fontSize4Xl = 36;

  /// 5X large font size (48px, 3rem) for hero text and large displays.
  static const double fontSize5Xl = 48;

  // Font weights

  /// Light font weight (300) for subtle text elements.
  static const FontWeight fontWeightLight = FontWeight.w300;

  /// Regular font weight (400) for body text and standard content.
  static const FontWeight fontWeightRegular = FontWeight.w400;

  /// Medium font weight (500) for emphasized text and buttons.
  static const FontWeight fontWeightMedium = FontWeight.w500;

  /// Semibold font weight (600) for subheadings and important text.
  static const FontWeight fontWeightSemibold = FontWeight.w600;

  /// Bold font weight (700) for headings and strong emphasis.
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Line heights

  /// Extra tight line height (1.2) for compact text layouts.
  static const double lineHeightXs = 1.2;

  /// Tight line height (1.25) for dense text content.
  static const double lineHeightSm = 1.25;

  /// Base line height (1.5) for comfortable reading of body text.
  static const double lineHeightBase = 1.5;

  /// Large line height (1.55) for improved readability.
  static const double lineHeightLg = 1.55;

  /// Extra large line height (1.6) for spacious text layouts.
  static const double lineHeightXl = 1.6;

  /// 2X large line height (1.3) for medium headings.
  static const double lineHeight2Xl = 1.3;

  /// 3X large line height (1.2) for large headings.
  static const double lineHeight3Xl = 1.2;

  /// 4X large line height (1.1) for display headings.
  static const double lineHeight4Xl = 1.1;

  /// 5X large line height (1.0) for hero text and tight displays.
  static const double lineHeight5Xl = 1;

  // Letter spacing

  /// Tight letter spacing (-0.025) for compact text.
  static const double letterSpacingTight = -0.025;

  /// Normal letter spacing (0) for standard text.
  static const double letterSpacingNormal = 0;

  /// Wide letter spacing (0.025) for spacious text and headings.
  static const double letterSpacingWide = 0.025;
}

/// Spacing tokens for consistent layout and component spacing.
///
/// All values are in logical pixels, providing a consistent spacing scale
/// based on the base unit of 16px (1rem).
class DesignSpacing {
  DesignSpacing._();

  /// Base spacing unit (16px, 1rem) for consistent scaling.
  static const double base = 16;

  /// Extra small spacing (4px, 0.25rem) for tight gaps and fine adjustments.
  static const double xs = 4;

  /// Small spacing (8px, 0.5rem) for minor element separation.
  static const double sm = 8;

  /// Medium spacing (16px, 1rem) for standard element separation.
  static const double md = 16;

  /// Large spacing (24px, 1.5rem) for section separation.
  static const double lg = 24;

  /// Extra large spacing (32px, 2rem) for major layout sections.
  static const double xl = 32;

  /// 2X large spacing (48px, 3rem) for page-level separation.
  static const double xl2 = 48;

  /// 3X large spacing (64px, 4rem) for maximum separation.

  static const double xl3 = 64;

  // Layout spacing

  /// Content padding (24px, 1.5rem) for main content areas.
  static const double contentPadding = 24;

  /// Section spacing (64px, 4rem) for major section breaks.
  static const double sectionSpacing = 64;

  /// Component spacing (16px, 1rem) for component separation.
  static const double componentSpacing = 16;
}

/// Border radius tokens for consistent corner rounding.
///
/// All values are in logical pixels, providing a scale from sharp to
/// fully rounded.
class DesignBorderRadius {
  DesignBorderRadius._();

  /// No border radius for sharp corners and square elements.
  static const double none = 0;

  /// Small border radius (2px, 0.125rem) for subtle rounding.
  static const double sm = 2;

  /// Medium border radius (6px, 0.375rem) for standard button rounding.
  static const double md = 6;

  /// Large border radius (8px, 0.5rem) for card and container rounding.
  static const double lg = 8;

  /// Extra large border radius (16px, 1rem) for prominent rounded elements.
  static const double xl = 16;

  /// Full border radius for perfectly circular elements.
  static const double full = 9999;
}

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

/// Z-index tokens for consistent element layering and stacking.
///
/// Provides a hierarchy for positioning elements above or below others.
class DesignZIndex {
  DesignZIndex._();

  /// Z-index for dropdown menus and overlays.
  static const int dropdown = 1000;

  /// Z-index for sticky positioned elements.
  static const int sticky = 1020;

  /// Z-index for fixed positioned elements.
  static const int fixed = 1030;

  /// Z-index for modal dialogs and overlays.
  static const int modal = 1040;

  /// Z-index for popover tooltips and callouts.
  static const int popover = 1050;

  /// Z-index for toast notifications and alerts.
  static const int toast = 1060;
}

/// Component size tokens
class DesignComponentSizes {
  DesignComponentSizes._();
}

/// Button size tokens for consistent button dimensions and spacing.
///
/// Defines heights and padding for small, medium, and large button variants.
class DesignButtonSizes {
  DesignButtonSizes._();

  /// Small button height (32px, 2rem) for compact button layouts.
  static const double heightSm = 32;

  /// Medium button height (40px, 2.5rem) for standard button layouts.
  static const double heightMd = 40;

  /// Large button height (48px, 3rem) for prominent button layouts.
  static const double heightLg = 48;

  /// Small button padding for compact buttons.
  static const EdgeInsets paddingSm = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  /// Medium button padding for standard buttons.
  static const EdgeInsets paddingMd = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 12,
  );

  /// Large button padding for prominent buttons.
  static const EdgeInsets paddingLg = EdgeInsets.symmetric(
    horizontal: 32,
    vertical: 16,
  );
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
    horizontal: 8,
    vertical: 6,
  );

  /// Medium input padding for standard input fields.
  static const EdgeInsets paddingMd = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  /// Large input padding for prominent input fields.
  static const EdgeInsets paddingLg = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
}

/// Navigation size tokens for consistent navigation bar dimensions.
///
/// Defines heights and padding for desktop and mobile navigation layouts.
class DesignNavigationSizes {
  DesignNavigationSizes._();

  /// Desktop navigation height (64px, 4rem) for desktop layouts.
  static const double desktopHeight = 64;

  /// Mobile navigation height (56px, 3.5rem) for mobile layouts.
  static const double mobileHeight = 56;

  /// Desktop navigation padding for spacious desktop layouts.
  static const EdgeInsets desktopPadding = EdgeInsets.symmetric(
    horizontal: 24,
  );

  /// Mobile navigation padding for compact mobile layouts.
  static const EdgeInsets mobilePadding = EdgeInsets.symmetric(
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

/// define spacing on components
enum AuraSpacing {
  /// no spacing
  none,

  /// common spacing
  base,

  /// extra small spacing
  xs,

  /// small spacing
  sm,

  /// medium spacing
  md,

  /// large spacing
  lg,

  /// extra large spacing
  xl,

  /// 2x extra large spacing
  xl2,

  /// 3x extra large spacing
  xl3,
}

/// Options for colors
enum AuraColorVariant {
  /// primary
  primary,

  /// on surface option
  onSurface,

  /// on surface variant option
  onSurfaceVariant,

  /// error option
  error,

  /// on primary option
  onPrimary,

  /// secondary option
  secondary,
}
