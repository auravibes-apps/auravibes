import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/organisms/aura_field_wrapper.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable input field component following the Aura design system.
///
/// This input field supports multiple sizes, validation states, and provides
/// consistent styling across the application by using the AuraFieldWrapper.
class AuraInput extends StatefulWidget {
  /// Creates a Aura input field.
  const AuraInput({
    super.key,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.label,
    this.hint,
    this.error,
    this.isRequired = false,
    this.prefixIcon,
    this.suffixIcon,
    this.size = AuraInputSize.medium,
    this.state = AuraInputState.normal,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.focusNode,
    this.semanticLabel,
    this.footer,
  }) : assert(
         controller == null || initialValue == null,
         'Cannot provide both controller and initialValue',
       );

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// The initial value of the input field.
  final String? initialValue;

  /// Placeholder text to display when the input is empty.
  final Widget? placeholder;

  /// Optional label text to display above the field.
  final Widget? label;

  /// Optional hint text to display below the field.
  final Widget? hint;

  /// Optional error text to display below the field.
  final Widget? error;

  /// Whether the field is required.
  final bool isRequired;

  /// Widget to display before the input text.
  final Widget? prefixIcon;

  /// Widget to display after the input text.
  final Widget? suffixIcon;

  /// The size of the input field.
  final AuraInputSize size;

  /// The visual state of the input field.
  final AuraInputState state;

  /// The type of keyboard to use for editing the text.
  final TextInputType? keyboardType;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether the input field is enabled.
  final bool enabled;

  /// Whether the input field is read-only.
  final bool readOnly;

  /// Whether this input field should focus itself if nothing else is already
  /// focused.
  final bool autofocus;

  /// The minimum number of lines to show.
  final int? minLines;

  /// The maximum number of lines to show at one time.
  final int maxLines;

  /// The maximum number of characters allowed in the input.
  final int? maxLength;

  /// Optional input validation and formatting overrides.
  final List<TextInputFormatter>? inputFormatters;

  /// Called when the user changes the text in the field.
  final ValueChanged<String>? onChanged;

  /// Called when the user indicates that they are done editing the text in the
  /// field.
  final ValueChanged<String>? onSubmitted;

  /// Called when the input field is tapped.
  final VoidCallback? onTap;

  /// Called for taps outside this input field's tap region.
  final TapRegionCallback? onTapOutside;

  /// Defines the keyboard focus for this widget.
  final FocusNode? focusNode;

  /// A semantic label for the input field.
  final String? semanticLabel;

  ///
  final Widget? footer;

  @override
  State<AuraInput> createState() => _AuraInputState();
}

class _AuraInputState extends State<AuraInput> {
  FocusNode? _focusNode;
  bool _isFocused = false;

  FocusNode get _requiredFocusNode {
    final focusNode = _focusNode;
    if (focusNode == null) {
      throw StateError('_focusNode is not initialized');
    }

    return focusNode;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    final focusNode = _focusNode;
    if (focusNode != null) {
      focusNode.removeListener(_onFocusChange);
      if (widget.focusNode == null) {
        focusNode.dispose();
      }
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _requiredFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final fieldState = _convertToFieldState(widget.state);
    final prefixIcon = widget.prefixIcon;
    final suffixIcon = widget.suffixIcon;
    final footer = widget.footer;

    return AuraFieldWrapper(
      child: Padding(
        padding: _getPadding(),
        child: Column(
          children: [
            Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon,
                  const AuraSizedBox(width: .sm),
                ],
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    initialValue: widget.initialValue,
                    focusNode: _requiredFocusNode,
                    decoration: InputDecoration(
                      hint: widget.placeholder,
                      hintStyle: _getHintStyle(
                        auraColors,
                        typography: context.auraTheme.typography,
                      ),
                      isDense: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      semanticCounterText: widget.semanticLabel,
                    ),
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    style: _getTextStyle(
                      auraColors,
                      typography: context.auraTheme.typography,
                    ),
                    autofocus: widget.autofocus,
                    readOnly: widget.readOnly,
                    obscureText: widget.obscureText,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    maxLength: widget.maxLength,
                    onChanged: widget.onChanged,
                    onTap: widget.onTap,
                    onTapOutside: widget.onTapOutside,
                    onFieldSubmitted: widget.onSubmitted,
                    inputFormatters: widget.inputFormatters,
                    enabled: widget.enabled,
                  ),
                ),
                if (suffixIcon != null) ...[
                  const AuraSizedBox(width: .sm),
                  suffixIcon,
                ],
              ],
            ),
            ?footer,
          ],
        ),
      ),
      label: widget.label,
      hint: widget.hint,
      error: widget.error,
      isRequired: widget.isRequired,
      state: fieldState,
      isEnabled: widget.enabled,
      isReadOnly: widget.readOnly,
      isFocused: _isFocused,
      semanticLabel: widget.semanticLabel,
    );
  }

  AuraFieldState _convertToFieldState(AuraInputState state) {
    return switch (state) {
      AuraInputState.normal => AuraFieldState.normal,
      AuraInputState.success => AuraFieldState.success,
      AuraInputState.warning => AuraFieldState.warning,
      AuraInputState.error => AuraFieldState.error,
    };
  }

  EdgeInsets _getPadding() {
    return switch (widget.size) {
      AuraInputSize.small => DesignInputSizes.paddingSm,
      AuraInputSize.medium => DesignInputSizes.paddingMd,
      AuraInputSize.large => DesignInputSizes.paddingLg,
    };
  }

  TextStyle _getTextStyle(
    AuraColorScheme colors, {
    required AuraTypographyScale typography,
  }) {
    final fontSize = switch (widget.size) {
      AuraInputSize.small => typography.fontSizeSm,
      AuraInputSize.medium => typography.fontSizeBase,
      AuraInputSize.large => typography.fontSizeLg,
    };

    return TextStyle(
      color: widget.enabled ? colors.onSurface : colors.onSurfaceVariant,
      fontSize: fontSize,
      fontWeight: typography.fontWeightRegular,
      height: typography.lineHeightBase,
      fontFamily: typography.bodyFontFamily,
    );
  }

  TextStyle _getHintStyle(
    AuraColorScheme colors, {
    required AuraTypographyScale typography,
  }) {
    final fontSize = switch (widget.size) {
      AuraInputSize.small => typography.fontSizeSm,
      AuraInputSize.medium => typography.fontSizeBase,
      AuraInputSize.large => typography.fontSizeLg,
    };

    return TextStyle(
      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
      fontSize: fontSize,
      fontWeight: typography.fontWeightRegular,
      height: typography.lineHeightBase,
      fontFamily: typography.bodyFontFamily,
    );
  }
}

/// The size of a [AuraInput].
enum AuraInputSize {
  /// A small input field.
  small,

  /// A medium input field (default).
  medium,

  /// A large input field.
  large,
}

/// The visual state of a [AuraInput].
enum AuraInputState {
  /// Normal state.
  normal,

  /// Success state (green border).
  success,

  /// Warning state (yellow border).
  warning,

  /// Error state (red border).
  error,
}
