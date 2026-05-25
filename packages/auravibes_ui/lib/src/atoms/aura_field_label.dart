import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable field label component following the Aura design system.
///
/// This label provides consistent typography and styling for field titles
/// with optional required field indicators.
class AuraFieldLabel extends StatelessWidget {
  /// Creates a Aura field label.
  const AuraFieldLabel({
    required this.child,
    super.key,
    this.isRequired = false,
    this.style,
    this.semanticLabel,
  });

  /// The label text to display.
  final Widget child;

  /// Whether the field is required.
  final bool isRequired;

  /// Optional text style to override the default.
  final AuraTextStyle? style;

  /// A semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: AuraText(
            child: Semantics(
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  fontWeight: DesignTypography.fontWeightMedium,
                ),
                child: child,
              ),
              label: semanticLabel,
            ),
            style: style ?? AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurface,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: DesignSpacing.xs),
          AuraText(
            child: const Text(
              '*',
              style: TextStyle(
                fontWeight: DesignTypography.fontWeightMedium,
              ),
              semanticsLabel: 'required',
            ),
            style: style ?? AuraTextStyle.bodySmall,
            color: AuraColorVariant.error,
          ),
        ],
      ],
    );
  }
}
