import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable divider component following the Aura design system.
///
/// This divider widget provides consistent visual separation between
/// content sections with support for labels and different orientations.
class AuraDivider extends StatelessWidget {
  /// Creates a horizontal Aura divider.
  const AuraDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  }) : orientation = AuraDividerOrientation.horizontal,
       width = null,
       label = null;

  /// Creates a vertical Aura divider.
  const AuraDivider.vertical({
    super.key,
    this.width,
    this.thickness,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  }) : orientation = AuraDividerOrientation.vertical,
       height = null,
       label = null;

  /// Creates a horizontal Aura divider with a label.
  const AuraDivider.withLabel({
    required this.label,
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  }) : orientation = AuraDividerOrientation.horizontal,
       width = null;

  /// The orientation of the divider.
  final AuraDividerOrientation orientation;

  /// The height of a horizontal divider or the width of a vertical divider.
  final double? height;

  /// The width of a vertical divider or the height of a horizontal divider.
  final double? width;

  /// The thickness of the divider line.
  final double? thickness;

  /// The tint of the divider line.
  final AuraTint? color;

  /// The amount of empty space to the leading edge of the divider.
  final double indent;

  /// The amount of empty space to the trailing edge of the divider.
  final double endIndent;

  /// Optional label to display in the center of the divider.
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    final auraTheme = context.auraTheme;
    final color = this.color;
    final dividerColor = color == null
        ? auraTheme.colors.outline
        : auraTheme.colors.colorFor(color);
    final dividerThickness = thickness ?? DesignBorderWidth.thin;

    final label = this.label;
    if (label != null) {
      return Container(
        height: height ?? context.auraTheme.fromSpacing(.xl),
        margin: EdgeInsets.only(
          left: indent,
          right: endIndent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                color: dividerColor,
                height: dividerThickness,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.auraTheme.fromSpacing(.md),
              ),
              child: AuraText(
                child: label,
                style: AuraTextStyle.caption,
              ),
            ),
            Expanded(
              child: Container(
                color: dividerColor,
                height: dividerThickness,
              ),
            ),
          ],
        ),
      );
    }

    if (orientation == AuraDividerOrientation.vertical) {
      return Container(
        width: width ?? context.auraTheme.fromSpacing(.md),
        margin: EdgeInsets.only(
          top: indent,
          bottom: endIndent,
        ),
        child: Center(
          child: Container(
            color: dividerColor,
            width: dividerThickness,
          ),
        ),
      );
    }

    return Container(
      height: height ?? context.auraTheme.fromSpacing(.md),
      margin: EdgeInsets.only(
        left: indent,
        right: endIndent,
      ),
      child: Center(
        child: Container(
          color: dividerColor,
          height: dividerThickness,
        ),
      ),
    );
  }
}

/// The orientation of a [AuraDivider].
enum AuraDividerOrientation {
  /// Horizontal divider.
  horizontal,

  /// Vertical divider.
  vertical,
}
