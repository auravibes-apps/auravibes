import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A custom painter for drawing the radio button circles.
///
/// Draws an outer circle with border and an inner filled circle when selected.
class _RadioPainter extends CustomPainter {
  _RadioPainter({
    required this.isSelected,
    required this.color,
    required this.borderColor,
  });

  final bool isSelected;
  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 2; // Account for stroke width

    // Draw outer circle with border
    final outerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, outerRadius, outerPaint);

    // Draw inner filled circle when selected (50% of outer radius)
    if (isSelected) {
      final innerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, outerRadius * 0.5, innerPaint);
    }
  }

  @override
  bool shouldRepaint(_RadioPainter oldDelegate) {
    return isSelected != oldDelegate.isSelected ||
        color != oldDelegate.color ||
        borderColor != oldDelegate.borderColor;
  }
}

/// A configuration class for radio options in a group.
///
/// Used with [AuraRadioGroup] to define the available selections.
class AuraRadioOption<T> {
  /// Creates a radio option with a value, label, and optional subtitle.
  const AuraRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  /// The value this option represents.
  final T value;

  /// The display label for this option.
  final Widget label;

  /// Optional subtitle displayed below the label.
  final Widget? subtitle;
}

/// An individual radio button that communicates with its parent group.
///
/// Follows the const-first design pattern using [AuraColorVariant] for
/// compile-time color configuration.
///
/// ## Selection Contract
///
/// | Condition | Visual State | Interaction |
/// |-----------|--------------|-------------|
/// | value == groupValue | Selected (filled) | None |
/// | value != groupValue | Unselected (empty) | Tappable |
/// | disabled == true | Greyed out | No response |
/// | onChanged == null | Greyed out | No response |
///
/// ## Example
///
/// ```dart
/// AuraRadio<String>(
///   value: 'option1',
///   groupValue: selectedValue,
///   onChanged: (value) => setState(() => selectedValue = value),
///   colorVariant: AuraColorVariant.primary,
/// )
/// ```
class AuraRadio<T> extends StatelessWidget {
  /// Creates an AuraRadio widget.
  const AuraRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    super.key,
    this.colorVariant,
    this.disabled = false,
  });

  /// The value represented by this radio button.
  final T value;

  /// The currently selected value in the group.
  final T? groupValue;

  /// Called when the user selects this radio button.
  ///
  /// If null, the radio button will be disabled.
  final ValueChanged<T?>? onChanged;

  /// The color variant for the radio button when selected.
  final AuraColorVariant? colorVariant;

  /// Whether the radio button is disabled.
  final bool disabled;

  Color _getActiveColor(BuildContext context) {
    final auraColors = context.auraColors;
    return switch (colorVariant) {
      AuraColorVariant.primary => auraColors.primary,
      AuraColorVariant.secondary => auraColors.secondary,
      AuraColorVariant.onSurface => auraColors.onSurface,
      AuraColorVariant.onSurfaceVariant => auraColors.onSurfaceVariant,
      AuraColorVariant.surfaceVariant => auraColors.surfaceVariant,
      AuraColorVariant.error => auraColors.error,
      AuraColorVariant.onPrimary => auraColors.onPrimary,
      AuraColorVariant.success => auraColors.success,
      AuraColorVariant.warning => auraColors.warning,
      AuraColorVariant.info => auraColors.info,
      null => auraColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;
    final isSelected = value == groupValue;
    final effectiveColor = _getActiveColor(context);
    final borderColor = isDisabled
        ? effectiveColor.withValues(alpha: 0.6)
        : effectiveColor;
    final fillColor = isDisabled
        ? effectiveColor.withValues(alpha: 0.6)
        : effectiveColor;

    return MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isDisabled ? null : () => onChanged?.call(value),
        child: Opacity(
          opacity: isDisabled ? 0.6 : 1.0,
          child: SizedBox(
            width: 24,
            height: 24,
            child: CustomPaint(
              painter: _RadioPainter(
                isSelected: isSelected,
                color: fillColor,
                borderColor: borderColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
