import 'package:auravibes_app/features/markdown/widgets/empty_markdown_preview.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class MarkdownPreviewField extends StatelessWidget {
  const MarkdownPreviewField({
    required this.controller,
    required this.titleKey,
    required this.editKey,
    required this.emptyKey,
    required this.onEdit,
    this.isReadOnly = false,
    super.key,
  });

  final TextEditingController controller;
  final String titleKey;
  final String editKey;
  final String emptyKey;
  final VoidCallback onEdit;
  final bool isReadOnly;

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
