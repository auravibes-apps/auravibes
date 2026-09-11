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
    child: _AuraStatContent(stat: this),
    tint: tint,
  );
}

class const _AuraStatContent({required final AuraStat stat})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.spacing;
    final stat = this.stat;

    return _AuraStatRows(stat: stat, spacing: spacing);
  }
}

class const _AuraStatRows({
  required final AuraStat stat,
  required final AuraSpacingScale spacing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    spacing: spacing.xs,
    children: [
      if (stat.icon case final icon?)
        _AuraStatIcon(icon: icon, tint: stat.tint),
      _AuraStatBody(stat: stat, spacing: spacing),
    ],
  );
}

class const _AuraStatIcon({
  required final IconData icon,
  required final AuraTint tint,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIcon(icon, tint: tint);
}

class _AuraStatBody extends StatelessWidget {
  new({required AuraStat stat, required AuraSpacingScale spacing})
    : _child = Column(
        crossAxisAlignment: .start,
        spacing: spacing.xs,
        children: [
          AuraText(child: Text(stat.value), style: .heading3),
          AuraText(child: Text(stat.label), style: .bodySmall),
          if (stat.delta case final delta?)
            AuraText(child: Text(delta), style: .caption),
        ],
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}
