// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/core/exceptions/no_conversation_selected_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoConversationSelectedException', () {
    test('toString has expected message', () {
      const ex = NoConversationSelectedException();
      expect(
        ex.toString(),
        'NoConversationSelectedException: No conversation is currently '
        'selected',
      );
    });
  });
}
