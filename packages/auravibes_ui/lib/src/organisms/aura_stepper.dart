import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

part 'aura_step_state.dart';
part 'aura_step.dart';

/// A read-only sequence of progress steps.
class AuraStepper extends StatelessWidget {
  /// Creates a stepper.
  const new({required this.steps, super.key});

  /// Steps in chronological order.
  final List<AuraStep> steps;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    spacing: context.auraTheme.spacing.sm,
    children: [
      for (final (index, step) in steps.indexed)
        _AuraStepperItem(
          step: step,
          isLast: index == steps.length - 1,
          spacing: context.auraTheme.spacing.sm,
        ),
    ],
  );
}

class _AuraStepperItem extends StatelessWidget {
  new({required AuraStep step, required bool isLast, required double spacing})
    : _child = Row(
        crossAxisAlignment: .start,
        spacing: spacing,
        children: [
          _AuraStepperIcon(state: step.state),
          Expanded(child: _AuraStepperText(step: step)),
          if (!isLast) const SizedBox.shrink(),
        ],
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraStepperIcon({required final AuraStepState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIcon(
    _stepIcon(state),
    tint: _stepTint(state),
    semanticLabel: state.name,
  );
}

class const _AuraStepperText({required final AuraStep step})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      AuraText(child: Text(step.title)),
      if (step.description case final value?)
        AuraText(child: Text(value), style: .bodySmall),
    ],
  );
}

IconData _stepIcon(AuraStepState state) => switch (state) {
  .complete => Icons.check_circle,
  .current => Icons.radio_button_checked,
  .error => Icons.error,
  .pending => Icons.radio_button_unchecked,
};

AuraTint _stepTint(AuraStepState state) => switch (state) {
  .complete => .success,
  .current => .primary,
  .error => .error,
  .pending => .secondary,
};
