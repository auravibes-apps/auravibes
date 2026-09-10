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
  Widget build(BuildContext context) => AuraCard(
    child: AuraColumn(
      children: [
        _MarkdownPreviewHeader(
          titleKey: titleKey,
          editKey: editKey,
          isReadOnly: isReadOnly,
          onEdit: onEdit,
        ),
        _MarkdownPreviewContent(controller: controller, emptyKey: emptyKey),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    ),
    style: .border,
  );
}

class const _MarkdownPreviewHeader({
  required final String titleKey,
  required final String editKey,
  required final bool isReadOnly,
  required final VoidCallback onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      Expanded(
        child: AuraText(child: TextLocale(titleKey), style: .heading6),
      ),
      if (!isReadOnly)
        AuraButton(
          onPressed: onEdit,
          child: TextLocale(editKey),
          variant: .outlined,
          size: .small,
        ),
    ],
    spacing: .md,
  );
}

class const _MarkdownPreviewContent({
  required final TextEditingController controller,
  required final String emptyKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final text = value.text.trim();
          if (text.isEmpty) return EmptyMarkdownPreview(label: emptyKey);

          return GptMarkdown(text);
        },
      );
}
