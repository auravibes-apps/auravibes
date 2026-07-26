import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('falls back to four words and thirty visible characters', () {
    expect(
      fallbackConversationTitle('  Hello   world this is a test  '),
      'Hello world this is',
    );
    expect(fallbackConversationTitle('a' * 100), '${'a' * 27}...');
  });

  test('normalizes streaming model titles and falls back when empty', () {
    expect(
      normalizeConversationTitle(' "Title: Deep Focus" ', 'fallback title'),
      'Deep Focus',
    );
    expect(
      normalizeConversationTitle('Conversation: ', 'one two three four'),
      'one two three four',
    );
  });
}
