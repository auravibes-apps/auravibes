import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

const _reviewTitleKey =
    'chats_screens.chat_conversation.archive_export_review_title';
const _reviewDescriptionKey =
    'chats_screens.chat_conversation.archive_export_review_description';
const _reviewContentsKey =
    'chats_screens.chat_conversation.archive_export_review_contents';
const _reviewPrivacyKey =
    'chats_screens.chat_conversation.archive_export_review_privacy';
const _reviewDestinationKey =
    'chats_screens.chat_conversation.archive_export_review_destination';
const _reviewContinueKey =
    'chats_screens.chat_conversation.archive_export_review_continue';

abstract final class ConversationArchiveExportReviewDialog {
  static Future<bool> show(
    BuildContext context, {
    required String fileName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _ConversationArchiveExportReviewDialog(fileName: fileName),
    );

    return confirmed == true;
  }
}

class const _ConversationArchiveExportReviewDialog({
  required final String fileName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TextLocale(_reviewTitleKey),
    content: _buildContent(),
    actions: _buildActions(context),
  );

  Widget _buildContent() => SizedBox(
    width: 480,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          const TextLocale(_reviewDescriptionKey),
          const SizedBox(height: 16),
          const TextLocale(_reviewContentsKey),
          const SizedBox(height: 16),
          const TextLocale(_reviewPrivacyKey),
          const SizedBox(height: 16),
          TextLocale(_reviewDestinationKey, args: [fileName]),
        ],
      ),
    ),
  );

  List<Widget> _buildActions(BuildContext context) => [
    TextButton(
      onPressed: () => Navigator.of(context).pop(false),
      child: const TextLocale(LocaleKeys.common_cancel),
    ),
    FilledButton(
      onPressed: () => Navigator.of(context).pop(true),
      child: const TextLocale(_reviewContinueKey),
    ),
  ];
}
