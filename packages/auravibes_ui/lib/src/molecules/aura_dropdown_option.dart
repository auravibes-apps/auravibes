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
    final leading = this.leading;
    final trailing = this.trailing;
    final child = this.child;

    Widget result = AuraPressable(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.auraTheme.fromSpacing(.sm),
          horizontal: context.auraTheme.fromSpacing(.md),
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(auraColors),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading,
              const AuraSizedBox(width: .sm),
            ],
            Expanded(
              child:
                  child ??
                  AuraText(
                    child: Text(
                      value.toString(),
                      style: TextStyle(
                        color: isEnabled
                            ? auraColors.onSurface
                            : auraColors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
            ),
            if (trailing != null) ...[
              const AuraSizedBox(width: .sm),
              trailing,
            ] else if (isSelected) ...[
              const AuraSizedBox(width: .sm),
              const AuraIcon(
                Icons.check,
                size: AuraIconSize.small,
                tint: AuraTint.primary,
              ),
            ],
          ],
        ),
      ),
      color: auraColors.primary,
      onPressed: isEnabled ? onTap : null,
    );

    if (semanticLabel != null) {
      result = Semantics(
        child: result,
        label: semanticLabel,
      );
    }

    return result;
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (!isEnabled) return DesignColors.transparent;
    if (isSelected) return colors.primary.withValues(alpha: 0.08);

    return DesignColors.transparent;
  }
}
