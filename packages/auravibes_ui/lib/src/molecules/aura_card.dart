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
  static const _borderWidth = 1.5;
  static const _glassBlurSigma = 18.0;

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
      radius: context.auraTheme.fromBorderRadius(.xl),
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

class const _AuraCardSurface({
  required final AuraCard card,
  required final AuraColorScheme colors,
  required final double radius,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = _AuraCardContent(
      card: card,
      color: colors.foregroundOnSurface,
    );
    final data = _AuraCardVariantData(
      card: card,
      content: content,
      colors: colors,
      onTap: card.onTap,
      radius: radius,
    );

    return _AuraCardSemantics(
      child: _AuraCardVariant(data: data),
      label: card.semanticLabel,
    );
  }
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
    if (data.card.style == AuraCardStyle.glass) {
      return _AuraGlassCard(data: data);
    }

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

class const _AuraGlassCard({required final _AuraCardVariantData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.all(.circular(data.radius)),
    child: BackdropFilter(
      filter: .blur(
        sigmaX: AuraCard._glassBlurSigma,
        sigmaY: AuraCard._glassBlurSigma,
      ),
      child: _AuraGlassPressable(data: data),
    ),
  );
}

class const _AuraGlassPressable({required final _AuraCardVariantData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPressable(
    child: data.content,
    color: data.colors.onBackground,
    decoration: _decoration(data.colors, data.radius),
    onPressed: data.onTap,
  );

  Decoration _decoration(AuraColorScheme colors, double radius) =>
      BoxDecoration(
        border: _border(colors),
        borderRadius: BorderRadius.all(.circular(radius)),
        gradient: _gradient(colors),
      );

  Border _border(AuraColorScheme colors) => Border.all(
    color: colors.background.withValues(alpha: 0.05),
    width: AuraCard._borderWidth,
  );

  Gradient _gradient(AuraColorScheme colors) => LinearGradient(
    begin: .topLeft,
    end: .bottomCenter,
    colors: [
      colors.onBackground.withValues(alpha: 0.07),
      colors.onBackground.withValues(alpha: 0.03),
    ],
  );
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
        color: appearance.backgroundColor,
        border: appearance.border,
        borderRadius: BorderRadius.all(.circular(radius)),
        boxShadow: appearance.shadows,
      );
}

class const _AuraCardAppearance({
  required final AuraColorScheme colors,
  required final AuraCardStyle style,
  required final AuraTint? tint,
}) {
  bool get isGlass => style == AuraCardStyle.glass;

  bool get isBorder => style == AuraCardStyle.border;

  Color get backgroundColor {
    if (isGlass) return colors.surface.withValues(alpha: 0.1);

    return _defaultBackgroundColor;
  }

  BoxBorder? get border {
    if (isGlass) {
      return Border.all(
        color: colors.surfaceVariant.withValues(alpha: 0.2),
        width: AuraCard._borderWidth,
      );
    }
    if (isBorder) {
      return Border.fromBorderSide(.new(color: colors.outlineVariant));
    }

    return null;
  }

  List<BoxShadow> get shadows {
    if (isGlass) return [DesignShadows.glass];
    if (isBorder) return const [];

    return [
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
    ];
  }

  Color get _defaultBackgroundColor {
    final tint = this.tint;
    if (tint == null) return colors.surface;

    return Color.alphaBlend(
      colors.colorFor(tint).withValues(alpha: 0.08),
      colors.surface,
    );
  }
}

/// Aura Card Style.
enum AuraCardStyle {
  /// Card With border.
  border,

  /// Card with glass effect.
  glass,

  /// Card with elevation.
  elevated,
}
