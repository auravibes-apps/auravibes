part of 'aura_choice_picker.dart';

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
