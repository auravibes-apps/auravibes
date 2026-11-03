import 'package:auravibes_app/features/chats/models/conversation_archive_export_preview.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

const _reviewTitleKey =
    'chats_screens.chat_conversation.archive_export_review_title';
const _reviewDescriptionKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_description';
const _reviewDestinationKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_destination';
const _reviewContinueKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_continue';
const _reviewIncludedWithAttachmentsKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_contents';
const _reviewIncludedWithoutAttachmentsKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_contents_without_attachments';
const _reviewIncludedNoAttachmentsKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_included_no_attachments';
const _reviewPrivacyWithAttachmentsKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_privacy';
const _reviewPrivacyWithoutAttachmentsKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_privacy_without_attachments';
const _reviewPrivacyNoAttachmentsKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_privacy_no_attachments';
const _reviewIncludeAttachmentsKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_include_attachments';
const _reviewIncludeAttachmentsDescriptionKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_include_attachments_description';
const _reviewAttachmentSectionKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_attachment_section';
const _reviewConversationSectionKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_conversation_section';
const _reviewNoAttachmentsKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_no_attachments';
const _reviewAttachmentMimeKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_attachment_mime';
const _reviewAttachmentSizeKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_attachment_size';
const _reviewUnnamedAttachmentKey =
    'chats_screens.chat_conversation.'
    'archive_export_review_unnamed_attachment';

abstract final class ConversationArchiveExportReviewDialog {
  static Future<({bool includeAttachments})?> show(
    BuildContext context, {
    required String fileName,
    required ConversationArchiveExportPreview preview,
  }) => showDialog<({bool includeAttachments})>(
    context: context,
    builder: (_) => _ConversationArchiveExportReviewDialog(
      fileName: fileName,
      preview: preview,
    ),
  );
}

class const _ConversationArchiveExportReviewDialog({
  required final String fileName,
  required final ConversationArchiveExportPreview preview,
}) extends StatefulWidget {
  @override
  State<_ConversationArchiveExportReviewDialog> createState() =>
      _ArchiveExportReviewState();
}

class _ArchiveExportReviewState
    extends State<_ConversationArchiveExportReviewDialog> {
  var _includeAttachments = true;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TextLocale(_reviewTitleKey),
    content: _ConversationArchiveExportReviewContent(
      fileName: widget.fileName,
      preview: widget.preview,
      includeAttachments: _includeAttachments,
      onIncludeAttachmentsChanged: (value) {
        setState(() => _includeAttachments = value);
      },
    ),
    actions: [
      const _ConversationArchiveExportCancelAction(),
      _ConversationArchiveExportContinueAction(
        includeAttachments: _includeAttachments,
      ),
    ],
    scrollable: true,
  );
}

class const _ConversationArchiveExportCancelAction() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.common_cancel),
  );
}

class const _ConversationArchiveExportContinueAction({
  required final bool includeAttachments,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: () =>
        Navigator.of(context).pop((includeAttachments: includeAttachments)),
    child: const TextLocale(_reviewContinueKey),
  );
}

class const _ConversationArchiveExportReviewContent({
  required final String fileName,
  required final ConversationArchiveExportPreview preview,
  required final bool includeAttachments,
  required final ValueChanged<bool> onIncludeAttachmentsChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          _ConversationArchiveExportReviewSummary(
            preview: preview,
            includeAttachments: includeAttachments,
            onIncludeAttachmentsChanged: onIncludeAttachmentsChanged,
          ),
          const AuraSizedBox(height: .sm),
          _ArchiveExportConversationList(preview: preview),
          const AuraSizedBox(height: .md),
          _ArchiveExportReviewDisclosure(
            fileName: fileName,
            preview: preview,
            includeAttachments: includeAttachments,
          ),
        ],
      ),
    );
  }
}

class const _ConversationArchiveExportReviewSummary({
  required final ConversationArchiveExportPreview preview,
  required final bool includeAttachments,
  required final ValueChanged<bool> onIncludeAttachmentsChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        const TextLocale(_reviewDescriptionKey),
        const AuraSizedBox(height: .md),
        _ArchiveExportReviewIncludedText(
          attachmentCount: preview.attachmentCount,
          includeAttachments: includeAttachments,
        ),
        if (preview.attachmentCount > 0)
          _ArchiveExportReviewAttachmentSummary(
            preview: preview,
            includeAttachments: includeAttachments,
            onIncludeAttachmentsChanged: onIncludeAttachmentsChanged,
          ),
      ],
    );
  }
}

class const _ArchiveExportReviewIncludedText({
  required final int attachmentCount,
  required final bool includeAttachments,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(switch (attachmentCount) {
    0 => _reviewIncludedNoAttachmentsKey,
    _ when includeAttachments => _reviewIncludedWithAttachmentsKey,
    _ => _reviewIncludedWithoutAttachmentsKey,
  });
}

class const _ArchiveExportReviewAttachmentSummary({
  required final ConversationArchiveExportPreview preview,
  required final bool includeAttachments,
  required final ValueChanged<bool> onIncludeAttachmentsChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      const AuraSizedBox(height: .sm),
      _ArchiveExportAttachmentToggle(
        includeAttachments: includeAttachments,
        onChanged: onIncludeAttachmentsChanged,
      ),
      const AuraSizedBox(height: .sm),
      TextLocale(
        _reviewAttachmentSectionKey,
        args: [preview.attachmentCount.toString()],
      ),
    ],
  );
}

class const _ArchiveExportAttachmentToggle({
  required final bool includeAttachments,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    key: const ValueKey('archive-export-include-attachments'),
    value: includeAttachments,
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
    title: const TextLocale(_reviewIncludeAttachmentsKey),
    subtitle: const TextLocale(_reviewIncludeAttachmentsDescriptionKey),
    controlAffinity: .leading,
    contentPadding: EdgeInsets.zero,
  );
}

class const _ArchiveExportConversationList({
  required final ConversationArchiveExportPreview preview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        const AuraSizedBox(height: .md),
        TextLocale(
          _reviewConversationSectionKey,
          args: [preview.conversations.length.toString()],
        ),
        for (final conversation in preview.conversations)
          _ConversationArchiveExportConversationRow(conversation: conversation),
      ],
    );
  }
}

class const _ConversationArchiveExportConversationRow({
  required final ConversationArchivePreviewConversation conversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.sm)),
      child: _ArchiveExportConversationRowContent(conversation: conversation),
    );
  }
}

class const _ArchiveExportConversationRowContent({
  required final ConversationArchivePreviewConversation conversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      Text(
        conversation.title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      _ArchiveExportConversationAttachments(conversation: conversation),
    ],
  );
}

class const _ArchiveExportConversationAttachments({
  required final ConversationArchivePreviewConversation conversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final attachments = conversation.attachments;
    if (attachments.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
        child: const TextLocale(_reviewNoAttachmentsKey),
      );
    }

    return Column(
      children: [
        for (final attachment in attachments)
          _ConversationArchiveExportAttachmentRow(attachment: attachment),
      ],
    );
  }
}

class const _ArchiveExportReviewDisclosure({
  required final String fileName,
  required final ConversationArchiveExportPreview preview,
  required final bool includeAttachments,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        TextLocale(switch (preview.attachmentCount) {
          0 => _reviewPrivacyNoAttachmentsKey,
          _ when includeAttachments => _reviewPrivacyWithAttachmentsKey,
          _ => _reviewPrivacyWithoutAttachmentsKey,
        }),
        const AuraSizedBox(height: .sm),
        TextLocale(_reviewDestinationKey, args: [fileName]),
      ],
    );
  }
}

class const _ConversationArchiveExportAttachmentRow({
  required final ConversationArchivePreviewAttachment attachment,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.xs),
      ),
      child: AuraRow(
        crossAxisAlignment: .start,
        spacing: .sm,
        children: [
          const _ArchiveExportAttachmentIcon(),
          Expanded(
            child: _ArchiveExportAttachmentDetails(attachment: attachment),
          ),
        ],
        crossAxisAlignment: .start,
      ),
    ),
    container: true,
  );
}

class const _ArchiveExportAttachmentIcon() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
    child: const Icon(Icons.attach_file, size: 18),
  );
}

class const _ArchiveExportAttachmentDetails({
  required final ConversationArchivePreviewAttachment attachment,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      if (attachment.fileName.isEmpty)
        const TextLocale(_reviewUnnamedAttachmentKey)
      else
        Text(attachment.fileName, softWrap: true),
      TextLocale(_reviewAttachmentMimeKey, args: [attachment.mimeType]),
      TextLocale(
        _reviewAttachmentSizeKey,
        args: [
          MaterialLocalizations.of(context).formatDecimal(attachment.sizeBytes),
        ],
      ),
    ],
  );
}
