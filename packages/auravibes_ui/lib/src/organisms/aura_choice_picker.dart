import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/molecules/aura_checkbox.dart';
import 'package:auravibes_ui/src/molecules/aura_radio_option.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

part 'aura_choice_option.dart';
part 'aura_choice_picker_variant.dart';
part 'aura_choice_picker_presentation.dart';

const _choicePickerTapTarget = 48.0;
const _disabledOpacity = 0.6;

/// A controlled list of labeled choices supporting single or multiple values.
///
/// The widget does not keep selection state. Callers must update [value] in
/// response to [onChanged]. In [AuraChoicePickerVariant.mutuallyExclusive]
/// mode, callbacks contain exactly one value when invoked. In
/// multiple-selection mode, [maxAllowedSelections] prevents adding values
/// beyond the limit while still allowing selected values to be removed.
class AuraChoicePicker<T> extends StatelessWidget {
  /// Creates an Aura choice picker.
  const new({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
    this.variant = AuraChoicePickerVariant.mutuallyExclusive,
    this.presentation = AuraChoicePickerPresentation.list,
    this.maxAllowedSelections,
    this.label,
    this.semanticLabel,
    this.tint,
  });

  /// The available choices.
  final List<AuraChoiceOption<T>> options;

  /// The currently selected values.
  final List<T> value;

  /// Called with the next selected values after a user change.
  final ValueChanged<List<T>>? onChanged;

  /// Whether one or multiple values may be selected.
  final AuraChoicePickerVariant variant;

  /// Whether choices appear as a list or wrapping chips.
  final AuraChoicePickerPresentation presentation;

  /// The largest number of selected values allowed in multiple-selection
  /// mode.
  final int? maxAllowedSelections;

  /// Optional content displayed above the choices.
  final Widget? label;

  /// An optional accessibility label for the choice group.
  final String? semanticLabel;

  /// Tint used by the selection controls.
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final effectiveOnChanged =
        AuraInteractionScope.of(context).allowsValueChanges ? onChanged : null;

    return _AuraChoicePickerSurface<T>(
      picker: this,
      onChanged: effectiveOnChanged,
    );
  }
}

class const _AuraChoicePickerSurface<T>({
  required final AuraChoicePicker<T> picker,
  required final ValueChanged<List<T>>? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: DefaultTextStyle.of(context).style
        .copyWith(color: context.auraColors.onSurface),
    child: _AuraChoicePickerSemantics<T>(picker: picker, onChanged: onChanged),
  );
}

class const _AuraChoicePickerSemantics<T>({
  required final AuraChoicePicker<T> picker,
  required final ValueChanged<List<T>>? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final semanticLabel = picker.semanticLabel;
    final content = _AuraChoicePickerLabeledContent<T>(
      picker: picker,
      onChanged: onChanged,
    );
    if (semanticLabel == null) return content;

    return Semantics(
      child: content,
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
    );
  }
}

class const _AuraChoicePickerLabeledContent<T>({
  required final AuraChoicePicker<T> picker,
  required final ValueChanged<List<T>>? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = picker.label;
    final choices = _AuraChoicePickerChoices<T>(
      picker: picker,
      onChanged: onChanged,
    );
    if (label == null) return choices;

    return _AuraChoicePickerLabeledColumn(
      label: label,
      excludeSemantics: picker.semanticLabel != null,
      choices: choices,
    );
  }
}

class const _AuraChoicePickerLabeledColumn({
  required final Widget label,
  required final bool excludeSemantics,
  required final Widget choices,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      ExcludeSemantics(excluding: excludeSemantics, child: label),
      const AuraSizedBox(height: .sm),
      choices,
    ],
  );
}

class const _AuraChoicePickerChoices<T>({
  required final AuraChoicePicker<T> picker,
  required final ValueChanged<List<T>>? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (picker.presentation) {
    .chips => _AuraChoicePickerChipOptions<T>(
      picker: picker,
      onChanged: onChanged,
    ),
    .list => _AuraChoicePickerListOptions<T>(
      picker: picker,
      onChanged: onChanged,
    ),
  };
}

class const _AuraChoicePickerChipOptions<T>({
  required final AuraChoicePicker<T> picker,
  required final ValueChanged<List<T>>? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.auraTheme.spacing.sm,
    runSpacing: context.auraTheme.spacing.sm,
    children: [
      for (final option in picker.options)
        _AuraChoicePickerOption<T>(
          picker: picker,
          option: option,
          onChanged: onChanged,
        ),
    ],
  );
}

class const _AuraChoicePickerListOptions<T>({
  required final AuraChoicePicker<T> picker,
  required final ValueChanged<List<T>>? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AuraChoicePickerListColumn<T>(picker: picker, onChanged: onChanged);
}

class _AuraChoicePickerListColumn<T> extends StatelessWidget {
  new({required this.picker, required this.onChanged})
    : _children = [
        for (final (index, option) in picker.options.indexed) ...[
          _AuraChoicePickerOption<T>(
            picker: picker,
            option: option,
            onChanged: onChanged,
          ),
          if (index < picker.options.length - 1)
            const AuraSizedBox(height: .sm),
        ],
      ];

  final AuraChoicePicker<T> picker;
  final ValueChanged<List<T>>? onChanged;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: .start, children: _children);
}

class const _AuraChoicePickerOption<T>({
  required final AuraChoicePicker<T> picker,
  required final AuraChoiceOption<T> option,
  required final ValueChanged<List<T>>? onChanged,
}) extends StatelessWidget {
  T? get _mutuallyExclusiveValue => picker.value.firstOrNull;

  bool get _isSelected {
    if (picker.variant == AuraChoicePickerVariant.mutuallyExclusive) {
      return picker.value.isNotEmpty && _mutuallyExclusiveValue == option.value;
    }

    return picker.value.contains(option.value);
  }

  bool get _isInteractive {
    if (option.disabled || onChanged == null) return false;
    if (picker.variant != AuraChoicePickerVariant.multipleSelection) {
      return true;
    }
    if (_isSelected) return true;

    final maxAllowedSelections = picker.maxAllowedSelections;

    return maxAllowedSelections == null ||
        picker.value.length < maxAllowedSelections;
  }

  @override
  Widget build(BuildContext context) {
    return switch (picker.presentation) {
      .chips => _AuraChoicePickerChip<T>(source: this),
      .list => _AuraChoicePickerListOption<T>(source: this),
    };
  }

  void _handleChange() {
    if (!_isInteractive) return;

    final nextValues = _nextChoiceValues();
    if (nextValues == null) return;

    onChanged?.call(nextValues);
  }

  List<T>? _nextChoiceValues() {
    if (picker.variant == AuraChoicePickerVariant.mutuallyExclusive) {
      return _isSelected ? null : [option.value];
    }

    final nextValues = [...picker.value];
    if (_isSelected) {
      final _ = nextValues.remove(option.value);
    } else {
      nextValues.add(option.value);
    }

    return nextValues;
  }
}

class const _AuraChoicePickerChip<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        child: _AuraChoicePickerChipPressable<T>(source: source),
        enabled: source._isInteractive,
        checked: source._isSelected,
        inMutuallyExclusiveGroup:
            source.picker.variant == AuraChoicePickerVariant.mutuallyExclusive,
      ),
    );
  }
}

class const _AuraChoicePickerChipPressable<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPressable(
      child: _AuraChoicePickerChipContent<T>(source: source),
      color: _chipAccent(context, source),
      decoration: _chipDecoration(context, source),
      onPressed: source._isInteractive ? source._handleChange : null,
      semanticLabel: source.option.semanticLabel,
      isButtonSemantics: true,
    );
  }
}

Color _chipAccent<T>(BuildContext context, _AuraChoicePickerOption<T> source) =>
    context.auraColors.colorFor(source.picker.tint ?? AuraTint.primary);

BoxDecoration _chipDecoration<T>(
  BuildContext context,
  _AuraChoicePickerOption<T> source,
) {
  final theme = context.auraTheme;
  final accent = _chipAccent(context, source);
  final isSelected = source._isSelected;
  final outline = context.auraColors.outline;

  return _chipDecorationValues((
    theme: theme,
    accent: accent,
    outline: outline,
    isSelected: isSelected,
  ));
}

typedef _ChipDecorationRequest = ({
  AuraTheme theme,
  Color accent,
  Color outline,
  bool isSelected,
});

BoxDecoration _chipDecorationValues(_ChipDecorationRequest request) {
  return BoxDecoration(
    color: request.isSelected ? request.accent.withValues(alpha: 0.12) : null,
    border: Border.all(
      color: request.isSelected ? request.accent : request.outline,
    ),
    borderRadius: BorderRadius.circular(request.theme.fromBorderRadius(.full)),
  );
}

typedef _ChoiceRadioData<T> = ({
  T value,
  T? groupValue,
  ValueChanged<T?>? onChanged,
  AuraTint? tint,
  bool disabled,
  String semanticLabel,
});

_ChoiceRadioData<T> _choiceRadioData<T>(_AuraChoicePickerOption<T> source) => (
  value: source.option.value,
  groupValue: source._mutuallyExclusiveValue,
  onChanged: source._isInteractive ? (_) => source._handleChange() : null,
  tint: source.picker.tint,
  disabled: source.option.disabled,
  semanticLabel: source.option.semanticLabel ?? 'Choice',
);

class const _AuraChoicePickerChipContent<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AuraChoicePickerChipPadding<T>(context.auraTheme, source);
}

class _AuraChoicePickerChipPadding<T> extends StatelessWidget {
  new(AuraTheme theme, _AuraChoicePickerOption<T> source)
    : _child = ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _choicePickerTapTarget,
          minHeight: _choicePickerTapTarget,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: theme.spacing.sm,
            horizontal: theme.spacing.md,
          ),
          child: _AuraChoicePickerChipLabel<T>(source: source),
        ),
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraChoicePickerChipLabel<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: ExcludeSemantics(
      excluding: source.option.semanticLabel != null,
      child: Opacity(
        opacity: source._isInteractive ? 1 : _disabledOpacity,
        child: source.option.label,
      ),
    ),
  );
}

class const _AuraChoicePickerListOption<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AuraChoicePickerListSemantics<T>(data: _listOptionSemanticsData(source));
}

typedef _ListOptionSemanticsData<T> = ({
  _AuraChoicePickerOption<T> source,
  bool enabled,
  bool checked,
  bool inMutuallyExclusiveGroup,
  String? label,
  VoidCallback? onTap,
});

_ListOptionSemanticsData<T> _listOptionSemanticsData<T>(
  _AuraChoicePickerOption<T> source,
) => (
  source: source,
  enabled: source._isInteractive,
  checked: source._isSelected,
  inMutuallyExclusiveGroup:
      source.picker.variant == AuraChoicePickerVariant.mutuallyExclusive,
  label: source.option.semanticLabel,
  onTap: source._isInteractive ? source._handleChange : null,
);

class const _AuraChoicePickerListSemantics<T>({
  required final _ListOptionSemanticsData<T> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _AuraChoicePickerListRow<T>(source: data.source),
    enabled: data.enabled,
    checked: data.checked,
    inMutuallyExclusiveGroup: data.inMutuallyExclusiveGroup,
    label: data.label,
    onTap: data.onTap,
  );
}

class const _AuraChoicePickerListRow<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AuraChoicePickerListControl<T>(source: source),
        const AuraSizedBox(width: .sm),
        Expanded(child: _AuraChoicePickerListLabel<T>(source: source)),
      ],
    );
  }
}

class const _AuraChoicePickerListControl<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _AuraChoicePickerControlTarget<T>(source: source),
    onTap: source._isInteractive ? source._handleChange : null,
    behavior: .opaque,
    excludeFromSemantics: true,
  );
}

class const _AuraChoicePickerControlTarget<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: _choicePickerTapTarget,
    height: _choicePickerTapTarget,
    child: Center(
      child: ExcludeSemantics(
        child: _AuraChoicePickerControl<T>(source: source),
      ),
    ),
  );
}

class const _AuraChoicePickerControl<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (source.picker.variant) {
    .mutuallyExclusive => _AuraChoicePickerRadio<T>(source: source),
    .multipleSelection => _AuraChoicePickerCheckbox<T>(source: source),
  };
}

class const _AuraChoicePickerRadio<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = _choiceRadioData(source);

    return AuraRadio<T>(
      value: data.value,
      groupValue: data.groupValue,
      onChanged: data.onChanged,
      tint: data.tint,
      disabled: data.disabled,
      semanticLabel: data.semanticLabel,
    );
  }
}

class const _AuraChoicePickerCheckbox<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckbox(
    value: source._isSelected,
    onChanged: source._isInteractive ? (_) => source._handleChange() : null,
    tint: source.picker.tint,
    disabled: source.option.disabled,
    semanticLabel: source.option.semanticLabel ?? 'Choice',
  );
}

class const _AuraChoicePickerListLabel<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: _AuraChoicePickerListLabelContent<T>(source: source),
      onTap: source._isInteractive ? source._handleChange : null,
      behavior: .opaque,
      excludeFromSemantics: true,
    );
  }
}

class const _AuraChoicePickerListLabelContent<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _choicePickerTapTarget),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Opacity(
          opacity: source._isInteractive ? 1 : _disabledOpacity,
          child: _AuraChoicePickerListLabelText<T>(source: source),
        ),
      ),
    );
  }
}

class const _AuraChoicePickerListLabelText<T>({
  required final _AuraChoicePickerOption<T> source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (source.option.semanticLabel == null) return source.option.label;

    return ExcludeSemantics(child: source.option.label);
  }
}
