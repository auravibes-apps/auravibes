// ignore_for_file: prefer-single-widget-per-file
// Required: UI components keep related private widgets together.
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

  /// Enum representing different spacing options for layout components.
  final AuraSpacing spacing;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      spacing: context.auraTheme.fromSpacing(spacing),
      children: children,
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

  /// Enum representing different spacing options for layout components.
  final AuraSpacing spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      spacing: context.auraTheme.fromSpacing(spacing),
      children: children,
    );
  }
}
