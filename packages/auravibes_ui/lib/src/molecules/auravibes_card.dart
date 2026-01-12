import 'dart:ui';

import 'package:auravibes_ui/src/atoms/atoms.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable card container component following the Aura design system.
///
/// This card provides consistent styling with different elevations, rounded
/// corners,
/// and padding variants for content organization.
class AuraCard extends StatelessWidget {
  /// Creates a Aura card.
  const AuraCard({
    required this.child,
    super.key,
    this.padding = .medium,
    this.onTap,
    this.semanticLabel,
    this.style = AuraCardStyle.elevated,
  });

  /// The widget to display inside the card.
  final Widget child;

  /// The padding inside the card.
  final AuraEdgeInsetsGeometry padding;

  /// The callback that is called when the card is tapped.
  final VoidCallback? onTap;

  /// A semantic label for the card for accessibility.
  final String? semanticLabel;

  /// style of card
  final AuraCardStyle? style;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    final isGlass = style == AuraCardStyle.glass;
    final isBorder = style == AuraCardStyle.border;

    // Define properties based on style
    Color backgroundColor;
    BoxBorder? border;
    List<BoxShadow> shadows;

    if (isGlass) {
      backgroundColor = auraColors.surface.withValues(alpha: 0.1);
      border = Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.5,
      );
      shadows = [DesignShadows.glass];
    } else if (isBorder) {
      backgroundColor = _getDefaultBackgroundColor(auraColors);
      border = Border.all(
        color: Colors.black.withValues(alpha: .06),
      );
      shadows = const [];
    } else {
      // Elevated / Default
      backgroundColor = _getDefaultBackgroundColor(auraColors);
      border = null;
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: .02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    }

    final Widget cardContent = AuraPadding(
      padding: padding,
      child: child,
    );

    Widget card;

    if (isGlass) {
      // Glass style implementation based on best practices
      // Reference: https://medium.com/@rohitsurage/build-beautiful-glassmorphism-ui-in-flutter-a-beginner-to-advanced-guide-023594a473b3
      card = ClipRRect(
        borderRadius: BorderRadius.circular(DesignBorderRadius.xl),
        // clipBehavior: Clip.hardEdge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AuraPressable(
            color: auraColors.onBackground,
            onPressed: onTap,
            decoration: BoxDecoration(
              // Use a subtle gradient for better glass effect than flat color
              // color: auraColors.inverseSurface.withValues(alpha: 0.3),
              gradient: LinearGradient(
                begin: .topLeft,
                end: .bottomCenter,
                colors: [
                  auraColors.onBackground.withValues(alpha: 0.07),
                  auraColors.onBackground.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignBorderRadius.xl),
              border: Border.all(
                color: auraColors.background.withValues(alpha: 0.05),
                width: 1.5,
              ),
            ),
            child: cardContent,
          ),
        ),
      );
    } else {
      card = AuraPressable(
        color: auraColors.primary,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(DesignBorderRadius.xl),
          border: border,
          boxShadow: shadows,
        ),
        onPressed: onTap,
        child: cardContent,
      );
    }

    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel,
        container: true,
        child: card,
      );
    }

    return card;
  }

  Color _getDefaultBackgroundColor(AuraColorScheme colors) {
    return colors.surface;
  }
}

/// Aura Card Style
enum AuraCardStyle {
  /// Card With border
  border,

  /// Card with glass effect
  glass,

  /// Card with elevation
  elevated,
}
