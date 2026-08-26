import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/molecules/aura_checkbox.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart' show AuraTint;
import 'package:flutter/widgets.dart';

/// A full-width settings row with an Aura checkbox, title, and optional
/// subtitle.
class AuraCheckboxListTile extends StatelessWidget {
  /// Creates an Aura checkbox list tile.
  const AuraCheckboxListTile({
    required this.value,
    required this.onChanged,
    required this.title,
    super.key,
    this.subtitle,
    this.tint,
    this.disabled = false,
    this.autofocus = false,
  });

  /// Whether the checkbox is selected.
  final bool value;

  /// Called when the user toggles the checkbox.
  final ValueChanged<bool>? onChanged;

  /// The title widget.
  final Widget title;

  /// Optional subtitle widget.
  final Widget? subtitle;

  /// Tint used when selected.
  final AuraTint? tint;

  /// Whether the tile is disabled.
  final bool disabled;

  /// Whether this checkbox tile should request focus when built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;
    final subtitle = this.subtitle;

    return Semantics(
      child: GestureDetector(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuraCheckbox(
              value: value,
              onChanged: isDisabled ? null : onChanged,
              tint: tint,
              disabled: isDisabled,
              autofocus: autofocus,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuraText(child: title),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    AuraText(child: subtitle, style: AuraTextStyle.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
        onTap: isDisabled ? null : () => onChanged?.call(!value),
        behavior: HitTestBehavior.opaque,
      ),
      enabled: !isDisabled,
      checked: value,
    );
  }
}
