part of 'aura_stepper.dart';

/// Display state for an [AuraStep].
enum AuraStepState {
  /// Not yet reached.
  pending,

  /// Current step.
  current,

  /// Finished successfully.
  complete,

  /// Finished with an error.
  error,
}
