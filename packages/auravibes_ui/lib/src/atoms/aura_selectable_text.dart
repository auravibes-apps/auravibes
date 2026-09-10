import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A selectable text widget that follows the Aura design system.
///
/// This widget allows users to select and copy text while maintaining
/// consistent typography styling from the Aura design system.
///
/// Example:
/// ```dart
/// AuraSelectableText(
///   'Copy this text',
///   style: AuraTextStyle.body,
/// )
/// ```
class AuraSelectableText extends StatelessWidget {
  /// Creates an Aura selectable text widget.
  const new(
    this.data, {
    super.key,
    this.style = AuraTextStyle.body,
    this.tint,
    this.textAlign,
    this.maxLines,
    this.onTap,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorTint,
    this.onSelectionChanged,
    this.showCursor = false,
    this.autofocus = false,
    this.minLines,
  });

  /// The text to display.
  final String data;

  /// The style variant to apply to the text.
  final AuraTextStyle style;

  /// The tint for the text.
  final AuraTint? tint;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The maximum number of lines for the text to span.
  final int? maxLines;

  /// Called when the user taps on the text.
  final GestureTapCallback? onTap;

  /// How thick the cursor will be.
  final double cursorWidth;

  /// How tall the cursor will be.
  final double? cursorHeight;

  /// How rounded the cursor is.
  final Radius? cursorRadius;

  /// The tint for the cursor.
  final AuraTint? cursorTint;

  /// Called when the user changes the selection.
  final SelectionChangedCallback? onSelectionChanged;

  /// Whether to show cursor.
  final bool showCursor;

  /// Whether this text field should focus itself.
  final bool autofocus;

  /// The minimum number of lines to occupy when the content spans fewer lines.
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return _AuraSelectableTextContent(
      _AuraSelectableTextConfiguration(
        text: this,
        context: context,
        colors: auraColors,
      ),
    );
  }

  Color _cursorColor(AuraColorScheme colors) {
    final tint = cursorTint;
    if (tint == null) return colors.primary;

    return colors.colorFor(tint);
  }

  TextStyle _textStyle(BuildContext context, AuraColorScheme colors) {
    final baseStyle = AuraTextStyles.resolve(
      style: style,
      colors: colors,
      typography: context.auraTheme.typography,
    );

    // Only override color when tint is provided.
    final tint = this.tint;

    return _applyTint(baseStyle, tint, colors);
  }
}

class _AuraSelectableTextConfiguration {
  _AuraSelectableTextConfiguration({
    required AuraSelectableText text,
    required BuildContext context,
    required AuraColorScheme colors,
  }) : data = text.data,
       style = text._textStyle(context, colors),
       textAlign = text.textAlign,
       showCursor = text.showCursor,
       autofocus = text.autofocus,
       minLines = text.minLines,
       maxLines = text.maxLines,
       cursorWidth = text.cursorWidth,
       cursorHeight = text.cursorHeight,
       cursorRadius = text.cursorRadius,
       cursorColor = text._cursorColor(colors),
       onTap = text.onTap,
       onSelectionChanged = text.onSelectionChanged;

  final String data;
  final TextStyle style;
  final TextAlign? textAlign;
  final bool showCursor;
  final bool autofocus;
  final int? minLines;
  final int? maxLines;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color cursorColor;
  final GestureTapCallback? onTap;
  final SelectionChangedCallback? onSelectionChanged;
}

TextStyle _applyTint(
  TextStyle baseStyle,
  AuraTint? tint,
  AuraColorScheme colors,
) =>
    tint == null ? baseStyle : baseStyle.copyWith(color: colors.colorFor(tint));

class const _AuraSelectableTextContent(
  final _AuraSelectableTextConfiguration configuration,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AuraSelectableTextWidget(configuration);
}

class _AuraSelectableTextWidget extends StatelessWidget {
  new(_AuraSelectableTextConfiguration configuration)
    : _selectableText = SelectableText(
        configuration.data,
        style: configuration.style,
        textAlign: configuration.textAlign,
        showCursor: configuration.showCursor,
        autofocus: configuration.autofocus,
        minLines: configuration.minLines,
        maxLines: configuration.maxLines,
        cursorWidth: configuration.cursorWidth,
        cursorHeight: configuration.cursorHeight,
        cursorRadius: configuration.cursorRadius,
        cursorColor: configuration.cursorColor,
        onTap: configuration.onTap,
        onSelectionChanged: configuration.onSelectionChanged,
      );

  final SelectableText _selectableText;

  @override
  Widget build(BuildContext context) => _selectableText;
}
