import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

typedef _AuraDividerInput = ({
  AuraDividerOrientation orientation,
  double thickness,
  double indent,
  double endIndent,
  Widget? label,
  Color color,
});

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
  Widget build(BuildContext context) =>
      _AuraDividerContent.from(divider: this, colors: context.auraColors);
}

class _AuraDividerContent extends StatelessWidget {
  new({
    required AuraDividerOrientation orientation,
    required double thickness,
    required double indent,
    required double endIndent,
    required Widget? label,
    required Color color,
  }) : _child = _AuraDividerBuilder.build((
         orientation: orientation,
         thickness: thickness,
         indent: indent,
         endIndent: endIndent,
         label: label,
         color: color,
       ));

  new from({required AuraDivider divider, required AuraColorScheme colors})
    : this(
        orientation: divider.orientation,
        thickness: divider.thickness,
        indent: divider.indent,
        endIndent: divider.endIndent,
        label: divider.label,
        color: switch (divider.color) {
          final tint? => colors.colorFor(tint),
          null => colors.outline,
        },
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

abstract final class _AuraDividerBuilder {
  static Widget build(_AuraDividerInput input) {
    final label = input.label;
    if (label != null) return _labeledDivider(input, label);

    return AuraDivider.isVertical(input.orientation)
        ? _verticalDivider(input)
        : _horizontalDivider(input);
  }

  static Widget _labeledDivider(_AuraDividerInput input, Widget label) =>
      _AuraLabeledDivider(
        label: label,
        thickness: input.thickness,
        indent: input.indent,
        endIndent: input.endIndent,
        color: input.color,
      );

  static Widget _verticalDivider(_AuraDividerInput input) =>
      _AuraVerticalDivider(
        thickness: input.thickness,
        indent: input.indent,
        endIndent: input.endIndent,
        color: input.color,
      );

  static Widget _horizontalDivider(_AuraDividerInput input) =>
      _AuraHorizontalDivider(
        thickness: input.thickness,
        indent: input.indent,
        endIndent: input.endIndent,
        color: input.color,
      );
}

class _AuraLabeledDivider extends StatelessWidget {
  new({
    required Widget label,
    required double thickness,
    required double indent,
    required double endIndent,
    required Color color,
  }) : _child = Container(
         constraints: .new(minHeight: thickness),
         margin: AuraDivider.marginFor(
           orientation: .horizontal,
           indent: indent,
           endIndent: endIndent,
         ),
         child: _AuraLabeledDividerContent(
           label: label,
           thickness: thickness,
           color: color,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraLabeledDividerContent extends StatelessWidget {
  new({required Widget label, required double thickness, required Color color})
    : _child = Row(
        children: [
          Expanded(
            child: _AuraDividerLine(
              color: color,
              thickness: thickness,
              orientation: .horizontal,
            ),
          ),
          _AuraDividerLabel(label: label),
          Expanded(
            child: _AuraDividerLine(
              color: color,
              thickness: thickness,
              orientation: .horizontal,
            ),
          ),
        ],
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
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

class _AuraHorizontalDivider extends StatelessWidget {
  new({
    required double thickness,
    required double indent,
    required double endIndent,
    required Color color,
  }) : _child = Container(
         height: thickness,
         margin: AuraDivider.marginFor(
           orientation: .horizontal,
           indent: indent,
           endIndent: endIndent,
         ),
         child: Center(
           child: _AuraDividerLine(
             color: color,
             thickness: thickness,
             orientation: .horizontal,
           ),
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraVerticalDivider extends StatelessWidget {
  new({
    required double thickness,
    required double indent,
    required double endIndent,
    required Color color,
  }) : _child = Container(
         width: thickness,
         margin: AuraDivider.marginFor(
           orientation: .vertical,
           indent: indent,
           endIndent: endIndent,
         ),
         child: Center(
           child: _AuraDividerLine(
             color: color,
             thickness: thickness,
             orientation: .vertical,
           ),
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraDividerLine({
  required final Color color,
  required final double thickness,
  required final AuraDividerOrientation orientation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: color,
    width: orientation == AuraDividerOrientation.vertical ? thickness : null,
    height: orientation == AuraDividerOrientation.horizontal ? thickness : null,
  );
}

/// The orientation of a [AuraDivider].
enum AuraDividerOrientation {
  /// Horizontal divider.
  horizontal,

  /// Vertical divider.
  vertical,
}
