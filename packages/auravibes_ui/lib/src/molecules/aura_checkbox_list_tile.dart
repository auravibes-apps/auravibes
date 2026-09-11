import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/molecules/aura_checkbox.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart' show AuraTint;
import 'package:flutter/widgets.dart';

/// A full-width settings row with an Aura checkbox, title, and optional
/// subtitle.
class AuraCheckboxListTile extends StatelessWidget {
  /// Creates an Aura checkbox list tile.
  const new({
    required this.value,
    required this.onChanged,
    required this.title,
    super.key,
    this.subtitle,
    this.tint,
    this.disabled = false,
    this.autofocus = false,
    this.semanticLabel = 'Checkbox',
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

  /// A semantic label announced by assistive technologies.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;

    return MergeSemantics(
      child: Semantics(
        child: _AuraCheckboxTileGesture(tile: this, isDisabled: isDisabled),
        container: true,
        label: semanticLabel,
      ),
    );
  }
}

class const _AuraCheckboxTileGesture({
  required final AuraCheckboxListTile tile,
  required final bool isDisabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _AuraCheckboxTileRow(tile: tile, isDisabled: isDisabled),
    onTap: isDisabled ? null : () => tile.onChanged?.call(!tile.value),
    behavior: .opaque,
  );
}

class _AuraCheckboxTileRow extends StatelessWidget {
  new({required AuraCheckboxListTile tile, required bool isDisabled})
    : _child = Row(
        crossAxisAlignment: .start,
        children: [
          AuraCheckbox(
            value: tile.value,
            onChanged: isDisabled ? null : tile.onChanged,
            tint: tile.tint,
            disabled: isDisabled,
            autofocus: tile.autofocus,
            semanticLabel: tile.semanticLabel,
          ),
          const SizedBox(width: 12),
          Expanded(child: _AuraCheckboxTileText(tile: tile)),
        ],
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraCheckboxTileText({required final AuraCheckboxListTile tile})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      AuraText(child: tile.title),
      if (tile.subtitle case final subtitle?) ...[
        const SizedBox(height: 4),
        AuraText(child: subtitle, style: .bodySmall),
      ],
    ],
  );
}
