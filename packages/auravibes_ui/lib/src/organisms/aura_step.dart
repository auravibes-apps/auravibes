part of 'aura_stepper.dart';

/// One read-only step.
class AuraStep {
  /// Creates a step.
  const new({
    required this.title,
    this.description,
    this.state = AuraStepState.pending,
  });

  /// Caller-localized title.
  final String title;

  /// Optional supporting text.
  final String? description;

  /// Display state.
  final AuraStepState state;

  /// Whether this step has supporting text.
  bool hasDescription() => description != null;
}
