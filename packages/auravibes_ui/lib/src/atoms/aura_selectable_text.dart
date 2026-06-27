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
  const AuraSelectableText(
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
    final tint = this.tint;
    final cursorTint = this.cursorTint;
    final baseStyle = auraResolveTextStyle(
      style: style,
      colors: auraColors,
      typography: context.auraTheme.typography,
    );
    // Only override color when tint is provided.
    final textStyle = tint != null
        ? baseStyle.copyWith(color: auraColors.colorFor(tint))
        : baseStyle;

    return SelectableText(
      data,
      style: textStyle,
      textAlign: textAlign,
      showCursor: showCursor,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorTint != null
          ? auraColors.colorFor(cursorTint)
          : auraColors.primary,
      onTap: onTap,
      onSelectionChanged: onSelectionChanged,
    );
  }
}
