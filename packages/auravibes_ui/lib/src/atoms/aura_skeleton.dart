import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

/// A reduced-motion-safe placeholder for loading content.
class AuraSkeleton extends StatelessWidget {
  /// Creates a skeleton block.
  const new({
    super.key,
    this.width,
    this.height = 16,
    this.circular = false,
    this.semanticLabel,
  });

  /// Optional bounded width.
  final double? width;

  /// Block height.
  final double height;

  /// Whether the block is circular.
  final bool circular;

  /// Optional accessible loading description.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => _AuraSkeletonContent(
    width: width,
    height: height,
    circular: circular,
    semanticLabel: semanticLabel,
    color: context.auraColors.surfaceVariant,
  ).child;
}

class _AuraSkeletonContent {
  _AuraSkeletonContent({
    required double? width,
    required double height,
    required bool circular,
    required String? semanticLabel,
    required Color color,
  }) : child = Semantics(
         child: SizedBox(
           width: width,
           height: height,
           child: DecoratedBox(
             decoration: BoxDecoration(
               color: color,
               borderRadius: BorderRadius.circular(circular ? height / 2 : 4),
             ),
           ),
         ),
         label: semanticLabel,
       );

  final Widget child;
}
