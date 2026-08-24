// Required: UI components keep related private widgets together.

import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
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
    this.tint,
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

  /// Tint for all radio buttons in the group.
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final optionsWidget = _AuraRadioOptions<T>(
      value: value,
      onChanged: onChanged,
      options: options,
      direction: direction,
      tint: tint,
    );

    final label = this.label;
    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const AuraSizedBox(height: .sm),
          optionsWidget,
        ],
      );
    }

    return optionsWidget;
  }
}

class _AuraRadioOptions<T> extends StatelessWidget {
  const _AuraRadioOptions({
    required this.value,
    required this.onChanged,
    required this.options,
    required this.direction,
    required this.tint,
  });

  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<AuraRadioOption<T>> options;
  final Axis direction;
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    return switch (direction) {
      Axis.vertical => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < options.length; i++) ...[
            _AuraRadioOption<T>(
              option: options[i],
              groupValue: value,
              onChanged: onChanged,
              tint: tint,
            ),
            if (i < options.length - 1) const AuraSizedBox(height: .sm),
          ],
        ],
      ),
      Axis.horizontal => Wrap(
        spacing: context.auraTheme.fromSpacing(.md),
        runSpacing: context.auraTheme.fromSpacing(.sm),
        children: [
          for (int i = 0; i < options.length; i++)
            _AuraRadioOption<T>(
              option: options[i],
              groupValue: value,
              onChanged: onChanged,
              tint: tint,
              shrinkWrap: true,
            ),
        ],
      ),
    };
  }
}

class _AuraRadioOption<T> extends StatelessWidget {
  const _AuraRadioOption({
    required this.option,
    required this.groupValue,
    required this.onChanged,
    required this.tint,
    this.shrinkWrap = false,
  });

  final AuraRadioOption<T> option;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final AuraTint? tint;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final onTap = onChanged == null || option.disabled
        ? null
        : () => onChanged(option.value);
    final row = Row(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        AuraRadio<T>(
          value: option.value,
          groupValue: groupValue,
          onChanged: onChanged,
          tint: tint,
          disabled: option.disabled,
        ),
        const AuraSizedBox(width: .sm),
        Flexible(child: option.label),
      ],
    );

    if (shrinkWrap) {
      return GestureDetector(
        child: row,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          child: row,
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
        ),
        if (option.subtitle != null)
          Padding(
            padding: EdgeInsets.only(
              left:
                  AuraRadioGroup._kRadioVisualSize +
                  context.auraTheme.fromSpacing(.sm),
            ),
            child: option.subtitle,
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
    this.tint,
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

  /// Tint when selected.
  final AuraTint? tint;

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
                tint: tint,
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
