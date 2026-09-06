import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// One read-only timeline entry.
class AuraTimelineEntry {
  /// Creates an entry.
  const new({
    required this.title,
    this.description,
    this.time,
    this.tint = AuraTint.primary,
  });

  /// Caller-localized title.
  final String title;

  /// Optional description.
  final String? description;

  /// Optional time label.
  final String? time;

  /// Entry marker tint.
  final AuraTint tint;
}

/// A display-only activity history.
class AuraTimeline extends StatelessWidget {
  /// Creates a timeline.
  const new({required this.entries, super.key});

  /// Entries in display order.
  final List<AuraTimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: context.auraTheme.spacing.md,
    children: [
      for (final entry in entries)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: context.auraTheme.spacing.sm,
          children: [
            AuraIcon(Icons.circle, size: .extraSmall, tint: entry.tint),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuraText(child: Text(entry.title)),
                  if (entry.description case final value?)
                    AuraText(child: Text(value), style: .bodySmall),
                  if (entry.time case final value?)
                    AuraText(child: Text(value), style: .caption),
                ],
              ),
            ),
          ],
        ),
    ],
  );
}
