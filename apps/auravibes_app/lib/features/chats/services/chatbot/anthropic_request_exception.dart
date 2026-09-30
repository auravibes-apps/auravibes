import 'package:auravibes_app/i18n/locale_keys.dart';

/// Redacted failure at the Anthropic protocol boundary.
class const AnthropicRequestException(final String code) implements Exception {
  String get localeKey => LocaleKeys.chats_screens_chat_conversation_send_error;

  @override
  String toString() => 'AnthropicRequestException: $code';
}
