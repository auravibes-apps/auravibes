import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

export 'aura_loading_overlay.dart';

/// A customizable loading spinner component following the Aura design system.
class AuraSpinner extends StatelessWidget {
  /// Creates an Aura spinner.
  const new({
    super.key,
    this.size = AuraSpinnerSize.medium,
    this.tint,
    this.color,
    this.strokeWidth,
    this.semanticLabel,
  });

  /// The size of the spinner.
  final AuraSpinnerSize size;

  /// The tint of the spinner. If null, uses the primary tint.
  final AuraTint? tint;

  /// Legacy explicit color override. Prefer [tint] for theme-aware colors.
  final Color? color;

  /// The width of the spinner stroke. If null, uses a default based on size.
  final double? strokeWidth;

  /// Semantic label announced by assistive technologies.
  ///
  /// Pass localized text when loading state needs an accessibility
  /// announcement.
  /// If omitted, spinner has no semantic label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => _AuraSpinnerContent.fromSpinner(
    spinner: this,
    colors: context.auraColors,
  );

  double _getSpinnerSize() {
    return switch (size) {
      .extraSmall => 12.0,
      .small => 16.0,
      .medium => 24.0,
      .large => 32.0,
      .extraLarge => 48.0,
    };
  }

  double _getDefaultStrokeWidth() {
    return switch (size) {
      .extraSmall => 1.5,
      .small => 2.0,
      .medium => 2.5,
      .large => 3.0,
      .extraLarge => 4.0,
    };
  }
}

class _AuraSpinnerContent extends StatelessWidget {
  const new({required this._size, required this._indicator});

  new fromSpinner({
    required AuraSpinner spinner,
    required AuraColorScheme colors,
  }) : this(
         size: spinner._getSpinnerSize(),
         indicator: CircularProgressIndicator(
           color: spinner.color ?? colors.colorFor(spinner.tint ?? .primary),
           strokeWidth: spinner.strokeWidth ?? spinner._getDefaultStrokeWidth(),
           semanticsLabel: spinner.semanticLabel,
         ),
       );

  final double _size;
  final Widget _indicator;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: _size, height: _size, child: _indicator);
}

/// The size of a [AuraSpinner].
enum AuraSpinnerSize {
  /// Extra small spinner (12px).
  extraSmall,

  /// Small spinner (16px).
  small,

  /// Medium spinner (24px) - default.
  medium,

  /// Large spinner (32px).
  large,

  /// Extra large spinner (48px).
  extraLarge,
}
