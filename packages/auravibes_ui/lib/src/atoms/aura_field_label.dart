import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';

/// A customizable field label component following the Aura design system.
///
/// This label provides consistent typography and styling for field titles
/// with optional required field indicators.
class AuraFieldLabel extends StatelessWidget {
  /// Creates a Aura field label.
  const new({
    required this.child,
    super.key,
    this.isRequired = false,
    this.style,
    this.semanticLabel,
    this.requiredLabel = 'required',
  });

  /// The label text to display.
  final Widget child;

  /// Whether the field is required.
  final bool isRequired;

  /// Optional text style to override the default.
  final AuraTextStyle? style;

  /// A semantic label for accessibility.
  final String? semanticLabel;

  /// The semantic label appended to the required-field indicator.
  final String requiredLabel;

  @override
  Widget build(BuildContext context) => _AuraFieldLabelRow.fromValues(
    child: child,
    isRequired: isRequired,
    style: style,
    semanticLabel: semanticLabel,
    requiredLabel: requiredLabel,
  );
}

class const _AuraFieldLabelRow({required final List<Widget> children})
    extends StatelessWidget {
  new fromValues({
    required Widget child,
    required bool isRequired,
    required AuraTextStyle? style,
    required String? semanticLabel,
    required String requiredLabel,
  }) : this(
         children: [
           _AuraFieldLabelText(
             child: child,
             style: style,
             semanticLabel: semanticLabel,
           ),
           if (isRequired) ...[
             const AuraSizedBox(width: .xs),
             _AuraRequiredFieldIndicator(style: style, label: requiredLabel),
           ],
         ],
       );

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: .min, crossAxisAlignment: .start, children: children);
}

class const _AuraFieldLabelText({
  required final Widget child,
  required final AuraTextStyle? style,
  required final String? semanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Flexible(
    child: AuraText(
      child: _AuraFieldLabelSemantics(
        child: child,
        label: semanticLabel,
        fontWeight: context.auraTheme.typography.fontWeightMedium,
      ),
      style: style ?? AuraTextStyle.bodySmall,
    ),
  );
}

class const _AuraFieldLabelSemantics({
  required final Widget child,
  required final String? label,
  required final FontWeight fontWeight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: DefaultTextStyle.merge(
      style: .new(fontWeight: fontWeight),
      child: child,
    ),
    label: label,
  );
}

class const _AuraRequiredFieldIndicator({
  required final AuraTextStyle? style,
  required final String label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      '*',
      style: .new(fontWeight: context.auraTheme.typography.fontWeightMedium),
      semanticsLabel: label,
    ),
    style: style ?? AuraTextStyle.bodySmall,
    tint: .error,
  );
}
