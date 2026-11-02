import 'package:auravibes_app/i18n/locale_keys.dart';

class const ConversationArchiveStateException({
  final String localizationKey =
      LocaleKeys.chats_screens_chat_conversation_archive_state_error,
}) implements Exception {
  @override
  String toString() => 'ConversationArchiveStateException($localizationKey)';
}
