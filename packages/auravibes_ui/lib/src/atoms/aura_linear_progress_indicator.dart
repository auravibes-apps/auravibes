import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraBorderRadius, AuraTint;
import 'package:flutter/widgets.dart';

/// A linear progress indicator following the Aura design system.
class AuraLinearProgressIndicator extends StatelessWidget {
  /// Creates an Aura linear progress indicator.
  const AuraLinearProgressIndicator({
    required this.value,
    super.key,
    this.height = 4,
    this.tint = AuraTint.primary,
    this.backgroundAlpha = 1,
    this.borderRadius = AuraBorderRadius.full,
    this.semanticLabel,
    this.semanticValue,
  });

  /// Current progress value.
  ///
  /// Values outside `0.0..1.0` are clamped.
  final double value;

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
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final clampedValue = value.clamp(0.0, 1.0);
    final clampedBackgroundAlpha = backgroundAlpha.clamp(0.0, 1.0);

    return Semantics(
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.all(
            Radius.circular(context.auraTheme.fromBorderRadius(borderRadius)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: auraColors.surfaceVariant.withValues(
                  alpha: clampedBackgroundAlpha,
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clampedValue,
                child: ColoredBox(
                  color: auraColors.colorFor(tint),
                ),
              ),
            ],
          ),
        ),
      ),
      label: semanticLabel,
      value: semanticValue,
    );
  }
}
