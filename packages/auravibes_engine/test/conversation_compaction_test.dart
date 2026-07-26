import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('builds a deterministic compaction request around history', () {
    final messages = buildConversationCompactionMessages([
      const ConversationCompactionMessage(role: 'user', content: 'Need help'),
    ]);

    expect(messages.map((message) => message.role), ['system', 'user', 'user']);
    expect(messages.first.content, conversationCompactionSystemPrompt);
    expect(messages.last.content, conversationCompactionRequestPrompt);
  });

  test('normalizes non-empty summaries and rejects empty output', () {
    expect(requireCompactionSummary(' summary '), 'summary');
    expect(() => requireCompactionSummary(' \n '), throwsFormatException);
  });
}
