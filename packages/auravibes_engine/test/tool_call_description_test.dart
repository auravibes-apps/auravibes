import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('requires concise tool-scoped action descriptions', () {
    expect(toolCallNarrationInstruction, contains('immediate operation'));
    expect(
      toolCallNarrationInstruction,
      contains('omit first-person phrasing'),
    );
    expect(toolCallNarrationInstruction, contains('prior failures'));
    expect(toolCallNarrationInstruction, contains('future steps'));
    expect(
      toolCallNarrationInstruction,
      contains('Do not put this description in tool arguments.'),
    );
  });

  test('normalizes provider text and bounds the display description', () {
    final description = normalizeToolCallUserFacingDescription([
      {'text': ' Search the web\n'},
      {'type': 'ignored'},
      {'text': 'for an item. '},
    ]);

    expect(description, 'Search the web for an item.');

    final longDescription = normalizeToolCallUserFacingDescription(
      'x' * (maxToolCallUserFacingDescriptionCharacters + 20),
    );
    expect(
      longDescription,
      hasLength(maxToolCallUserFacingDescriptionCharacters),
    );
    expect(longDescription, endsWith('…'));
  });

  test('treats missing and blank provider text as absent', () {
    expect(normalizeToolCallUserFacingDescription(null), isNull);
    expect(normalizeToolCallUserFacingDescription(' \n\t '), isNull);
    expect(normalizeToolCallUserFacingDescription(const []), isNull);
  });
}
