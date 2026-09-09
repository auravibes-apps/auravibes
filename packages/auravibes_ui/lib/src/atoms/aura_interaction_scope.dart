import 'package:flutter/widgets.dart';

/// Defines how descendant Aura widgets may respond to user interaction.
enum AuraInteractionMode {
  /// Descendant controls may edit values and invoke callbacks.
  interactive,

  /// Value controls are display-only while local navigation may remain usable.
  readOnly,

  /// Descendant controls do not accept interaction.
  disabled,
}

/// Immutable interaction policy inherited by Aura widgets.
@immutable
class AuraInteractionPolicy {
  /// Creates a policy that allows value changes and actions.
  const new interactive({this.allowLocalNavigation = true})
    : mode = AuraInteractionMode.interactive;

  /// Creates a policy that displays values without allowing edits or actions.
  const new readOnly({this.allowLocalNavigation = true})
    : mode = AuraInteractionMode.readOnly;

  /// Creates a policy that blocks all interaction.
  const new disabled()
    : mode = AuraInteractionMode.disabled,
      allowLocalNavigation = false;

  /// Current interaction mode.
  final AuraInteractionMode mode;

  /// Whether navigation-only controls may respond.
  final bool allowLocalNavigation;

  /// Whether value controls may change their value.
  bool get allowsValueChanges => mode == AuraInteractionMode.interactive;

  /// Whether command callbacks may be invoked.
  bool get allowsActions => mode == AuraInteractionMode.interactive;

  /// Whether navigation callbacks may be invoked.
  bool get allowsNavigation =>
      mode != AuraInteractionMode.disabled && allowLocalNavigation;

  @override
  int get hashCode => Object.hash(mode, allowLocalNavigation);

  @override
  bool operator ==(Object other) {
    return other is AuraInteractionPolicy &&
        other.mode == mode &&
        other.allowLocalNavigation == allowLocalNavigation;
  }
}

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
