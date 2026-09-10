import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class const EmptyMarkdownPreview({required final String label, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _emptyPreviewDecoration(auraColors),
      child: AuraText(child: TextLocale(label), style: .caption),
    );
  }
}

BoxDecoration _emptyPreviewDecoration(AuraColorScheme colors) => BoxDecoration(
  color: colors.surfaceVariant.withValues(alpha: 0.45),
  border: Border.fromBorderSide(.new(color: colors.outlineVariant)),
  borderRadius: const BorderRadius.all(.circular(8)),
);
