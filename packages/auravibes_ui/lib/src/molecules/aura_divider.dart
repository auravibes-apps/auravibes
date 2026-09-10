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
  const new({
    super.key,
    this.thickness = 1,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  }) : orientation = AuraDividerOrientation.horizontal,
       label = null;

  /// Creates a vertical Aura divider.
  const new vertical({
    super.key,
    this.thickness = 1,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  }) : orientation = AuraDividerOrientation.vertical,
       label = null;

  /// Creates a horizontal Aura divider with a label.
  const new withLabel({
    required this.label,
    super.key,
    this.thickness = 1,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  }) : orientation = AuraDividerOrientation.horizontal;

  /// The orientation of the divider.
  final AuraDividerOrientation orientation;

  /// The thickness of the divider line and its cross-axis area.
  final double thickness;

  /// The tint of the divider line.
  final AuraTint? color;

  /// The amount of empty space to the leading edge of the divider.
  final double indent;

  /// The amount of empty space to the trailing edge of the divider.
  final double endIndent;

  /// Optional label to display in the center of the divider.
  final Widget? label;

  /// Whether [orientation] is vertical.
  static bool isVertical(AuraDividerOrientation orientation) =>
      orientation == AuraDividerOrientation.vertical;

  /// Returns the margin for [orientation] and its indents.
  static EdgeInsetsDirectional marginFor({
    required AuraDividerOrientation orientation,
    required double indent,
    required double endIndent,
  }) => isVertical(orientation)
      ? EdgeInsetsDirectional.only(top: indent, bottom: endIndent)
      : EdgeInsetsDirectional.only(start: indent, end: endIndent);

  @override
  Widget build(BuildContext context) {
    final auraTheme = context.auraTheme;
    final color = this.color;
    return _AuraDividerContent(
      orientation: orientation,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      label: label,
      color: color == null
          ? auraTheme.colors.outline
          : auraTheme.colors.colorFor(color),
    );
  }
}

class const _AuraDividerContent({
  required final AuraDividerOrientation orientation,
  required final double thickness,
  required final double indent,
  required final double endIndent,
  required final Widget? label,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = this.label;
    if (label != null) {
      return _AuraLabeledDivider(
        label: label,
        thickness: thickness,
        indent: indent,
        endIndent: endIndent,
        color: color,
      );
    }

    if (AuraDivider.isVertical(orientation)) {
      return _AuraVerticalDivider(
        thickness: thickness,
        indent: indent,
        endIndent: endIndent,
        color: color,
      );
    }

    return _AuraHorizontalDivider(
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}

class const _AuraLabeledDivider({
  required final Widget label,
  required final double thickness,
  required final double indent,
  required final double endIndent,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    constraints: .new(minHeight: thickness),
    margin: AuraDivider.marginFor(
      orientation: AuraDividerOrientation.horizontal,
      indent: indent,
      endIndent: endIndent,
    ),
    child: _AuraLabeledDividerContent(
      label: label,
      thickness: thickness,
      color: color,
    ),
  );
}

class const _AuraLabeledDividerContent({
  required final Widget label,
  required final double thickness,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _AuraDividerLine(
          color: color,
          thickness: thickness,
          orientation: AuraDividerOrientation.horizontal,
        ),
      ),
      _AuraDividerLabel(label: label),
      Expanded(
        child: _AuraDividerLine(
          color: color,
          thickness: thickness,
          orientation: AuraDividerOrientation.horizontal,
        ),
      ),
    ],
  );
}

class const _AuraDividerLabel({required final Widget label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.auraTheme.fromSpacing(.md),
    ),
    child: AuraText(child: label, style: .caption),
  );
}

class const _AuraHorizontalDivider({
  required final double thickness,
  required final double indent,
  required final double endIndent,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: thickness,
    margin: AuraDivider.marginFor(
      orientation: AuraDividerOrientation.horizontal,
      indent: indent,
      endIndent: endIndent,
    ),
    child: Center(
      child: _AuraDividerLine(
        color: color,
        thickness: thickness,
        orientation: AuraDividerOrientation.horizontal,
      ),
    ),
  );
}

class const _AuraVerticalDivider({
  required final double thickness,
  required final double indent,
  required final double endIndent,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: thickness,
    margin: AuraDivider.marginFor(
      orientation: AuraDividerOrientation.vertical,
      indent: indent,
      endIndent: endIndent,
    ),
    child: Center(
      child: _AuraDividerLine(
        color: color,
        thickness: thickness,
        orientation: AuraDividerOrientation.vertical,
      ),
    ),
  );
}

class const _AuraDividerLine({
  required final Color color,
  required final double thickness,
  required final AuraDividerOrientation orientation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: color,
    height: orientation == AuraDividerOrientation.horizontal ? thickness : null,
    width: orientation == AuraDividerOrientation.vertical ? thickness : null,
  );
}

/// The orientation of a [AuraDivider].
enum AuraDividerOrientation {
  /// Horizontal divider.
  horizontal,

  /// Vertical divider.
  vertical,
}
