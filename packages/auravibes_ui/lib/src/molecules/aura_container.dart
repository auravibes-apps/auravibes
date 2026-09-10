import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart'
    show AuraEdgeInsetsGeometry, AuraPadding;
import 'package:auravibes_ui/src/tokens/aura_theme.dart'
    show AuraTheme, AuraThemeExtension;
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show DesignColors, DesignShadows;
import 'package:flutter/material.dart';

/// A customizable layout container component following the Aura design system.
///
/// This container provides consistent padding, margin, background colors,
/// border radius, and shadow options for layout organization.
class AuraContainer extends StatelessWidget {
  /// Creates a Aura container.
  const new({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.variant = AuraContainerVariant.surface,
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

  /// The structural surface variant of the container.
  final AuraContainerVariant variant;

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
  Widget build(BuildContext context) => _AuraContainerBody(container: this);
}

class const _AuraContainerBody({required final AuraContainer container})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraContainerMargins(
    container: container,
    child: _AuraContainerDecorated(container: container),
  );
}

class const _AuraContainerMargins({
  required final AuraContainer container,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final margin = container.margin;
    final content = margin == null
        ? child
        : AuraPadding(child: child, padding: margin);
    final label = container.semanticLabel;

    return label == null
        ? content
        : Semantics(child: content, container: true, label: label);
  }
}

class const _AuraContainerDecorated({required final AuraContainer container})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final padding = container.padding;
    final content = padding == null
        ? container.child
        : AuraPadding(child: container.child, padding: padding);

    return Container(
      alignment: container.alignment,
      decoration: _containerDecoration(container, context.auraTheme),
      width: container.width,
      height: container.height,
      child: content,
    );
  }
}

BoxDecoration _containerDecoration(AuraContainer container, AuraTheme theme) =>
    BoxDecoration(
      color: _containerColor(container.variant, theme),
      border: container.border,
      borderRadius: _containerBorderRadius(container.borderRadius),
      boxShadow: _containerBoxShadow(container.shadow),
    );

Color _containerColor(AuraContainerVariant variant, AuraTheme theme) =>
    switch (variant) {
      .surface => theme.colors.surface,
      .surfaceVariant => theme.colors.surfaceVariant,
      .transparent => DesignColors.transparent,
    };

BorderRadius? _containerBorderRadius(double? radius) =>
    radius == null ? null : BorderRadius.circular(radius);

List<BoxShadow> _containerBoxShadow(AuraContainerShadow shadow) =>
    switch (shadow) {
      .none => [],
      .sm => [DesignShadows.sm],
      .md => [DesignShadows.md],
      .lg => [DesignShadows.lg],
      .xl => [DesignShadows.xl],
      .inner => [DesignShadows.inner],
      .glass => [DesignShadows.glass],
    };

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

/// Structural background variants for [AuraContainer].
enum AuraContainerVariant {
  /// Default surface background.
  surface,

  /// Alternate surface background.
  surfaceVariant,

  /// Transparent background.
  transparent,
}
