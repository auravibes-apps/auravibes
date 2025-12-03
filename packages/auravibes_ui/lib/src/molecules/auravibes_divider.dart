import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
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

  /// The color of the divider line.
  final Color? color;

  /// The amount of empty space to the leading edge of the divider.
  final double indent;

  /// The amount of empty space to the trailing edge of the divider.
  final double endIndent;

  /// Optional label to display in the center of the divider.
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    final auraTheme = context.auraTheme;
    final dividerColor = color ?? auraTheme.colors.outline;
    final dividerThickness = thickness ?? DesignBorderWidth.thin;

    if (label != null) {
      return _buildLabeledDivider(dividerColor, dividerThickness, auraTheme);
    }

    if (orientation == AuraDividerOrientation.vertical) {
      return _buildVerticalDivider(dividerColor, dividerThickness);
    }

    return _buildHorizontalDivider(dividerColor, dividerThickness);
  }

  Widget _buildHorizontalDivider(Color dividerColor, double dividerThickness) {
    return Container(
      height: height ?? DesignSpacing.md,
      margin: EdgeInsets.only(
        left: indent,
        right: endIndent,
      ),
      child: Center(
        child: Container(
          height: dividerThickness,
          color: dividerColor,
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(Color dividerColor, double dividerThickness) {
    return Container(
      width: width ?? DesignSpacing.md,
      margin: EdgeInsets.only(
        top: indent,
        bottom: endIndent,
      ),
      child: Center(
        child: Container(
          width: dividerThickness,
          color: dividerColor,
        ),
      ),
    );
  }

  Widget _buildLabeledDivider(
    Color dividerColor,
    double dividerThickness,
    AuraTheme auraTheme,
  ) {
    return Container(
      height: height ?? DesignSpacing.xl,
      margin: EdgeInsets.only(
        left: indent,
        right: endIndent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: dividerThickness,
              color: dividerColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpacing.md,
            ),
            child: AuraText(
              style: AuraTextStyle.caption,
              color: AuraColorVariant.onSurfaceVariant,
              child: label!,
            ),
          ),
          Expanded(
            child: Container(
              height: dividerThickness,
              color: dividerColor,
            ),
          ),
        ],
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
