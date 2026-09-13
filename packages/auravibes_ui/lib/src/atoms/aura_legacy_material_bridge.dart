import 'package:material_ui/material_ui.dart';

/// Temporarily provides legacy Material theme and localization data to
/// third-party widgets that have not migrated to material_ui.
///
/// Remove this after direct dependencies no longer import
/// package:flutter/material.dart or package:flutter/cupertino.dart.
class AuraLegacyMaterialBridge extends StatelessWidget {
  /// Creates a legacy Material compatibility boundary.
  const new({required this.child, super.key});

  /// Descendant subtree containing legacy third-party widgets.
  final Widget child;

  @override
  Widget build(BuildContext _) {
    // ignore: deprecated_member_use - Temporary bridge for legacy dependencies.
    return MaterialUiCompatibilityBridge(child: child);
  }
}
