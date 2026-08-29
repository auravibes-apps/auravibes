import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/molecules/aura_radio_option.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

export 'package:auravibes_ui/src/molecules/aura_radio_option.dart'
    show AuraRadioOption;
export 'aura_radio_list_tile.dart';

/// A container managing mutually exclusive radio selections.
class AuraRadioGroup<T> extends StatelessWidget {
  static const double _kRadioTapTargetSize = 48;

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
    if (options.isEmpty) return const SizedBox.shrink();

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
          DefaultTextStyle.merge(
            style: TextStyle(color: context.auraColors.onSurface),
            child: label,
          ),
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
    final subtitle = option.subtitle;
    final onTap = onChanged == null || option.disabled
        ? null
        : () => onChanged(option.value);
    final labelWidget = DefaultTextStyle.merge(
      style: TextStyle(color: context.auraColors.onSurface),
      child: option.label,
    );
    final row = Row(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        ExcludeSemantics(
          child: AuraRadio<T>(
            value: option.value,
            groupValue: groupValue,
            onChanged: onChanged,
            tint: tint,
            disabled: option.disabled,
            semanticLabel: option.semanticLabel,
          ),
        ),
        const AuraSizedBox(width: .sm),
        if (shrinkWrap) labelWidget else Flexible(child: labelWidget),
      ],
    );

    final interactiveRow = Semantics(
      child: GestureDetector(
        child: row,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
      ),
      excludeSemantics: true,
      enabled: onTap != null,
      checked: option.value == groupValue,
      inMutuallyExclusiveGroup: true,
      label: option.semanticLabel ?? 'Radio button',
      onTap: onTap,
    );

    if (shrinkWrap) return interactiveRow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        interactiveRow,
        if (subtitle != null)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start:
                  AuraRadioGroup._kRadioTapTargetSize +
                  context.auraTheme.fromSpacing(.sm),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: context.auraColors.onSurfaceVariant),
              child: subtitle,
            ),
          ),
      ],
    );
  }
}
