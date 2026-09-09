part of 'aura_interaction_scope.dart';

/// Defines how descendant Aura widgets may respond to user interaction.
enum AuraInteractionMode {
  /// Descendant controls may edit values and invoke callbacks.
  interactive,

  /// Value controls are display-only while local navigation may remain usable.
  readOnly,

  /// Descendant controls do not accept interaction.
  disabled,
}
