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
  const new({
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

    return _AuraRadioGroupContent<T>(
      value: value,
      onChanged: onChanged,
      options: options,
      direction: direction,
      tint: tint,
      label: label,
    );
  }
}

class const _AuraRadioGroupContent<T>({
  required final T? value,
  required final ValueChanged<T?>? onChanged,
  required final List<AuraRadioOption<T>> options,
  required final Axis direction,
  required final AuraTint? tint,
  required final Widget? label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraRadioGroupContentData<T>(
    value: value,
    onChanged: onChanged,
    options: options,
    direction: direction,
    tint: tint,
    label: label,
    color: context.auraColors.onSurface,
  ).child;
}

class _AuraRadioGroupContentData<T> extends StatelessWidget {
  new({
    required this.value,
    required this.onChanged,
    required this.options,
    required this.direction,
    required this.tint,
    required this.label,
    required Color color,
  }) : child = label == null
           ? _AuraRadioOptions<T>(
               value: value,
               onChanged: onChanged,
               options: options,
               direction: direction,
               tint: tint,
             )
           : Column(
               crossAxisAlignment: .start,
               children: [
                 DefaultTextStyle.merge(
                   style: .new(color: color),
                   child: label,
                 ),
                 const AuraSizedBox(height: .sm),
                 _AuraRadioOptions<T>(
                   value: value,
                   onChanged: onChanged,
                   options: options,
                   direction: direction,
                   tint: tint,
                 ),
               ],
             );

  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<AuraRadioOption<T>> options;
  final Axis direction;
  final AuraTint? tint;
  final Widget? label;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _AuraRadioOptions<T> extends StatelessWidget {
  const new({
    required this._value,
    required this._onChanged,
    required this._options,
    required this._direction,
    required this._tint,
  });

  final T? _value;
  final ValueChanged<T?>? _onChanged;
  final List<AuraRadioOption<T>> _options;
  final AuraTint? _tint;
  final Axis _direction;

  @override
  Widget build(BuildContext context) => _AuraRadioOptionsData<T>(
    value: _value,
    onChanged: _onChanged,
    options: _options,
    direction: _direction,
    tint: _tint,
    spacing: context.auraTheme.spacing,
  ).child;
}

class _AuraRadioOptionsData<T> {
  new({
    required T? value,
    required ValueChanged<T?>? onChanged,
    required List<AuraRadioOption<T>> options,
    required Axis direction,
    required AuraTint? tint,
    required AuraSpacingScale spacing,
  }) : child = switch (direction) {
         .vertical => _AuraRadioVerticalOptions<T>(
           value: value,
           onChanged: onChanged,
           options: options,
           tint: tint,
         ),
         .horizontal => _AuraRadioHorizontalOptions<T>(
           value: value,
           onChanged: onChanged,
           options: options,
           tint: tint,
           spacing: spacing,
         ),
       };

  final Widget child;
}

class _AuraRadioVerticalOptions<T> extends StatelessWidget {
  new({
    required T? value,
    required ValueChanged<T?>? onChanged,
    required List<AuraRadioOption<T>> options,
    required AuraTint? tint,
  }) : _child = Column(
         crossAxisAlignment: .start,
         children: _AuraRadioVerticalOptionsData<T>(
           value: value,
           onChanged: onChanged,
           options: options,
           tint: tint,
         ).children,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraRadioVerticalOptionsData<T> {
  new({
    required T? value,
    required ValueChanged<T?>? onChanged,
    required List<AuraRadioOption<T>> options,
    required AuraTint? tint,
  }) : children = [
         for (int i = 0; i < options.length; i++) ...[
           _AuraRadioOption<T>(
             option: options[i],
             groupValue: value,
             onChanged: onChanged,
             tint: tint,
           ),
           if (i < options.length - 1) const AuraSizedBox(height: .sm),
         ],
       ];

  final List<Widget> children;
}

class _AuraRadioHorizontalOptions<T> extends StatelessWidget {
  new({
    required T? value,
    required ValueChanged<T?>? onChanged,
    required List<AuraRadioOption<T>> options,
    required AuraTint? tint,
    required AuraSpacingScale spacing,
  }) : _child = Wrap(
         spacing: spacing.md,
         runSpacing: spacing.sm,
         children: [
           for (final option in options)
             _AuraRadioOption<T>(
               option: option,
               groupValue: value,
               onChanged: onChanged,
               tint: tint,
               shrinkWrap: true,
             ),
         ],
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraRadioOption<T>({
  required final AuraRadioOption<T> option,
  required final T? groupValue,
  required final ValueChanged<T?>? onChanged,
  required final AuraTint? tint,
  final bool shrinkWrap = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraRadioOptionLayout<T>(
    option: option,
    groupValue: groupValue,
    onChanged: onChanged,
    tint: tint,
    shrinkWrap: shrinkWrap,
  );
}

class _AuraRadioOptionLayout<T> extends StatelessWidget {
  new({
    required AuraRadioOption<T> option,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    required AuraTint? tint,
    required bool shrinkWrap,
  }) : _child = shrinkWrap
           ? _AuraRadioOptionInteractive<T>(
               option: option,
               groupValue: groupValue,
               onChanged: onChanged,
               tint: tint,
               shrinkWrap: shrinkWrap,
             )
           : Column(
               crossAxisAlignment: .start,
               children: [
                 _AuraRadioOptionInteractive<T>(
                   option: option,
                   groupValue: groupValue,
                   onChanged: onChanged,
                   tint: tint,
                   shrinkWrap: shrinkWrap,
                 ),
                 if (option.subtitle case final subtitle?)
                   _AuraRadioOptionSubtitle(child: subtitle),
               ],
             );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraRadioOptionInteractive<T>({
  required final AuraRadioOption<T> option,
  required final T? groupValue,
  required final ValueChanged<T?>? onChanged,
  required final AuraTint? tint,
  required final bool shrinkWrap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraRadioOptionSemantics<T>(
    data: _AuraRadioOptionInteractiveData<T>(
      option: option,
      groupValue: groupValue,
      onChanged: onChanged,
      tint: tint,
      shrinkWrap: shrinkWrap,
    ),
  );
}

class const _AuraRadioOptionInteractiveData<T>({
  required final AuraRadioOption<T> option,
  required final T? groupValue,
  required final ValueChanged<T?>? onChanged,
  required final AuraTint? tint,
  required final bool shrinkWrap,
}) {
  VoidCallback? onTap() {
    final callback = onChanged;
    if (option.disabled || callback == null) return null;

    return () => callback(option.value);
  }
}

class _AuraRadioOptionSemantics<T> extends StatelessWidget {
  new({required _AuraRadioOptionInteractiveData<T> data})
    : _child = Semantics(
        child: _AuraRadioOptionGesture<T>(data: data),
        excludeSemantics: true,
        enabled: data.onTap() != null,
        checked: data.option.value == data.groupValue,
        inMutuallyExclusiveGroup: true,
        label: data.option.semanticLabel ?? 'Radio button',
        onTap: data.onTap(),
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraRadioOptionGesture<T>({
  required final _AuraRadioOptionInteractiveData<T> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _AuraRadioOptionRow<T>(
      option: data.option,
      groupValue: data.groupValue,
      onChanged: data.onChanged,
      tint: data.tint,
      shrinkWrap: data.shrinkWrap,
    ),
    onTap: data.onTap(),
    behavior: .opaque,
    excludeFromSemantics: true,
  );
}

class _AuraRadioOptionRow<T> extends StatelessWidget {
  new({
    required AuraRadioOption<T> option,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    required AuraTint? tint,
    required bool shrinkWrap,
  }) : _child = Row(
         mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
         children: [
           _AuraRadioOptionControl<T>(
             option: option,
             groupValue: groupValue,
             onChanged: onChanged,
             tint: tint,
           ),
           const AuraSizedBox(width: .sm),
           _AuraRadioOptionLabel(option: option, shrinkWrap: shrinkWrap),
         ],
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraRadioOptionControl<T>({
  required final AuraRadioOption<T> option,
  required final T? groupValue,
  required final ValueChanged<T?>? onChanged,
  required final AuraTint? tint,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AuraRadio<T>(
      value: option.value,
      groupValue: groupValue,
      onChanged: onChanged,
      tint: tint,
      disabled: option.disabled,
      semanticLabel: option.semanticLabel,
    ),
  );
}

class const _AuraRadioOptionLabel({
  required final AuraRadioOption<dynamic> option,
  required final bool shrinkWrap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = DefaultTextStyle.merge(
      style: .new(color: context.auraColors.onSurface),
      child: option.label,
    );

    return shrinkWrap ? label : Flexible(child: label);
  }
}

class const _AuraRadioOptionSubtitle({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(
      start:
          AuraRadioGroup._kRadioTapTargetSize +
          context.auraTheme.fromSpacing(.sm),
    ),
    child: DefaultTextStyle.merge(
      style: .new(color: context.auraColors.onSurfaceVariant),
      child: child,
    ),
  );
}
