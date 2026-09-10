part of 'aura_interaction_scope.dart';

/// Immutable interaction policy inherited by Aura widgets.
@immutable
class AuraInteractionPolicy {
  /// Creates a policy that allows value changes and actions.
  const new interactive({this.allowLocalNavigation = true})
    : mode = AuraInteractionMode.interactive,
      allowsValueChanges = true,
      allowsActions = true,
      allowsNavigation = allowLocalNavigation;

  /// Creates a policy that displays values without allowing edits or actions.
  const new readOnly({this.allowLocalNavigation = true})
    : mode = AuraInteractionMode.readOnly,
      allowsValueChanges = false,
      allowsActions = false,
      allowsNavigation = allowLocalNavigation;

  /// Creates a policy that blocks all interaction.
  const new disabled()
    : mode = AuraInteractionMode.disabled,
      allowLocalNavigation = false,
      allowsValueChanges = false,
      allowsActions = false,
      allowsNavigation = false;

  /// Current interaction mode.
  final AuraInteractionMode mode;

  /// Whether navigation-only controls may respond.
  final bool allowLocalNavigation;

  /// Whether value controls may change their value.
  final bool allowsValueChanges;

  /// Whether command callbacks may be invoked.
  final bool allowsActions;

  /// Whether navigation callbacks may be invoked.
  final bool allowsNavigation;

  @override
  int get hashCode => Object.hash(mode, allowLocalNavigation);

  /// Creates a policy with selected values replaced.
  AuraInteractionPolicy copyWith({
    AuraInteractionMode? mode,
    bool? allowLocalNavigation,
  }) {
    final nextMode = mode ?? this.mode;
    final nextAllowLocalNavigation =
        nextMode != AuraInteractionMode.disabled &&
        (allowLocalNavigation ?? this.allowLocalNavigation);

    return switch (nextMode) {
      AuraInteractionMode.interactive => AuraInteractionPolicy.interactive(
        allowLocalNavigation: nextAllowLocalNavigation,
      ),
      AuraInteractionMode.readOnly => AuraInteractionPolicy.readOnly(
        allowLocalNavigation: nextAllowLocalNavigation,
      ),
      AuraInteractionMode.disabled => const AuraInteractionPolicy.disabled(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is AuraInteractionPolicy &&
        other.mode == mode &&
        other.allowLocalNavigation == allowLocalNavigation;
  }
}
