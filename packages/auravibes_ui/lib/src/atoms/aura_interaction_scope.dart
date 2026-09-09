import 'package:flutter/widgets.dart';

part 'aura_interaction_mode.dart';
part 'aura_interaction_policy.dart';

/// Inherited interaction policy for a subtree of Aura widgets.
class AuraInteractionScope extends InheritedWidget {
  /// Creates an interaction scope.
  const new({required this.policy, required super.child, super.key});

  /// Policy applied to descendant Aura widgets.
  final AuraInteractionPolicy policy;

  /// Returns the nearest policy or the default interactive policy.
  static AuraInteractionPolicy of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AuraInteractionScope>()
            ?.policy ??
        const AuraInteractionPolicy.interactive();
  }

  @override
  bool updateShouldNotify(AuraInteractionScope oldWidget) {
    return policy != oldWidget.policy;
  }
}
