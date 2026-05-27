// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'dart:ui';

import 'package:auravibes_ui/src/atoms/atoms.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
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
        color: Colors.black.withValues(alpha: 0.06),
      );
      shadows = const [];
    } else {
      // Elevated / Default
      backgroundColor = _getDefaultBackgroundColor(auraColors);
      border = null;
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          offset: const Offset(0, 12),
          blurRadius: 28,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
      ];
    }

    final Widget cardContent = AuraPadding(
      child: child,
      padding: padding,
    );

    // Glass style implementation based on best practices
    // Reference: https://medium.com/@rohitsurage/build-beautiful-glassmorphism-ui-in-flutter-a-beginner-to-advanced-guide-023594a473b3
    var card = isGlass
        ? ClipRRect(
            borderRadius: BorderRadius.circular(DesignBorderRadius.xl),
            // clipBehavior: Clip.hardEdge,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: AuraPressable(
                child: cardContent,
                color: auraColors.onBackground,
                decoration: BoxDecoration(
                  // Use a subtle gradient for better glass effect than a
                  // flat color.
                  // color: auraColors.inverseSurface.withValues(alpha: 0.3),
                  border: Border.all(
                    color: auraColors.background.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(DesignBorderRadius.xl),
                  gradient: LinearGradient(
                    begin: .topLeft,
                    end: .bottomCenter,
                    colors: [
                      auraColors.onBackground.withValues(alpha: 0.07),
                      auraColors.onBackground.withValues(alpha: 0.03),
                    ],
                  ),
                ),
                onPressed: onTap,
              ),
            ),
          )
        : AuraPressable(
            child: cardContent,
            color: auraColors.primary,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: border,
              borderRadius: BorderRadius.circular(DesignBorderRadius.xl),
              boxShadow: shadows,
            ),
            onPressed: onTap,
          );

    if (semanticLabel != null) {
      card = Semantics(
        child: card,
        container: true,
        label: semanticLabel,
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
