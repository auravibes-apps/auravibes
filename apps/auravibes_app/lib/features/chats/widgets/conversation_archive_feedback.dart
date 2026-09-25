import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';

void showConversationArchiveError(BuildContext context, Object error) {
  if (!context.mounted) return;

  final localizationKey = switch (error) {
    MalformedConversationArchiveException(:final localizationKey) =>
      localizationKey,
    UnsupportedArchiveVersionException(:final localizationKey) =>
      localizationKey,
    _ => LocaleKeys.chats_screens_chat_conversation_archive_error,
  };
  final _ = AuraSnackBars.show(
    context: context,
    content: TextLocale(localizationKey),
    variant: .error,
  );
}
