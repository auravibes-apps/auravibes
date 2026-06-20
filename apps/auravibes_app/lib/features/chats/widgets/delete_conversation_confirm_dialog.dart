import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

/// Shows the shared destructive confirmation dialog for conversation deletion.
Future<bool> showDeleteConversationConfirmDialog(BuildContext context) async {
  final confirmed = await showAuraConfirmDialog(
    context: context,
    title: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_delete_title,
    ),
    message: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_delete_confirm,
    ),
    actions: const AuraConfirmDialogActions(
      confirmLabel: TextLocale(LocaleKeys.common_delete),
      cancelLabel: TextLocale(LocaleKeys.common_cancel),
    ),
    isDestructive: true,
  );

  return confirmed ?? false;
}
