import 'package:characters/characters.dart';

const conversationTitleSystemPrompt = 'You generate conversation titles.';

String conversationTitlePrompt(String firstMessage) =>
    'Generate a short, concise title (max 5 words) for a conversation '
    'that starts with this message: "$firstMessage". '
    'The title should capture the main topic or theme. '
    'Respond with only the title, no quotes or extra text.';

String fallbackConversationTitle(String message) {
  final title = message
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(4)
      .join(' ');

  return _truncate(title, 30);
}

String normalizeConversationTitle(String title, String firstMessage) {
  var normalized = title.trim();
  for (final quote in const ['"', "'"]) {
    if (normalized.length > 1 &&
        normalized.startsWith(quote) &&
        normalized.endsWith(quote)) {
      normalized = normalized.characters
          .skip(1)
          .take(
            normalized.characters.length - 2,
          )
          .toString();
    }
  }
  for (final prefix in const ['Title:', 'Conversation:']) {
    if (normalized.startsWith(prefix)) {
      normalized = normalized.replaceFirst(prefix, '').trim();
    }
  }

  return normalized.isEmpty
      ? fallbackConversationTitle(firstMessage)
      : _truncate(normalized, 50);
}

String _truncate(String value, int maxLength) {
  final valueCharacters = value.characters;
  if (valueCharacters.length <= maxLength) return value;

  const suffix = '...';
  return '${valueCharacters.take(maxLength - suffix.length)}$suffix';
}
