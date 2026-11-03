import 'package:auravibes_app/features/chats/models/conversation_archive_export_preview.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

const _reviewTitleKey =
    'chats_screens.chat_conversation.archive_export_review_title';
const _reviewDescriptionKey =
    'chats_screens.chat_conversation.archive_export_review_description';
const _reviewDestinationKey =
    'chats_screens.chat_conversation.archive_export_review_destination';
const _reviewContinueKey =
    'chats_screens.chat_conversation.archive_export_review_continue';
const _reviewIncludedWithAttachmentsKey =
    'chats_screens.chat_conversation.archive_export_review_contents';
const _reviewIncludedWithoutAttachmentsKey =
    'chats_screens.chat_conversation.archive_export_review_contents_without_attachments';
const _reviewIncludedNoAttachmentsKey =
    'chats_screens.chat_conversation.archive_export_review_included_no_attachments';
const _reviewPrivacyWithAttachmentsKey =
    'chats_screens.chat_conversation.archive_export_review_privacy';
const _reviewPrivacyWithoutAttachmentsKey =
    'chats_screens.chat_conversation.archive_export_review_privacy_without_attachments';
const _reviewPrivacyNoAttachmentsKey =
    'chats_screens.chat_conversation.archive_export_review_privacy_no_attachments';
const _reviewIncludeAttachmentsKey =
    'chats_screens.chat_conversation.archive_export_review_include_attachments';
const _reviewIncludeAttachmentsDescriptionKey =
    'chats_screens.chat_conversation.archive_export_review_include_attachments_description';
const _reviewAttachmentSectionKey =
    'chats_screens.chat_conversation.archive_export_review_attachment_section';
const _reviewConversationSectionKey =
    'chats_screens.chat_conversation.archive_export_review_conversation_section';
const _reviewNoAttachmentsKey =
    'chats_screens.chat_conversation.archive_export_review_no_attachments';
const _reviewAttachmentMimeKey =
    'chats_screens.chat_conversation.archive_export_review_attachment_mime';
const _reviewAttachmentSizeKey =
    'chats_screens.chat_conversation.archive_export_review_attachment_size';
const _reviewUnnamedAttachmentKey =
    'chats_screens.chat_conversation.archive_export_review_unnamed_attachment';

abstract final class ConversationArchiveExportReviewDialog {
  static Future<({bool includeAttachments})?> show(
    BuildContext context, {
    required String fileName,
    required ConversationArchiveExportPreview preview,
  }) async {
    final decision = await showDialog<({bool includeAttachments})>(
      context: context,
      builder: (_) => _ConversationArchiveExportReviewDialog(
        fileName: fileName,
        preview: preview,
      ),
    );

    return decision;
  }
}

class const _ConversationArchiveExportReviewDialog({
  required final String fileName,
  required final ConversationArchiveExportPreview preview,
}) extends StatefulWidget {
  @override
  State<_ConversationArchiveExportReviewDialog> createState() =>
      _ConversationArchiveExportReviewDialogState();
}

class _ConversationArchiveExportReviewDialogState
    extends State<_ConversationArchiveExportReviewDialog> {
  bool _includeAttachments = true;

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
    final theme = context.auraTheme;

    return SizedBox(
      width: 480,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            const TextLocale(_reviewDescriptionKey),
            SizedBox(height: theme.fromSpacing(.md)),
            TextLocale(switch (preview.attachmentCount) {
              0 => _reviewIncludedNoAttachmentsKey,
              _ when includeAttachments => _reviewIncludedWithAttachmentsKey,
              _ => _reviewIncludedWithoutAttachmentsKey,
            }),
            if (preview.attachmentCount > 0) ...[
              SizedBox(height: theme.fromSpacing(.sm)),
              CheckboxListTile(
                key: const ValueKey('archive-export-include-attachments'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: includeAttachments,
                onChanged: (value) {
                  if (value != null) onIncludeAttachmentsChanged(value);
                },
                title: const TextLocale(_reviewIncludeAttachmentsKey),
                subtitle: const TextLocale(
                  _reviewIncludeAttachmentsDescriptionKey,
                ),
              ),
            ],
            SizedBox(height: theme.fromSpacing(.sm)),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    if (preview.attachmentCount > 0)
                      TextLocale(
                        _reviewAttachmentSectionKey,
                        args: [preview.attachmentCount.toString()],
                      ),
                    SizedBox(height: theme.fromSpacing(.md)),
                    TextLocale(
                      _reviewConversationSectionKey,
                      args: [preview.conversations.length.toString()],
                    ),
                    for (final conversation in preview.conversations)
                      Padding(
                        padding: EdgeInsets.only(top: theme.fromSpacing(.sm)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversation.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (conversation.attachments.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: theme.fromSpacing(.xs),
                                ),
                                child: const TextLocale(_reviewNoAttachmentsKey),
                              ),
                            for (final attachment in conversation.attachments)
                              _ConversationArchiveExportAttachmentRow(
                                attachment: attachment,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: theme.fromSpacing(.md)),
            TextLocale(switch (preview.attachmentCount) {
              0 => _reviewPrivacyNoAttachmentsKey,
              _ when includeAttachments => _reviewPrivacyWithAttachmentsKey,
              _ => _reviewPrivacyWithoutAttachmentsKey,
            }),
            SizedBox(height: theme.fromSpacing(.sm)),
            TextLocale(_reviewDestinationKey, args: [fileName]),
          ],
        ),
      ),
    );
  }
}

class const _ConversationArchiveExportAttachmentRow({
  required final ConversationArchiveExportAttachmentPreview attachment,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;

    return Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.fromSpacing(.xs)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: theme.fromSpacing(.xs),
                right: theme.fromSpacing(.sm),
              ),
              child: const Icon(Icons.attach_file, size: 18),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (attachment.fileName.isEmpty)
                    const TextLocale(_reviewUnnamedAttachmentKey)
                  else
                    Text(attachment.fileName, softWrap: true),
                  TextLocale(
                    _reviewAttachmentMimeKey,
                    args: [attachment.mimeType],
                  ),
                  TextLocale(
                    _reviewAttachmentSizeKey,
                    args: [
                      MaterialLocalizations.of(context)
                          .formatDecimal(attachment.sizeBytes),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
