import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

part 'aura_key_value_entry.dart';

/// A display-only key/value list.
class AuraKeyValue extends StatelessWidget {
  /// Creates a list of rows.
  const new({required this.entries, super.key});

  /// Ordered rows.
  final List<AuraKeyValueEntry> entries;

  @override
  Widget build(BuildContext context) => _AuraKeyValueContent(
    entries: entries,
    spacing: context.auraTheme.spacing,
  );
}

class _AuraKeyValueContent extends StatelessWidget {
  _AuraKeyValueContent({
    required List<AuraKeyValueEntry> entries,
    required AuraSpacingScale spacing,
  }) : _child = Column(
         crossAxisAlignment: .stretch,
         spacing: spacing.xs,
         children: [
           for (final entry in entries)
             Row(
               crossAxisAlignment: .start,
               children: [
                 Expanded(
                   child: AuraText(child: Text(entry.label), style: .bodySmall),
                 ),
                 Expanded(
                   child: AuraText(child: Text(entry.value), textAlign: .end),
                 ),
               ],
             ),
         ],
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}
