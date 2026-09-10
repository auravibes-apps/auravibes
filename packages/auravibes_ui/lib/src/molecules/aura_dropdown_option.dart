// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable dropdown option component following the Aura design system.
///
/// This option provides consistent styling for dropdown items with support
/// for custom content, icons, and selection states.
class AuraDropdownOption<T> extends StatelessWidget {
  /// Creates a Aura dropdown option.
  const new({
    required this.value,
    super.key,
    this.child,
    this.leading,
    this.trailing,
    this.isEnabled = true,
    this.isSelected = false,
    this.onTap,
    this.semanticLabel,
  });

  /// The value associated with this option.
  final T value;

  /// The label widget to display.
  final Widget? child;

  /// A widget to display before the label.
  final Widget? leading;

  /// A widget to display after the label.
  final Widget? trailing;

  /// Whether the option is enabled.
  final bool isEnabled;

  /// Whether the option is currently selected.
  final bool isSelected;

  /// Callback when the option is tapped.
  final VoidCallback? onTap;

  /// A semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => _AuraDropdownOptionBody(option: this);

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (!isEnabled) return DesignColors.transparent;
    if (isSelected) return colors.primary.withValues(alpha: 0.08);

    return DesignColors.transparent;
  }
}

class const _AuraDropdownOptionBody<T>({
  required final AuraDropdownOption<T> option,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final result = _AuraDropdownOptionButton(option: option);
    final label = option.semanticLabel;

    return label == null ? result : Semantics(child: result, label: label);
  }
}

class const _AuraDropdownOptionButton<T>({
  required final AuraDropdownOption<T> option,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return AuraPressable(
      child: _AuraDropdownOptionContent(option: option, colors: colors),
      color: colors.primary,
      onPressed: option.isEnabled ? option.onTap : null,
    );
  }
}

class const _AuraDropdownOptionContent<T>({
  required final AuraDropdownOption<T> option,
  required final AuraColorScheme colors,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      vertical: context.auraTheme.fromSpacing(.sm),
      horizontal: context.auraTheme.fromSpacing(.md),
    ),
    decoration: BoxDecoration(color: option._getBackgroundColor(colors)),
    child: _AuraDropdownOptionRow(option: option),
  );
}

class const _AuraDropdownOptionRow<T>({
  required final AuraDropdownOption<T> option,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _AuraDropdownOptionLeading(option: option),
      Expanded(child: option.child ?? _AuraDropdownOptionLabel(option: option)),
      _AuraDropdownOptionTrailing(option: option),
    ],
  );
}

class const _AuraDropdownOptionLeading<T>({
  required final AuraDropdownOption<T> option,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (option.leading) {
    final leading? => Row(
      mainAxisSize: .min,
      children: [
        leading,
        const AuraSizedBox(width: .sm),
      ],
    ),
    null => const SizedBox.shrink(),
  };
}

class _AuraDropdownOptionTrailing<T> extends StatelessWidget {
  _AuraDropdownOptionTrailing({required AuraDropdownOption<T> option})
    : _child = switch (option.trailing) {
        final trailing? => Row(
          mainAxisSize: .min,
          children: [
            const AuraSizedBox(width: .sm),
            trailing,
          ],
        ),
        null when option.isSelected => const Row(
          mainAxisSize: .min,
          children: [
            AuraSizedBox(width: .sm),
            AuraIcon(Icons.check, size: .small, tint: .primary),
          ],
        ),
        null => const SizedBox.shrink(),
      };

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraDropdownOptionLabel<T>({
  required final AuraDropdownOption<T> option,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      option.value.toString(),
      style: .new(
        color: option.isEnabled
            ? context.auraColors.onSurface
            : context.auraColors.onSurface.withValues(alpha: 0.6),
      ),
    ),
  );
}
