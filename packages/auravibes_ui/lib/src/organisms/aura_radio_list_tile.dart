import 'package:auravibes_ui/src/molecules/aura_radio_option.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A list tile with an integrated radio button for settings-style selections.
class AuraRadioListTile<T> extends StatelessWidget {
  /// Creates an AuraRadioListTile widget.
  const new({
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

  bool get _isDisabled => disabled || onChanged == null;

  @override
  Widget build(BuildContext context) => _AuraRadioListTileSemantics<T>(
    value: value,
    groupValue: groupValue,
    onChanged: onChanged,
    title: title,
    subtitle: subtitle,
    tint: tint,
    disabled: _isDisabled,
    semanticLabel: semanticLabel,
  );
}

class const _AuraRadioListTileSemantics<T>({
  required final T value,
  required final T? groupValue,
  required final ValueChanged<T?>? onChanged,
  required final Widget title,
  required final Widget? subtitle,
  required final AuraTint? tint,
  required final bool disabled,
  required final String? semanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraRadioListTileSemanticsData<T>(
    value: value,
    groupValue: groupValue,
    onChanged: onChanged,
    title: title,
    subtitle: subtitle,
    tint: tint,
    disabled: disabled,
    semanticLabel: semanticLabel,
  ).child;
}

class _AuraRadioListTileSemanticsData<T> {
  new({
    required T value,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    required Widget title,
    required Widget? subtitle,
    required AuraTint? tint,
    required bool disabled,
    required String? semanticLabel,
  }) : child = Semantics(
         child: _AuraRadioListTileInteraction<T>(
           value: value,
           groupValue: groupValue,
           onChanged: onChanged,
           title: title,
           subtitle: subtitle,
           tint: tint,
           disabled: disabled,
           onTap: _radioListTileOnTap(disabled, onChanged, value),
         ),
         container: true,
         excludeSemantics: true,
         enabled: !disabled,
         checked: value == groupValue,
         inMutuallyExclusiveGroup: true,
         label: semanticLabel ?? 'Radio button',
         onTap: _radioListTileOnTap(disabled, onChanged, value),
       );

  final Widget child;
}

VoidCallback? _radioListTileOnTap<T>(
  bool disabled,
  ValueChanged<T?>? onChanged,
  T value,
) => disabled ? null : () => onChanged?.call(value);

class const _AuraRadioListTileInteraction<T>({
  required final T value,
  required final T? groupValue,
  required final ValueChanged<T?>? onChanged,
  required final Widget title,
  required final Widget? subtitle,
  required final AuraTint? tint,
  required final bool disabled,
  required final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraRadioListTileInteractionData<T>(
    value: value,
    groupValue: groupValue,
    onChanged: onChanged,
    title: title,
    subtitle: subtitle,
    tint: tint,
    disabled: disabled,
    onTap: onTap,
  ).child;
}

class _AuraRadioListTileInteractionData<T> {
  new({
    required T value,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    required Widget title,
    required Widget? subtitle,
    required AuraTint? tint,
    required bool disabled,
    required VoidCallback? onTap,
  }) : child = MouseRegion(
         cursor: disabled
             ? SystemMouseCursors.forbidden
             : SystemMouseCursors.click,
         child: GestureDetector(
           child: Opacity(
             opacity: disabled ? 0.6 : 1.0,
             child: _AuraRadioListTileContent<T>(
               value: value,
               groupValue: groupValue,
               onChanged: disabled ? null : onChanged,
               title: title,
               subtitle: subtitle,
               tint: tint,
             ),
           ),
           onTap: onTap,
           behavior: .opaque,
           excludeFromSemantics: true,
         ),
       );

  final Widget child;
}

class const _AuraRadioListTileContent<T>({
  required final T value,
  required final T? groupValue,
  required final ValueChanged<T?>? onChanged,
  required final Widget title,
  required final Widget? subtitle,
  required final AuraTint? tint,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraRadioListTileContentData<T>(
    value: value,
    groupValue: groupValue,
    onChanged: onChanged,
    title: title,
    subtitle: subtitle,
    tint: tint,
  ).child;
}

class _AuraRadioListTileContentData<T> {
  new({
    required T value,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    required Widget title,
    required Widget? subtitle,
    required AuraTint? tint,
  }) : child = Row(
         crossAxisAlignment: .start,
         children: [
           ExcludeSemantics(
             child: AuraRadio<T>(
               value: value,
               groupValue: groupValue,
               onChanged: onChanged,
               tint: tint,
               disabled: onChanged == null,
             ),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: _AuraRadioListTileText(title: title, subtitle: subtitle),
           ),
         ],
       );

  final Widget child;
}

class const _AuraRadioListTileText({
  required final Widget title,
  required final Widget? subtitle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraRadioListTileTextData(
    title: title,
    subtitle: subtitle,
    context: context,
  ).child;
}

class _AuraRadioListTileTextData {
  new({
    required Widget title,
    required Widget? subtitle,
    required BuildContext context,
  }) : child = Column(
         mainAxisSize: .min,
         crossAxisAlignment: .start,
         children: [
           DefaultTextStyle(
             style:
                 Theme.of(context).textTheme.bodyMedium ??
                 const TextStyle(fontSize: 16),
             child: title,
           ),
           if (subtitle != null) _AuraRadioListTileSubtitle(child: subtitle),
         ],
       );

  final Widget child;
}

class const _AuraRadioListTileSubtitle({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AuraRadioListTileSubtitleData(child: child, context: context).child;
}

class _AuraRadioListTileSubtitleData {
  new({required Widget child, required BuildContext context})
    : child = Padding(
        padding: const EdgeInsets.only(top: 4),
        child: DefaultTextStyle(
          style:
              Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.auraColors.onSurfaceVariant) ??
              TextStyle(
                color: context.auraColors.onSurfaceVariant,
                fontSize: 14,
              ),
          child: child,
        ),
      );

  final Widget child;
}
