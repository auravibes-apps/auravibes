import 'package:flutter/material.dart' as sdk_material;
import 'package:flutter/widgets.dart';

/// Provides Flutter SDK Material ancestors for controls from Flutter Material.
class AuraSdkMaterialSurface extends StatelessWidget {
  /// Creates a surface for SDK Material controls.
  const new({required this.child, super.key});

  /// Subtree that uses SDK Material controls.
  final Widget child;

  @override
  Widget build(BuildContext context) => sdk_material.Material(
    type: sdk_material.MaterialType.transparency,
    child: child,
  );
}
