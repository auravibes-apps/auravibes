import 'package:auravibes_ui/src/molecules/aura_radio_option.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A list tile with an integrated radio button for settings-style selections.
class AuraRadioListTile<T> extends StatelessWidget {
  /// Creates an AuraRadioListTile widget.
  const AuraRadioListTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    super.key,
    this.subtitle,
    this.tint,
    this.disabled = false,
    this.semanticLabel = 'Radio button',
  });

  /// The value represented by this tile.
  final T value;

  /// The currently selected value in the group.
  final T? groupValue;

  /// Called when the user selects this tile.
  final ValueChanged<T?>? onChanged;

  /// The title widget.
  final Widget title;

  /// Optional subtitle widget.
  final Widget? subtitle;

  /// Tint when selected.
  final AuraTint? tint;

  /// Whether the tile is disabled.
  final bool disabled;

  /// A semantic label announced by assistive technologies.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;
    final subtitle = this.subtitle;

    final onTap = isDisabled ? null : () => onChanged?.call(value);

    final radioTile = MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        child: Opacity(
          opacity: isDisabled ? 0.6 : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: AuraRadio<T>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: isDisabled ? null : onChanged,
                  tint: tint,
                  disabled: isDisabled,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style:
                          Theme.of(context).textTheme.bodyMedium ??
                          const TextStyle(fontSize: 16),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.auraColors.onSurfaceVariant,
                            ) ??
                            TextStyle(
                              color: context.auraColors.onSurfaceVariant,
                              fontSize: 14,
                            ),
                        child: subtitle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
      ),
    );

    return Semantics(
      child: radioTile,
      container: true,
      excludeSemantics: true,
      enabled: !isDisabled,
      checked: value == groupValue,
      inMutuallyExclusiveGroup: true,
      label: semanticLabel ?? 'Radio button',
      onTap: onTap,
    );
  }
}
