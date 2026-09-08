import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

/// A caller-localized display row.
class AuraKeyValueEntry {
  /// Creates one key/value row.
  const new({required this.label, required this.value});

  /// Visible key.
  final String label;

  /// Visible value.
  final String value;
}

/// A display-only key/value list.
class AuraKeyValue extends StatelessWidget {
  /// Creates a list of rows.
  const new({required this.entries, super.key});

  /// Ordered rows.
  final List<AuraKeyValueEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: context.auraTheme.spacing.xs,
    children: [
      for (final entry in entries)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AuraText(child: Text(entry.label), style: .bodySmall),
            ),
            Expanded(
              child: AuraText(
                child: Text(entry.value),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
    ],
  );
}
