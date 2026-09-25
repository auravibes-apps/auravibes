import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the shared destructive confirmation dialog for conversation deletion.
abstract final class DeleteConversationConfirmDialog {
  static Future<bool> show(BuildContext context, {bool bulk = false}) async {
    final confirmed = await AuraDialogs.confirm(
      context: context,
      title: _title(bulk),
      message: _message(bulk),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.common_delete),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
      isDestructive: true,
    );

    return confirmed ?? false;
  }

  static TextLocale _title(bool bulk) => TextLocale(
    bulk
        ? LocaleKeys.chats_screens_chats_list_bulk_delete_title
        : LocaleKeys.chats_screens_chat_conversation_delete_title,
  );

  static TextLocale _message(bool bulk) => TextLocale(
    bulk
        ? LocaleKeys.chats_screens_chats_list_bulk_delete_confirm
        : LocaleKeys.chats_screens_chat_conversation_delete_confirm,
  );
}
