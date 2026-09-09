part of 'aura_interaction_scope.dart';

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
