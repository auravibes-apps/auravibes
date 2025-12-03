import 'package:auravibes_ui/src/atoms/auravibes_padding.dart'
    show AuraEdgeInsetsGeometry, AuraPadding;
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart'
    show AuraThemeExtension;
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show DesignShadows, DesignSpacing;
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

  /// The background color of the container.
  final Color? backgroundColor;

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

    var container = child;

    if (padding != null) {
      container = AuraPadding(
        padding: padding!,
        child: child,
      );
    }

    container = Container(
      width: width,
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(
        color: backgroundColor ?? auraTheme.colors.surface,
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : null,
        border: border,
        boxShadow: _getBoxShadow(),
      ),
      child: container,
    );

    if (margin != null) {
      container = AuraPadding(
        padding: margin!,
        child: container,
      );
    }

    if (semanticLabel != null) {
      container = Semantics(
        label: semanticLabel,
        container: true,
        child: container,
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

/// Predefined padding options for [AuraContainer].
class AuraContainerPadding {
  AuraContainerPadding._();

  /// Extra small padding.
  static const EdgeInsets xs = EdgeInsets.all(DesignSpacing.xs);

  /// Small padding.
  static const EdgeInsets sm = EdgeInsets.all(DesignSpacing.sm);

  /// Medium padding.
  static const EdgeInsets md = EdgeInsets.all(DesignSpacing.md);

  /// Large padding.
  static const EdgeInsets lg = EdgeInsets.all(DesignSpacing.lg);

  /// Extra large padding.
  static const EdgeInsets xl = EdgeInsets.all(DesignSpacing.xl);

  /// 2x extra large padding.
  static const EdgeInsets xl2 = EdgeInsets.all(DesignSpacing.xl2);

  /// 3x extra large padding.
  static const EdgeInsets xl3 = EdgeInsets.all(DesignSpacing.xl3);

  /// Horizontal extra small padding.
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(
    horizontal: DesignSpacing.xs,
  );

  /// Horizontal small padding.
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(
    horizontal: DesignSpacing.sm,
  );

  /// Horizontal medium padding.
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(
    horizontal: DesignSpacing.md,
  );

  /// Horizontal large padding.
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(
    horizontal: DesignSpacing.lg,
  );

  /// Horizontal extra large padding.
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(
    horizontal: DesignSpacing.xl,
  );

  /// Vertical extra small padding.
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(
    vertical: DesignSpacing.xs,
  );

  /// Vertical small padding.
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(
    vertical: DesignSpacing.sm,
  );

  /// Vertical medium padding.
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(
    vertical: DesignSpacing.md,
  );

  /// Vertical large padding.
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(
    vertical: DesignSpacing.lg,
  );

  /// Vertical extra large padding.
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(
    vertical: DesignSpacing.xl,
  );
}

/// Predefined margin options for [AuraContainer].
class AuraContainerMargin {
  AuraContainerMargin._();

  /// Extra small margin.
  static const EdgeInsets xs = EdgeInsets.all(DesignSpacing.xs);

  /// Small margin.
  static const EdgeInsets sm = EdgeInsets.all(DesignSpacing.sm);

  /// Medium margin.
  static const EdgeInsets md = EdgeInsets.all(DesignSpacing.md);

  /// Large margin.
  static const EdgeInsets lg = EdgeInsets.all(DesignSpacing.lg);

  /// Extra large margin.
  static const EdgeInsets xl = EdgeInsets.all(DesignSpacing.xl);

  /// 2x extra large margin.
  static const EdgeInsets xl2 = EdgeInsets.all(DesignSpacing.xl2);

  /// 3x extra large margin.
  static const EdgeInsets xl3 = EdgeInsets.all(DesignSpacing.xl3);

  /// Horizontal extra small margin.
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(
    horizontal: DesignSpacing.xs,
  );

  /// Horizontal small margin.
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(
    horizontal: DesignSpacing.sm,
  );

  /// Horizontal medium margin.
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(
    horizontal: DesignSpacing.md,
  );

  /// Horizontal large margin.
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(
    horizontal: DesignSpacing.lg,
  );

  /// Horizontal extra large margin.
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(
    horizontal: DesignSpacing.xl,
  );

  /// Vertical extra small margin.
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(
    vertical: DesignSpacing.xs,
  );

  /// Vertical small margin.
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(
    vertical: DesignSpacing.sm,
  );

  /// Vertical medium margin.
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(
    vertical: DesignSpacing.md,
  );

  /// Vertical large margin.
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(
    vertical: DesignSpacing.lg,
  );

  /// Vertical extra large margin.
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(
    vertical: DesignSpacing.xl,
  );
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
