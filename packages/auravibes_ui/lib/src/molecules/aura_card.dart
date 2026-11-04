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
  const new({
    required this.child,
    super.key,
    this.padding = .medium,
    this.onTap,
    this.semanticLabel,
    this.style = AuraCardStyle.elevated,
    this.tint,
  });

  /// The widget to display inside the card.
  final Widget child;

  /// The padding inside the card.
  final AuraEdgeInsetsGeometry padding;

  /// The callback that is called when the card is tapped.
  final VoidCallback? onTap;

  /// A semantic label for the card for accessibility.
  final String? semanticLabel;

  /// Style of card.
  final AuraCardStyle style;

  /// Optional semantic accent blended with the card surface.
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) => _AuraCardBody(card: this);
}

class const _AuraCardBody({required final AuraCard card})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return _AuraCardSurface(
      card: card,
      colors: colors,
      radius: AuraCornerRadiusScope.resolve(context, fallback: .xl),
    );
  }
}

class const _AuraCardContent({
  required final AuraCard card,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPadding(
    child: DefaultTextStyle.merge(
      style: .new(color: color),
      child: IconTheme(
        data: .new(color: color),
        child: card.child,
      ),
    ),
    padding: card.padding,
  );
}

class _AuraCardSurface extends StatelessWidget {
  new({
    required AuraCard card,
    required AuraColorScheme colors,
    required double radius,
  }) : _child = _AuraCardSemantics(
         child: _AuraCardVariant(
           data: .new(
             card: card,
             content: _AuraCardContent(
               card: card,
               color: colors.foregroundOnSurface,
             ),
             colors: colors,
             onTap: card.onTap,
             radius: radius,
           ),
         ),
         label: card.semanticLabel,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraCardSemantics({
  required final Widget child,
  required final String? label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => label == null
      ? child
      : Semantics(child: child, container: true, label: label);
}

class const _AuraCardVariantData({
  required final AuraCard card,
  required final Widget content,
  required final AuraColorScheme colors,
  required final VoidCallback? onTap,
  required final double radius,
});

class const _AuraCardVariant({required final _AuraCardVariantData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AuraSolidCard(
      appearance: .new(
        colors: data.colors,
        style: data.card.style,
        tint: data.card.tint,
      ),
      data: data,
    );
  }
}

class const _AuraSolidCard({
  required final _AuraCardAppearance appearance,
  required final _AuraCardVariantData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPressable(
    child: data.content,
    color: appearance.colors.primary,
    decoration: _decoration(appearance, data.radius),
    onPressed: data.onTap,
  );

  Decoration _decoration(_AuraCardAppearance appearance, double radius) =>
      BoxDecoration(
        color: appearance.surfaceColor(),
        border: appearance._border,
        borderRadius: BorderRadius.all(.circular(radius)),
        boxShadow: appearance._shadows,
      );
}

class _AuraCardAppearance {
  new({required this.colors, required this.style, required this.tint})
    : _shadows = switch (style) {
        .glass || .border => const [],
        .elevated => [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            offset: const Offset(0, 12),
            blurRadius: 28,
          ),
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.02),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      };

  final AuraColorScheme colors;
  final AuraCardStyle style;
  final AuraTint? tint;
  final List<BoxShadow> _shadows;

  bool get _isBorder =>
      style == AuraCardStyle.border || style == AuraCardStyle.glass;

  BoxBorder? get _border {
    if (_isBorder) {
      return Border.fromBorderSide(.new(color: colors.outlineVariant));
    }

    return null;
  }

  Color get _defaultBackgroundColor {
    final tint = this.tint;
    if (tint == null) return colors.surface;

    return Color.alphaBlend(
      colors.colorFor(tint).withValues(alpha: 0.08),
      colors.surface,
    );
  }

  Color surfaceColor() => _defaultBackgroundColor;

  @override
  String toString() => 'AuraCardAppearance(style: $style, tint: $tint)';
}

/// Aura Card Style.
enum AuraCardStyle {
  /// Card With border.
  border,

  /// Legacy alias for the bordered card style.
  glass,

  /// Card with elevation.
  elevated,
}
