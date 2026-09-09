part of 'aura_animated_content.dart';

/// Supported content transitions.
enum AuraContentTransition {
  /// Replace content immediately.
  none,

  /// Briefly fade between keyed children.
  fade,

  /// Slide between keyed children.
  slide,

  /// Scale between keyed children.
  scale,
}
