import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A tokenized row or column layout.
class AuraFlex extends StatelessWidget {
  /// Creates a flex layout with an explicit direction.
  const new _(
    this._direction, {
    required this.children,
    this.spacing = AuraSpacing.base,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.padding,
    super.key,
  });

  /// Creates a horizontal flex layout.
  const new row({
    required List<Widget> children,
    AuraSpacing spacing = AuraSpacing.base,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    AuraEdgeInsetsGeometry? padding,
    Key? key,
  }) : this._(
         Axis.horizontal,
         children: children,
         spacing: spacing,
         crossAxisAlignment: crossAxisAlignment,
         mainAxisSize: mainAxisSize,
         mainAxisAlignment: mainAxisAlignment,
         padding: padding,
         key: key,
       );

  /// Creates a vertical flex layout.
  const new column({
    required List<Widget> children,
    AuraSpacing spacing = AuraSpacing.base,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    AuraEdgeInsetsGeometry? padding,
    Key? key,
  }) : this._(
         Axis.vertical,
         children: children,
         spacing: spacing,
         crossAxisAlignment: crossAxisAlignment,
         mainAxisSize: mainAxisSize,
         mainAxisAlignment: mainAxisAlignment,
         padding: padding,
         key: key,
       );

  final Axis _direction;

  /// Flex children.
  final List<Widget> children;

  /// Cross-axis alignment.
  final CrossAxisAlignment crossAxisAlignment;

  /// Main-axis size.
  final MainAxisSize mainAxisSize;

  /// Main-axis alignment.
  final MainAxisAlignment mainAxisAlignment;

  /// Optional tokenized padding around the layout.
  final AuraEdgeInsetsGeometry? padding;

  /// Spacing between children.
  final AuraSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final padding = this.padding;
    final flex = Flex(
      direction: _direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      spacing: context.auraTheme.fromSpacing(spacing),
      children: children,
    );

    if (padding == null) return flex;

    return AuraPadding(child: flex, padding: padding);
  }
}

/// A token-free spacer for generated and ordinary Aura layouts.
class AuraSpacer extends StatelessWidget {
  /// Creates a fixed or flexible spacer.
  const new({super.key, this.size, this.flex = 1});

  /// Fixed size. When omitted, the spacer expands in a Flex parent.
  final double? size;

  /// Flex factor when [size] is omitted.
  final int flex;

  @override
  Widget build(BuildContext context) =>
      size == null ? Spacer(flex: flex) : SizedBox(width: size, height: size);
}

/// Gives a child a controlled flex factor in an Aura row or column.
class AuraFlexItem extends StatelessWidget {
  /// Creates a flex item.
  const new({
    required this.child,
    super.key,
    this.flex = 1,
    this.fit = FlexFit.loose,
  });

  /// Child laid out by the surrounding Flex.
  final Widget child;

  /// Flex factor.
  final int flex;

  /// Whether the item fills its allocation.
  final FlexFit fit;

  @override
  Widget build(BuildContext context) =>
      Flexible(flex: flex, fit: fit, child: child);
}
