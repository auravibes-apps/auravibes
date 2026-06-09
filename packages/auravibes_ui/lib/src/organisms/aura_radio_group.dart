// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// ignore_for_file: avoid-returning-widgets
// Required: Existing helper builders return widgets.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-moving-to-variable
// Required: UI components repeat theme and layout lookups intentionally.
// ignore_for_file: prefer-single-widget-per-file
// Required: UI components keep related private widgets together.

import 'package:auravibes_ui/src/molecules/aura_radio_option.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

export 'package:auravibes_ui/src/molecules/aura_radio_option.dart'
    show AuraRadioOption;

/// A container managing mutually exclusive radio selections.
///
/// Tracks the currently selected value and provides a clean API for
/// single-choice selections. Supports both vertical and horizontal layouts.
///
/// ## Layout Contract
///
/// | direction | Layout |
/// |-----------|--------|
/// | Axis.vertical | Column with spacing.sm between items |
/// | Axis.horizontal | Row with spacing.md between items |
///
/// ## Example
///
/// ```dart
/// AuraRadioGroup<AppTheme>(
///   value: selectedTheme,
///   onChanged: (value) => setState(() => selectedTheme = value),
///   options: [
///     AuraRadioOption(value: AppTheme.system, label: Text('System')),
///     AuraRadioOption(value: AppTheme.light, label: Text('Light')),
///     AuraRadioOption(value: AppTheme.dark, label: Text('Dark')),
///   ],
/// )
/// ```
class AuraRadioGroup<T> extends StatelessWidget {
  /// Creates an AuraRadioGroup widget.
  const AuraRadioGroup({
    required this.value,
    required this.onChanged,
    required this.options,
    super.key,
    this.label,
    this.direction = Axis.vertical,
    this.colorVariant,
  });
  static const double _kRadioVisualSize = 24;

  /// The currently selected value.
  final T? value;

  /// Called when the selection changes.
  final ValueChanged<T?>? onChanged;

  /// The available options.
  final List<AuraRadioOption<T>> options;

  /// Optional label displayed above the options.
  final Widget? label;

  /// Layout direction for the options.
  final Axis direction;

  /// Color variant for all radio buttons in the group.
  final AuraColorVariant? colorVariant;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final spacing = context.auraTheme.spacing;

    final radios = options.map((option) {
      return AuraRadio<T>(
        value: option.value,
        groupValue: value,
        onChanged: onChanged,
        colorVariant: colorVariant,
      );
    }).toList();

    final optionsWidget = direction == Axis.vertical
        ? _buildVerticalOptions(radios, spacing)
        : _buildHorizontalOptions(radios, spacing);

    final label = this.label;
    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          SizedBox(height: spacing.sm),
          optionsWidget,
        ],
      );
    }

    return optionsWidget;
  }

  Widget _buildVerticalOptions(
    List<AuraRadio<T>> radios,
    AuraSpacingTheme spacing,
  ) {
    final onChanged = this.onChanged;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          GestureDetector(
            child: Row(
              children: [
                radios[i],
                SizedBox(width: spacing.sm),
                Flexible(child: options[i].label),
              ],
            ),
            onTap: onChanged == null ? null : () => onChanged(options[i].value),
            behavior: HitTestBehavior.opaque,
          ),
          if (options[i].subtitle != null)
            Padding(
              padding: EdgeInsets.only(
                left: _kRadioVisualSize + spacing.sm,
              ),
              child: options[i].subtitle,
            ),
          if (i < options.length - 1) SizedBox(height: spacing.sm),
        ],
      ],
    );
  }

  Widget _buildHorizontalOptions(
    List<AuraRadio<T>> radios,
    AuraSpacingTheme spacing,
  ) {
    final onChanged = this.onChanged;

    return Wrap(
      spacing: spacing.md,
      runSpacing: spacing.sm,
      children: [
        for (int i = 0; i < options.length; i++)
          GestureDetector(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                radios[i],
                SizedBox(width: spacing.sm),
                Flexible(child: options[i].label),
              ],
            ),
            onTap: onChanged == null ? null : () => onChanged(options[i].value),
            behavior: HitTestBehavior.opaque,
          ),
      ],
    );
  }
}

/// A list tile with an integrated radio button for settings-style selections.
///
/// Provides a full-width tappable tile with a radio indicator, title,
/// and optional subtitle. Ideal for settings screens and preference dialogs.
///
/// ## Layout Contract
///
/// ```text
/// ┌────────────────────────────────────────┐
/// │ ○  [Title]                             │
/// │    [Subtitle]                          │
/// └────────────────────────────────────────┘
/// ```
///
/// - Radio: 24x24, left-aligned
/// - Title: AuraTextStyle.bodyMedium
/// - Subtitle: AuraTextStyle.bodySmall, onSurfaceVariant
///
/// ## Example
///
/// ```dart
/// AuraRadioListTile<String>(
///   value: 'dark',
///   groupValue: selectedTheme,
///   onChanged: (value) => setState(() => selectedTheme = value),
///   title: Text('Dark Theme'),
///   subtitle: Text('Easier on the eyes in low light'),
/// )
/// ```
class AuraRadioListTile<T> extends StatelessWidget {
  /// Creates an AuraRadioListTile widget.
  const AuraRadioListTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    super.key,
    this.subtitle,
    this.colorVariant,
    this.disabled = false,
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

  /// Color variant when selected.
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
          opacity: isDisabled ? 0.6 : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuraRadio<T>(
                value: value,
                groupValue: groupValue,
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
        onTap: isDisabled ? null : () => onChanged?.call(value),
      ),
    );
  }
}
