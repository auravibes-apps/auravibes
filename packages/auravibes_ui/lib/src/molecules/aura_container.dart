// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart'
    show AuraEdgeInsetsGeometry, AuraPadding;
import 'package:auravibes_ui/src/tokens/aura_theme.dart'
    show AuraThemeExtension;
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraColorVariant, DesignShadows;
import 'package:flutter/material.dart';

/// A customizable layout container component following the Aura design system.
///
/// This container provides consistent padding, margin, background colors,
/// border radius, and shadow options for layout organization.
class AuraContainer extends StatelessWidget {
  /// Creates a Aura container.
  const AuraContainer({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.shadow = AuraContainerShadow.none,
    this.border,
    this.width,
    this.height,
    this.alignment,
    this.semanticLabel,
  });

  /// The widget to display inside the container.
  final Widget child;

  /// The padding inside the container.
  final AuraEdgeInsetsGeometry? padding;

  /// The margin outside the container.
  final AuraEdgeInsetsGeometry? margin;

  /// The background color variant of the container.
  final AuraColorVariant? backgroundColor;

  /// The border radius of the container.
  final double? borderRadius;

  /// The shadow variant of the container.
  final AuraContainerShadow shadow;

  /// The border of the container.
  final Border? border;

  /// The width of the container.
  final double? width;

  /// The height of the container.
  final double? height;

  /// The alignment of the child within the container.
  final AlignmentGeometry? alignment;

  /// A semantic label for the container for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final auraTheme = context.auraTheme;
    final padding = this.padding;
    final margin = this.margin;
    final borderRadius = this.borderRadius;

    var container = child;

    if (padding != null) {
      container = AuraPadding(
        child: child,
        padding: padding,
      );
    }

    container = Container(
      alignment: alignment,
      decoration: BoxDecoration(
        color:
            auraTheme.colors.getColorOrNull(backgroundColor) ??
            auraTheme.colors.surface,
        border: border,
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius)
            : null,
        boxShadow: _getBoxShadow(),
      ),
      width: width,
      height: height,
      child: container,
    );

    if (margin != null) {
      container = AuraPadding(
        child: container,
        padding: margin,
      );
    }

    if (semanticLabel != null) {
      container = Semantics(
        child: container,
        container: true,
        label: semanticLabel,
      );
    }

    return container;
  }

  List<BoxShadow> _getBoxShadow() {
    return switch (shadow) {
      AuraContainerShadow.none => [],
      AuraContainerShadow.sm => [DesignShadows.sm],
      AuraContainerShadow.md => [DesignShadows.md],
      AuraContainerShadow.lg => [DesignShadows.lg],
      AuraContainerShadow.xl => [DesignShadows.xl],
      AuraContainerShadow.inner => [DesignShadows.inner],
      AuraContainerShadow.glass => [DesignShadows.glass],
    };
  }
}

/// The shadow variant of a [AuraContainer].
enum AuraContainerShadow {
  /// No shadow.
  none,

  /// Small shadow.
  sm,

  /// Medium shadow.
  md,

  /// Large shadow.
  lg,

  /// Extra large shadow.
  xl,

  /// Inner shadow.
  inner,

  /// Glass morphism shadow.
  glass,
}
