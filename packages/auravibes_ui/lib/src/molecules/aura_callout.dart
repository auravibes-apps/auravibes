import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// An inline semantic alert with optional icon and description.
class AuraCallout extends StatelessWidget {
  /// Creates a callout.
  const new({
    required this.title,
    super.key,
    this.description,
    this.icon,
    this.tint = AuraTint.info,
  });

  /// Caller-localized heading.
  final String title;

  /// Caller-localized supporting text.
  final String? description;

  /// Optional status icon.
  final IconData? icon;

  /// Semantic visual tone.
  final AuraTint tint;

  @override
  Widget build(BuildContext context) => Semantics(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.auraColors.colorFor(tint).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          context.auraTheme.fromBorderRadius(.md),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.auraTheme.spacing.md),
        child: Row(
          crossAxisAlignment: .start,
          spacing: context.auraTheme.spacing.sm,
          children: [
            if (icon case final value?) AuraIcon(value, tint: tint),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  AuraText(child: Text(title), style: .bodyLarge, tint: tint),
                  if (description case final value?)
                    AuraText(child: Text(value), style: .bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    liveRegion: true,
  );
}
