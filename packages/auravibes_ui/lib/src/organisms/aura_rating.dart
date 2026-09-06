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
  Widget build(BuildContext context) {
    final enabled =
        AuraInteractionScope.of(context).allowsValueChanges &&
        onChanged != null;
    final callback = onChanged;
    final selected = value.clamp(0, max);

    return Semantics(
      child: Wrap(
        children: [
          for (var index = 1; index <= max; index++)
            IconButton(
              onPressed: enabled && callback != null
                  ? () => callback(index)
                  : null,
              tooltip: '$index',
              icon: Icon(
                index <= selected ? Icons.star : Icons.star_border,
                color: context.auraColors.warning,
              ),
            ),
        ],
      ),
      label: label,
      value: '$selected of $max',
    );
  }
}
