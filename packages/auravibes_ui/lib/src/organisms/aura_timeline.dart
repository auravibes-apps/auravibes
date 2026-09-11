import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

part 'aura_timeline_entry.dart';

/// A display-only activity history.
class AuraTimeline extends StatelessWidget {
  /// Creates a timeline.
  const new({required this.entries, super.key});

  /// Entries in display order.
  final List<AuraTimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    spacing: context.auraTheme.spacing.md,
    children: [
      for (final entry in entries) _AuraTimelineEntryView(entry: entry),
    ],
  );
}

class const _AuraTimelineEntryView({required final AuraTimelineEntry entry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .start,
    spacing: context.auraTheme.spacing.sm,
    children: [
      AuraIcon(Icons.circle, size: .extraSmall, tint: entry.tint),
      Expanded(child: _AuraTimelineEntryText(entry: entry)),
    ],
  );
}

class const _AuraTimelineEntryText({required final AuraTimelineEntry entry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      AuraText(child: Text(entry.title)),
      if (entry.description case final value?)
        AuraText(child: Text(value), style: .bodySmall),
      if (entry.time case final value?)
        AuraText(child: Text(value), style: .caption),
    ],
  );
}
