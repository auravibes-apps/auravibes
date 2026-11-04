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

  test('preserves data roles and provenance in compaction history', () {
    final messages = buildConversationCompactionMessages([
      const ConversationCompactionMessage(
        role: 'system',
        content: 'EXTERNAL_SENTINEL',
      ),
      const ConversationCompactionMessage(
        role: 'system',
        content: 'AUTHORIZED_SENTINEL',
        provenance: AgentContextProvenance.applicationPrompt,
      ),
    ]);

    expect(messages[0].role, 'system');
    expect(messages[0].provenance, AgentContextProvenance.applicationPrompt);
    expect(messages[1].role, 'user');
    expect(messages[1].content, 'EXTERNAL_SENTINEL');
    expect(messages[1].provenance, AgentContextProvenance.unknown);
    expect(messages[2].role, 'system');
    expect(messages[2].content, 'AUTHORIZED_SENTINEL');
    expect(messages[2].provenance, AgentContextProvenance.applicationPrompt);
    expect(messages.last.role, 'user');
  });

  test('normalizes non-empty summaries and rejects empty output', () {
    expect(requireCompactionSummary(' summary '), 'summary');
    expect(() => requireCompactionSummary(' \n '), throwsFormatException);
  });
}
