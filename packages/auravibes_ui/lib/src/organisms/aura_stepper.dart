import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

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
}

/// A read-only sequence of progress steps.
class AuraStepper extends StatelessWidget {
  /// Creates a stepper.
  const new({required this.steps, super.key});

  /// Steps in chronological order.
  final List<AuraStep> steps;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: context.auraTheme.spacing.sm,
    children: [
      for (final (index, step) in steps.indexed)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: context.auraTheme.spacing.sm,
          children: [
            AuraIcon(
              _icon(step.state),
              tint: _tint(step.state),
              semanticLabel: step.state.name,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuraText(child: Text(step.title)),
                  if (step.description case final value?)
                    AuraText(child: Text(value), style: .bodySmall),
                ],
              ),
            ),
            if (index < steps.length - 1) const SizedBox.shrink(),
          ],
        ),
    ],
  );

  IconData _icon(AuraStepState state) => switch (state) {
    .complete => Icons.check_circle,
    .current => Icons.radio_button_checked,
    .error => Icons.error,
    .pending => Icons.radio_button_unchecked,
  };

  AuraTint _tint(AuraStepState state) => switch (state) {
    .complete => .success,
    .current => .primary,
    .error => .error,
    .pending => .secondary,
  };
}
