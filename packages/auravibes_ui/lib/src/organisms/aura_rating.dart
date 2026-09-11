import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';

/// A controlled integer rating input.
class AuraRating extends StatelessWidget {
  /// Creates a rating input.
  const new({
    required this.value,
    required this.onChanged,
    super.key,
    this.max = 5,
    this.label,
  }) : assert(max > 0, 'max must be positive');

  /// Selected rating from zero through [max].
  final int value;

  /// Called after a user selects a rating.
  final ValueChanged<int>? onChanged;

  /// Largest selectable rating.
  final int max;

  /// Accessible label.
  final String? label;

  @override
  Widget build(BuildContext context) => _AuraRatingSemantics(
    max: max,
    selected: value.clamp(0, max),
    enabled:
        AuraInteractionScope.of(context).allowsValueChanges &&
        onChanged != null,
    callback: onChanged,
    label: label,
    color: context.auraColors.warning,
  );
}

class const _AuraRatingSemantics({
  required final int max,
  required final int selected,
  required final bool enabled,
  required final ValueChanged<int>? callback,
  required final String? label,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _AuraRatingStars(
      max: max,
      selected: selected,
      enabled: enabled,
      callback: callback,
      color: color,
    ),
    label: label,
    value: '$selected of $max',
  );
}

class const _AuraRatingStars({
  required final int max,
  required final int selected,
  required final bool enabled,
  required final ValueChanged<int>? callback,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    children: [
      for (var index = 1; index <= max; index++)
        _AuraRatingStar(
          index: index,
          selected: index <= selected,
          enabled: enabled,
          callback: callback,
          color: color,
        ),
    ],
  );
}

class const _AuraRatingStar({
  required final int index,
  required final bool selected,
  required final bool enabled,
  required final ValueChanged<int>? callback,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onPressed = switch ((enabled: enabled, callback: callback)) {
      (enabled: true, callback: final callback?) => () => callback(index),
      _ => null,
    };

    return IconButton(
      onPressed: onPressed,
      tooltip: '$index',
      icon: Icon(selected ? Icons.star : Icons.star_border, color: color),
    );
  }
}
