import 'package:riverpod/riverpod.dart';

class ConversationAgentLanguageRuntime {
  final Map<String, String> _languageCodes = {};

  String? languageCodeFor(String conversationId) =>
      _languageCodes[conversationId];

  void remember(String conversationId, String? languageCode) {
    final normalizedLanguageCode = languageCode?.trim();
    if (normalizedLanguageCode == null || normalizedLanguageCode.isEmpty) {
      return;
    }

    _languageCodes[conversationId] = normalizedLanguageCode;
  }
}

final conversationAgentLanguageRuntimeProvider =
    Provider<ConversationAgentLanguageRuntime>(
      (ref) => ConversationAgentLanguageRuntime(),
    );
