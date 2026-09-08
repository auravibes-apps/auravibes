import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/molecules/aura_checkbox.dart';
import 'package:auravibes_ui/src/molecules/aura_radio_option.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

const _choicePickerTapTarget = 48.0;

/// A labeled value that can be selected by [AuraChoicePicker].
class AuraChoiceOption<T> {
  /// Creates a choice option.
  const new({
    required this.value,
    required this.label,
    this.disabled = false,
    this.semanticLabel,
  });

  /// The stable value associated with the option.
  final T value;

  /// The content displayed for the option.
  final Widget label;

  /// Whether the option cannot be selected.
  final bool disabled;

  /// An optional accessibility label for the option.
  final String? semanticLabel;
}

/// Defines how an [AuraChoicePicker] handles selections.
enum AuraChoicePickerVariant {
  /// Allow at most one selected value.
  mutuallyExclusive,

  /// Allow multiple selected values.
  multipleSelection,
}

/// Visual layout, independent of single or multiple selection behavior.
enum AuraChoicePickerPresentation {
  /// Vertically arranged radio or checkbox options.
  list,

  /// Wrapping, keyboard-accessible choice chips.
  chips,
}

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

    final optionWidgets = [
      for (int i = 0; i < options.length; i++) ...[
        _AuraChoicePickerOption<T>(
          option: options[i],
          selectedValues: value,
          variant: variant,
          presentation: presentation,
          maxAllowedSelections: maxAllowedSelections,
          onChanged: effectiveOnChanged,
          tint: tint,
        ),
        if (presentation == AuraChoicePickerPresentation.list &&
            i < options.length - 1)
          const AuraSizedBox(height: .sm),
      ],
    ];
    final Widget choices = presentation == AuraChoicePickerPresentation.chips
        ? Wrap(
            spacing: context.auraTheme.spacing.sm,
            runSpacing: context.auraTheme.spacing.sm,
            children: optionWidgets,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: optionWidgets,
          );

    final label = this.label;
    final semanticLabel = this.semanticLabel;
    final visibleLabel = label != null && semanticLabel != null
        ? ExcludeSemantics(child: label)
        : label;
    var result = visibleLabel == null
        ? choices
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              visibleLabel,
              const AuraSizedBox(height: .sm),
              choices,
            ],
          );

    result = DefaultTextStyle(
      style: DefaultTextStyle.of(context).style
          .copyWith(color: context.auraColors.onSurface),
      child: result,
    );

    if (semanticLabel != null) {
      result = Semantics(
        child: result,
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
      );
    }

    return result;
  }
}

class const _AuraChoicePickerOption<T>({
  required final AuraChoiceOption<T> option,
  required final List<T> selectedValues,
  required final AuraChoicePickerVariant variant,
  required final AuraChoicePickerPresentation presentation,
  required final int? maxAllowedSelections,
  required final ValueChanged<List<T>>? onChanged,
  required final AuraTint? tint,
}) extends StatelessWidget {
  T? get _mutuallyExclusiveValue => selectedValues.firstOrNull;

  bool get _isSelected {
    if (variant == AuraChoicePickerVariant.mutuallyExclusive) {
      return selectedValues.isNotEmpty &&
          _mutuallyExclusiveValue == option.value;
    }

    return selectedValues.contains(option.value);
  }

  bool get _isInteractive {
    if (option.disabled || onChanged == null) return false;
    if (variant != AuraChoicePickerVariant.multipleSelection) return true;
    if (_isSelected) return true;

    final maxAllowedSelections = this.maxAllowedSelections;

    return maxAllowedSelections == null ||
        selectedValues.length < maxAllowedSelections;
  }

  @override
  Widget build(BuildContext context) {
    if (presentation == AuraChoicePickerPresentation.chips) {
      final theme = context.auraTheme;
      final colors = context.auraColors;
      final accent = colors.colorFor(tint ?? AuraTint.primary);

      return MergeSemantics(
        child: Semantics(
          child: AuraPressable(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: _choicePickerTapTarget,
                minHeight: _choicePickerTapTarget,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: theme.spacing.sm,
                  horizontal: theme.spacing.md,
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: ExcludeSemantics(
                    excluding: option.semanticLabel != null,
                    child: Opacity(
                      opacity: _isInteractive ? 1 : 0.6,
                      child: option.label,
                    ),
                  ),
                ),
              ),
            ),
            color: accent,
            decoration: BoxDecoration(
              color: _isSelected ? accent.withValues(alpha: 0.12) : null,
              border: Border.all(color: _isSelected ? accent : colors.outline),
              borderRadius: BorderRadius.circular(
                theme.fromBorderRadius(.full),
              ),
            ),
            onPressed: _isInteractive ? _handleChange : null,
            semanticLabel: option.semanticLabel,
            isButtonSemantics: true,
          ),
          enabled: _isInteractive,
          checked: _isSelected,
          inMutuallyExclusiveGroup:
              variant == AuraChoicePickerVariant.mutuallyExclusive,
        ),
      );
    }
    final label = option.semanticLabel == null
        ? option.label
        : ExcludeSemantics(child: option.label);
    final control = switch (variant) {
      AuraChoicePickerVariant.mutuallyExclusive => AuraRadio<T>(
        value: option.value,
        groupValue: _mutuallyExclusiveValue,
        onChanged: _isInteractive ? (_) => _handleChange() : null,
        tint: tint,
        disabled: option.disabled,
        semanticLabel: option.semanticLabel ?? 'Choice',
      ),
      AuraChoicePickerVariant.multipleSelection => AuraCheckbox(
        value: _isSelected,
        onChanged: _isInteractive ? (_) => _handleChange() : null,
        tint: tint,
        disabled: option.disabled,
        semanticLabel: option.semanticLabel ?? 'Choice',
      ),
    };

    return Semantics(
      child: Row(
        children: [
          GestureDetector(
            child: SizedBox(
              width: _choicePickerTapTarget,
              height: _choicePickerTapTarget,
              child: Center(child: ExcludeSemantics(child: control)),
            ),
            onTap: _isInteractive ? _handleChange : null,
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
          ),
          const AuraSizedBox(width: .sm),
          Expanded(
            child: GestureDetector(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: _choicePickerTapTarget,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Opacity(
                    opacity: _isInteractive ? 1 : 0.6,
                    child: label,
                  ),
                ),
              ),
              onTap: _isInteractive ? _handleChange : null,
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
      enabled: _isInteractive,
      checked: _isSelected,
      inMutuallyExclusiveGroup:
          variant == AuraChoicePickerVariant.mutuallyExclusive,
      label: option.semanticLabel,
      onTap: _isInteractive ? _handleChange : null,
    );
  }

  void _handleChange() {
    if (!_isInteractive) return;

    final nextValues = [...selectedValues];
    if (variant == AuraChoicePickerVariant.mutuallyExclusive) {
      if (_isSelected) return;

      nextValues
        ..clear()
        ..add(option.value);
    } else if (_isSelected) {
      final _ = nextValues.remove(option.value);
    } else {
      nextValues.add(option.value);
    }

    onChanged?.call(nextValues);
  }
}
