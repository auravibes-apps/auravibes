import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

/// Constrains an interactive child to the minimum size inherited from
/// [AuraTheme].
class AuraInteractionTarget extends StatelessWidget {
  /// Creates a minimum-size interaction target.
  const new({required this.child, super.key});

  /// Widget that receives the minimum target constraints.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final targetSize = context.auraTheme.interactionSizes.minimumTargetSize;

    return ConstrainedBox(
      constraints: .new(minWidth: targetSize, minHeight: targetSize),
      child: child,
    );
  }
}
