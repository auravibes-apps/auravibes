import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraBorderRadius, AuraTint;
import 'package:flutter/widgets.dart';

typedef _AuraLinearProgressConfiguration = ({
  double height,
  double borderRadius,
  num? value,
  Color backgroundColor,
  num backgroundAlpha,
  Color fillColor,
});

/// A linear progress indicator following the Aura design system.
class AuraLinearProgressIndicator extends StatelessWidget {
  /// Creates an Aura linear progress indicator.
  const new({
    this.value,
    super.key,
    this.height = 4,
    this.tint = AuraTint.primary,
    this.backgroundAlpha = 1,
    this.borderRadius = AuraBorderRadius.full,
    this.semanticLabel,
    this.semanticValue,
  });

  /// Current progress value. Null renders an indeterminate track.
  ///
  /// Values outside `0.0..1.0` are clamped.
  final double? value;

  /// Height of the progress track.
  final double height;

  /// Filled progress tint.
  final AuraTint tint;

  /// Track background alpha.
  final double backgroundAlpha;

  /// Border radius token used for clipping the track.
  final AuraBorderRadius borderRadius;

  /// Accessibility label.
  final String? semanticLabel;

  /// Accessibility value.
  final String? semanticValue;

  @override
  Widget build(BuildContext context) => _AuraLinearProgressSemantics(
    configuration: _configuration(context),
    semanticLabel: semanticLabel,
    semanticValue: semanticValue,
  );

  _AuraLinearProgressConfiguration _configuration(BuildContext context) {
    final colors = context.auraColors;
    final theme = context.auraTheme;
    final progress = _clampProgress(value);
    final alpha = _clampAlpha(backgroundAlpha);

    return (
      height: height,
      borderRadius: theme.fromBorderRadius(borderRadius),
      value: progress,
      backgroundColor: colors.surfaceVariant,
      backgroundAlpha: alpha,
      fillColor: colors.colorFor(tint),
    );
  }
}

double? _clampProgress(double? value) {
  if (value == null) return null;
  if (value < 0) return 0;
  if (value > 1) return 1;

  return value;
}

double _clampAlpha(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;

  return value;
}

class const _AuraLinearProgressSemantics({
  required final _AuraLinearProgressConfiguration configuration,
  required final String? semanticLabel,
  required final String? semanticValue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _AuraLinearProgressTrack(configuration: configuration),
    label: semanticLabel,
    value: semanticValue,
  );
}

class const _AuraLinearProgressTrack({
  required final _AuraLinearProgressConfiguration configuration,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: configuration.height,
    child: ClipRRect(
      borderRadius: BorderRadius.all(.circular(configuration.borderRadius)),
      child: _AuraLinearProgressStack(
        value: configuration.value,
        backgroundColor: configuration.backgroundColor,
        backgroundAlpha: configuration.backgroundAlpha,
        fillColor: configuration.fillColor,
      ),
    ),
  );
}

class const _AuraLinearProgressStack({
  required final num? value,
  required final Color backgroundColor,
  required final num backgroundAlpha,
  required final Color fillColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      ColoredBox(
        color: backgroundColor.withValues(alpha: backgroundAlpha.toDouble()),
      ),
      _AuraLinearProgressFill(value: value, color: fillColor),
    ],
  );
}

class const _AuraLinearProgressFill({
  required final num? value,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (value case final value?) {
      return FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: value.toDouble(),
        child: ColoredBox(color: color),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: 0.35,
        child: ColoredBox(color: color),
      ),
    );
  }
}
