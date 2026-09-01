import 'package:auravibes_app/features/markdown/widgets/empty_markdown_preview.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class const MarkdownPreviewField({
  required final TextEditingController controller,
  required final String titleKey,
  required final String editKey,
  required final String emptyKey,
  required final VoidCallback onEdit,
  final bool isReadOnly = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          AuraRow(
            children: [
              Expanded(
                child: AuraText(
                  child: TextLocale(titleKey),
                  style: AuraTextStyle.heading6,
                ),
              ),
              if (!isReadOnly)
                AuraButton(
                  onPressed: onEdit,
                  child: TextLocale(editKey),
                  variant: AuraButtonVariant.outlined,
                  size: AuraButtonSize.small,
                ),
            ],
            spacing: .md,
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final text = value.text.trim();
              if (text.isEmpty) {
                return EmptyMarkdownPreview(label: emptyKey);
              }

              return GptMarkdown(text);
            },
          ),
        ],
        spacing: .sm,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      style: AuraCardStyle.border,
    );
  }
}
