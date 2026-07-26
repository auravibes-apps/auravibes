const conversationCompactionSystemPrompt =
    'You are a conversation compaction assistant. Your task is to create '
    'a comprehensive but concise summary of the conversation messages '
    'provided. Preserve all of the following:\n'
    '- User goals and intents\n'
    '- Key constraints and requirements\n'
    '- Important decisions made\n'
    '- Current task status and progress\n'
    '- Files, identifiers, and technical references mentioned\n'
    '- Errors encountered and their resolutions\n'
    '- Pending tasks and open questions\n'
    '- Concise facts from tool outputs that affect the task\n\n'
    'Do NOT:\n'
    '- Invent code state or file contents you have not seen\n'
    '- Preserve sensitive tool output verbatim\n'
    '- Mark unresolved tool calls as completed\n'
    '- Add information not present in the conversation\n';

const conversationCompactionRequestPrompt =
    'Please create a comprehensive summary of the above conversation. '
    'Preserve all goals, decisions, technical details, and current status.';

class ConversationCompactionMessage {
  const ConversationCompactionMessage({
    required this.role,
    required this.content,
  });

  final String role;
  final String content;
}

List<ConversationCompactionMessage> buildConversationCompactionMessages(
  Iterable<ConversationCompactionMessage> history,
) => [
  const ConversationCompactionMessage(
    role: 'system',
    content: conversationCompactionSystemPrompt,
  ),
  ...history,
  const ConversationCompactionMessage(
    role: 'user',
    content: conversationCompactionRequestPrompt,
  ),
];

String requireCompactionSummary(String summary) {
  final normalized = summary.trim();
  if (normalized.isEmpty) {
    throw const FormatException('Compaction summary is empty.');
  }
  return normalized;
}
