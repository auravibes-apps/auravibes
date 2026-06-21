// Required: UI components keep related private widgets together.
import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// Contextual Column management.
class AuraColumn extends StatelessWidget {
  /// Creates auravibes column.
  const AuraColumn({
    required this.children,
    this.spacing = AuraSpacing.base,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.padding,
    super.key,
  });

  /// Flex children.
  final List<Widget> children;

  /// CrossAxisAlignment.
  final CrossAxisAlignment crossAxisAlignment;

  /// MainAxisSize.
  final MainAxisSize mainAxisSize;

  /// MainAxisAlignment.
  final MainAxisAlignment mainAxisAlignment;

  /// Optional tokenized padding around the column.
  final AuraEdgeInsetsGeometry? padding;

  /// Enum representing different spacing options for layout components.
  final AuraSpacing spacing;
  @override
  Widget build(BuildContext context) {
    final padding = this.padding;
    final column = Column(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      spacing: context.auraTheme.fromSpacing(spacing),
      children: children,
    );

    if (padding == null) {
      return column;
    }

    return AuraPadding(
      child: column,
      padding: padding,
    );
  }
}

/// Contextual Row management.
class AuraRow extends StatelessWidget {
  /// Creates auravibes row.
  const AuraRow({
    required this.children,
    this.spacing = AuraSpacing.base,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.padding,
    super.key,
  });

  /// Flex children.
  final List<Widget> children;

  /// CrossAxisAlignment.
  final CrossAxisAlignment crossAxisAlignment;

  /// MainAxisSize.
  final MainAxisSize mainAxisSize;

  /// MainAxisAlignment.
  final MainAxisAlignment mainAxisAlignment;

  /// Optional tokenized padding around the row.
  final AuraEdgeInsetsGeometry? padding;

  /// Enum representing different spacing options for layout components.
  final AuraSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final padding = this.padding;
    final row = Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      spacing: context.auraTheme.fromSpacing(spacing),
      children: children,
    );

    if (padding == null) {
      return row;
    }

    return AuraPadding(
      child: row,
      padding: padding,
    );
  }
}
