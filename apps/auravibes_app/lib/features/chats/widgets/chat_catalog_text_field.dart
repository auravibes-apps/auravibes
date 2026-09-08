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

    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final placeholder = widget.placeholder;
    final helperText = widget.helperText;
    final errorText = widget.errorText;

    return AuraInput(
      controller: _controller,
      placeholder: placeholder.isEmpty ? null : Text(placeholder),
      label: label == null ? null : AuraText(child: Text(label)),
      hint: helperText.isEmpty ? null : Text(helperText),
      error: errorText == null ? null : Text(errorText),
      isRequired: widget.required,
      keyboardType: switch (widget.variant) {
        'number' => TextInputType.number,
        'email' => TextInputType.emailAddress,
        _ => null,
      },
      obscureText: widget.variant == 'password',
      maxLines: widget.variant == 'multiline' ? 4 : 1,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      semanticLabel: label,
    );
  }
}
