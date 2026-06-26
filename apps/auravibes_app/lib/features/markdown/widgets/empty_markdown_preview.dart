import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class EmptyMarkdownPreview extends StatelessWidget {
  const EmptyMarkdownPreview({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: auraColors.surfaceVariant.withValues(alpha: 0.45),
        border: Border.fromBorderSide(
          BorderSide(color: auraColors.outlineVariant),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: AuraText(
        child: TextLocale(label),
        style: AuraTextStyle.caption,
        color: AuraColorVariant.onSurfaceVariant,
      ),
    );
  }
}
