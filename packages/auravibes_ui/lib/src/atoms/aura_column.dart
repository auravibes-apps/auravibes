import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

export 'aura_row.dart';

/// Contextual Column management.
class AuraColumn extends StatelessWidget {
  /// Creates an Aura column.
  const new({
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

    if (padding == null) return column;

    return AuraPadding(child: column, padding: padding);
  }
}
