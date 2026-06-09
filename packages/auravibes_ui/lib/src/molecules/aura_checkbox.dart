// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraColorVariant;
import 'package:flutter/material.dart';

/// An Aura checkbox that follows the const-first design system.
class AuraCheckbox extends StatelessWidget {
  /// Creates an Aura checkbox.
  const AuraCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
    this.colorVariant,
    this.disabled = false,
  });

  /// Whether the checkbox is selected.
  final bool value;

  /// Called when the user toggles the checkbox.
  final ValueChanged<bool>? onChanged;

  /// Color variant used when selected.
  final AuraColorVariant? colorVariant;

  /// Whether the checkbox is disabled.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;

    return Semantics(
      child: MouseRegion(
        cursor: isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: GestureDetector(
          child: Opacity(
            opacity: isDisabled ? 0.6 : 1,
            child: _CheckboxVisual(
              value: value,
              colorVariant: colorVariant,
              disabled: isDisabled,
            ),
          ),
          onTap: isDisabled ? null : () => onChanged?.call(!value),
          behavior: HitTestBehavior.opaque,
        ),
      ),
      enabled: !isDisabled,
      checked: value,
    );
  }
}

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
    this.colorVariant,
    this.disabled = false,
  });

  /// Whether the checkbox is selected.
  final bool value;

  /// Called when the user toggles the checkbox.
  final ValueChanged<bool>? onChanged;

  /// The title widget.
  final Widget title;

  /// Optional subtitle widget.
  final Widget? subtitle;

  /// Color variant used when selected.
  final AuraColorVariant? colorVariant;

  /// Whether the tile is disabled.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;
    final subtitle = this.subtitle;

    return MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        child: Opacity(
          opacity: isDisabled ? 0.6 : 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuraCheckbox(
                value: value,
                onChanged: isDisabled ? null : onChanged,
                colorVariant: colorVariant,
                disabled: isDisabled,
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
        onTap: isDisabled ? null : () => onChanged?.call(!value),
        behavior: HitTestBehavior.opaque,
      ),
    );
  }
}

class _CheckboxVisual extends StatelessWidget {
  const _CheckboxVisual({
    required this.value,
    required this.colorVariant,
    required this.disabled,
  });

  final bool value;
  final AuraColorVariant? colorVariant;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final activeColor = _getActiveColor(context);
    final borderColor = disabled ? auraColors.outlineVariant : activeColor;

    return AnimatedContainer(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value ? activeColor : Colors.transparent,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      width: 24,
      height: 24,
      child: value
          ? const AuraIcon(
              Icons.check,
              size: AuraIconSize.extraSmall,
              color: AuraColorVariant.onPrimary,
            )
          : null,
      duration: context.auraTheme.animation.fast,
    );
  }

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
}
