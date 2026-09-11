part of 'aura_interaction_scope.dart';

/// Immutable interaction policy inherited by Aura widgets.
@immutable
class AuraInteractionPolicy {
  /// Creates a policy that allows value changes and actions.
  const new interactive({this.allowLocalNavigation = true})
    : mode = AuraInteractionMode.interactive,
      allowsValueChanges = true,
      allowsActions = true,
      allowsNavigation = allowLocalNavigation,
      hashCode = allowLocalNavigation ? 1 : 0;

  /// Creates a policy that displays values without allowing edits or actions.
  const new readOnly({this.allowLocalNavigation = true})
    : mode = AuraInteractionMode.readOnly,
      allowsValueChanges = false,
      allowsActions = false,
      allowsNavigation = allowLocalNavigation,
      hashCode = 1 ^ (allowLocalNavigation ? 1 : 0);

  /// Creates a policy that blocks all interaction.
  const new disabled()
    : mode = AuraInteractionMode.disabled,
      allowLocalNavigation = false,
      allowsValueChanges = false,
      allowsActions = false,
      allowsNavigation = false,
      hashCode = 2;

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
  final int hashCode;

  /// Creates a policy with selected values replaced.
  AuraInteractionPolicy copyWith({
    AuraInteractionMode? mode,
    bool? allowLocalNavigation,
  }) {
    final nextMode = mode ?? this.mode;
    final nextAllowLocalNavigation = _nextAllowLocalNavigation(
      nextMode,
      allowLocalNavigation ?? this.allowLocalNavigation,
    );

    return _policyForMode(nextMode, nextAllowLocalNavigation);
  }

  @override
  String toString() =>
      'AuraInteractionPolicy(mode: $mode, allowLocalNavigation: '
      '$allowLocalNavigation)';

  @override
  bool operator ==(Object other) {
    return other is AuraInteractionPolicy &&
        other.mode == mode &&
        other.allowLocalNavigation == allowLocalNavigation;
  }
}

bool _nextAllowLocalNavigation(
  AuraInteractionMode mode,
  bool allowLocalNavigation,
) => mode != AuraInteractionMode.disabled && allowLocalNavigation;

AuraInteractionPolicy _policyForMode(
  AuraInteractionMode mode,
  bool allowLocalNavigation,
) => switch (mode) {
  .interactive => .interactive(allowLocalNavigation: allowLocalNavigation),
  .readOnly => .readOnly(allowLocalNavigation: allowLocalNavigation),
  .disabled => const AuraInteractionPolicy.disabled(),
};
