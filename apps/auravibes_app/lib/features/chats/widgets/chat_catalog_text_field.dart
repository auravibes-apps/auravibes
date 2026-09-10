import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';

/// A catalog field whose text stays synchronized with its bound model value.
class ChatCatalogTextField extends StatefulWidget {
  /// Creates a controlled field with caller-resolved labels.
  const new({
    required this.onChanged,
    super.key,
    this.value,
    this.label,
    this.variant,
    this.placeholder = '',
    this.helperText = '',
    this.errorText,
    this.required = false,
    this.maxLength,
  });

  /// Called for user edits, not model updates.
  final ValueChanged<String> onChanged;

  /// Bound text; null clears the field.
  final String? value;

  /// Optional visible and accessible label.
  final String? label;

  /// Supports multiline, number, and password.
  /// Number changes the keyboard only.
  final String? variant;

  /// Hint shown in the empty field.
  final String placeholder;

  /// Supporting copy shown below the field.
  final String helperText;

  /// App-validated or model-provided error copy.
  final String? errorText;

  /// Whether this field must be answered before form submission.
  final bool required;

  /// Maximum number of accepted characters.
  final int? maxLength;

  @override
  State<ChatCatalogTextField> createState() => _ChatCatalogTextFieldState();
}

class _ChatCatalogTextFieldState extends State<ChatCatalogTextField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatCatalogTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value ?? '';
    if (_controller.text == text) return;

    _controller.value = .new(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = _fieldValues(widget);

    return _ChatCatalogTextFieldInput(
      controller: _controller,
      isRequired: widget.required,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      semanticLabel: widget.label,
      values: values,
    );
  }
}

class const _ChatCatalogTextFieldInput({
  required final TextEditingController controller,
  required final bool isRequired,
  required final int? maxLength,
  required final ValueChanged<String> onChanged,
  required final String? semanticLabel,
  required final ({
    bool obscureText,
    TextInputType? keyboardType,
    Widget? label,
    Widget? hint,
    Widget? error,
    int maxLines,
    Widget? placeholder,
  })
  values,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    placeholder: values.placeholder,
    label: values.label,
    hint: values.hint,
    error: values.error,
    isRequired: isRequired,
    keyboardType: values.keyboardType,
    obscureText: values.obscureText,
    maxLines: values.maxLines,
    maxLength: maxLength,
    onChanged: onChanged,
    semanticLabel: semanticLabel,
  );
}

({
  bool obscureText,
  TextInputType? keyboardType,
  Widget? label,
  Widget? hint,
  Widget? error,
  int maxLines,
  Widget? placeholder,
})
_fieldValues(ChatCatalogTextField widget) => (
  placeholder: _optionalFieldText(widget.placeholder),
  label: _fieldLabel(widget.label),
  hint: _optionalFieldText(widget.helperText),
  error: _fieldError(widget.errorText),
  keyboardType: _fieldKeyboardType(widget.variant),
  obscureText: widget.variant == 'password',
  maxLines: widget.variant == 'multiline' ? 4 : 1,
);

Widget? _optionalFieldText(String? value) =>
    value == null || value.isEmpty ? null : Text(value);

Widget? _fieldLabel(String? value) =>
    value == null ? null : AuraText(child: Text(value));

Widget? _fieldError(String? value) => value == null ? null : Text(value);

TextInputType? _fieldKeyboardType(String? variant) => switch (variant) {
  'number' => TextInputType.number,
  'email' => TextInputType.emailAddress,
  _ => null,
};
