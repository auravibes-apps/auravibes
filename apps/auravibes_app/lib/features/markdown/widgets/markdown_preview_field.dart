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
  final bool isRequired = false,
  final String? errorText,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _MarkdownPreviewBody(
      controller: controller,
      titleKey: titleKey,
      editKey: editKey,
      emptyKey: emptyKey,
      isReadOnly: isReadOnly,
      isRequired: isRequired,
      errorText: errorText,
      onEdit: onEdit,
    ),
    style: .border,
  );
}

class const _MarkdownPreviewBody({
  required final TextEditingController controller,
  required final String titleKey,
  required final String editKey,
  required final String emptyKey,
  required final bool isReadOnly,
  required final bool isRequired,
  required final String? errorText,
  required final VoidCallback onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final error = errorText;

    return AuraColumn(
      children: [
        _MarkdownPreviewHeader(
          titleKey: titleKey,
          editKey: editKey,
          isReadOnly: isReadOnly,
          isRequired: isRequired,
          onEdit: onEdit,
        ),
        _MarkdownPreviewContent(controller: controller, emptyKey: emptyKey),
        if (error != null)
          AuraText(child: Text(error), style: .caption, tint: .error),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _MarkdownPreviewHeader({
  required final String titleKey,
  required final String editKey,
  required final bool isReadOnly,
  required final bool isRequired,
  required final VoidCallback onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      Expanded(
        child: AuraRow(
          children: [
            AuraText(child: TextLocale(titleKey), style: .heading6),
            if (isRequired) const AuraText(child: Text('*'), tint: .error),
          ],
          spacing: .xs,
        ),
      ),
      if (!isReadOnly)
        _MarkdownPreviewEditButton(editKey: editKey, onEdit: onEdit),
    ],
    spacing: .md,
  );
}

class const _MarkdownPreviewEditButton({
  required final String editKey,
  required final VoidCallback onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onEdit,
    child: TextLocale(editKey),
    variant: .outlined,
    size: .small,
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
          return _MarkdownPreviewValue(text: value.text, emptyKey: emptyKey);
        },
      );
}

class const _MarkdownPreviewValue({
  required final String text,
  required final String emptyKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return EmptyMarkdownPreview(label: emptyKey);

    return GptMarkdown(text);
  }
}
