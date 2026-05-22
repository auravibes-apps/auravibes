import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// Contextual Column management
class AuraColumn extends StatelessWidget {
  /// creates auravibes column
  const AuraColumn({
    required this.children,
    this.spacing = AuraSpacing.base,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    super.key,
  });

  /// Flex children
  final List<Widget> children;

  /// crossAxisAlignment
  final CrossAxisAlignment crossAxisAlignment;

  /// mainAxisSize
  final MainAxisSize mainAxisSize;

  /// mainAxisAlignment
  final MainAxisAlignment mainAxisAlignment;

  /// Enum representing different spacing options for layout components
  final AuraSpacing spacing;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      spacing: context.auraTheme.fromSpacing(spacing),
      children: children,
    );
  }
}

/// Contextual Row management
class AuraRow extends StatelessWidget {
  /// creates auravibes row
  const AuraRow({
    required this.children,
    this.spacing = AuraSpacing.base,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    super.key,
  });

  /// Flex children
  final List<Widget> children;

  /// crossAxisAlignment
  final CrossAxisAlignment crossAxisAlignment;

  /// mainAxisSize
  final MainAxisSize mainAxisSize;

  /// mainAxisAlignment
  final MainAxisAlignment mainAxisAlignment;

  /// Enum representing different spacing options for layout components
  final AuraSpacing spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      spacing: context.auraTheme.fromSpacing(spacing),
      children: children,
    );
  }
}
