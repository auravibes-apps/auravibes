import 'package:auravibes_ui/src/tokens/tokens.dart';
import 'package:flutter/widgets.dart';

/// A [SizedBox] whose dimensions are selected by [AuraSpacing] and resolved
/// from the ambient theme. This keeps sizing rethemeable: a subtree Theme
/// override that rescales spacing resizes every [AuraSizedBox].
///
/// [AuraSpacing.none] resolves to `null` (no constraint), so the default
/// constructor behaves as a passthrough wrapper.
class AuraSizedBox extends StatelessWidget {
  /// Default constructor.
  const AuraSizedBox({
    this.width = AuraSpacing.none,
    this.height = AuraSpacing.none,
    this.child,
    super.key,
  });

  /// Horizontal spacing. Selects the resolved [width].
  final AuraSpacing width;

  /// Vertical spacing. Selects the resolved [height].
  final AuraSpacing height;

  /// The widget below this widget in the tree.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;

    return SizedBox(
      width: width == AuraSpacing.none ? null : theme.fromSpacing(width),
      height: height == AuraSpacing.none ? null : theme.fromSpacing(height),
      child: child,
    );
  }
}
