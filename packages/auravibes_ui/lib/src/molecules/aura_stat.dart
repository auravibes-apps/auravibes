import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/molecules/aura_card.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A compact KPI tile with a value, label, and optional delta.
class AuraStat extends StatelessWidget {
  /// Creates a stat tile.
  const new({
    required this.value,
    required this.label,
    super.key,
    this.delta,
    this.icon,
    this.tint = AuraTint.primary,
  });

  /// Prominent value.
  final String value;

  /// Caller-localized metric name.
  final String label;

  /// Optional delta or supporting value.
  final String? delta;

  /// Optional metric icon.
  final IconData? icon;

  /// Semantic accent color.
  final AuraTint tint;

  @override
  Widget build(BuildContext context) => AuraCard(
    child: Column(
      crossAxisAlignment: .start,
      spacing: context.auraTheme.spacing.xs,
      children: [
        if (icon case final value?) AuraIcon(value, tint: tint),
        AuraText(child: Text(value), style: .heading3),
        AuraText(child: Text(label), style: .bodySmall),
        if (delta case final value?)
          AuraText(child: Text(value), style: .caption),
      ],
    ),
    tint: tint,
  );
}
