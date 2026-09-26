import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

/// Provides legacy theme and localization data to third-party widgets.
class AuraLegacyMaterialBridge extends StatelessWidget {
  /// Creates a legacy Material compatibility boundary.
  const new({required this.child, super.key});

  /// Descendant subtree containing legacy third-party widgets.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use - Legacy compatibility bridge.
    return material_ui.MaterialUiCompatibilityBridge(
      child: material_ui.Material(
        type: material_ui.MaterialType.transparency,
        child: AuraSdkMaterialSurface(child: child),
      ),
    );
  }
}
