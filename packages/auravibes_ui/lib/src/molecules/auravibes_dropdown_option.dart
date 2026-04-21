import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/atoms/auravibes_pressable.dart';
import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable dropdown option component following the Aura design system.
///
/// This option provides consistent styling for dropdown items with support
/// for custom content, icons, and selection states.
class AuraDropdownOption<T> extends StatelessWidget {
  /// Creates a Aura dropdown option.
  const AuraDropdownOption({
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
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    Widget result = AuraPressable(
      color: Colors.blue,
      onPressed: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSpacing.md,
          vertical: DesignSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(auraColors),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: DesignSpacing.sm),
            ],
            Expanded(
              child: child ?? _buildDefaultLabel(context),
            ),
            if (trailing != null) ...[
              const SizedBox(width: DesignSpacing.sm),
              trailing!,
            ] else if (isSelected) ...[
              const SizedBox(width: DesignSpacing.sm),
              const AuraIcon(
                Icons.check,
                color: AuraColorVariant.primary,
                size: AuraIconSize.small,
              ),
            ],
          ],
        ),
      ),
    );

    if (semanticLabel != null) {
      result = Semantics(
        label: semanticLabel,
        child: result,
      );
    }

    return result;
  }

  Widget _buildDefaultLabel(BuildContext context) {
    final auraColors = context.auraColors;

    return AuraText(
      child: Text(
        value.toString(),
        style: TextStyle(
          color: isEnabled
              ? auraColors.onSurface
              : auraColors.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (!isEnabled) return Colors.transparent;
    if (isSelected) return colors.primary.withValues(alpha: 0.08);
    return Colors.transparent;
  }
}
