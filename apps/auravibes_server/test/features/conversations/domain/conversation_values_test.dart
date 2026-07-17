import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:test/test.dart';

void main() {
  test('only completed, cancelled, and failed turns are terminal', () {
    expect(ConversationStatuses.isTerminal(ConversationStatuses.queued), false);
    expect(
      ConversationStatuses.isTerminal(ConversationStatuses.cancelRequested),
      false,
    );
    expect(
      ConversationStatuses.isTerminal(ConversationStatuses.completed),
      true,
    );
    expect(
      ConversationStatuses.isTerminal(ConversationStatuses.cancelled),
      true,
    );
    expect(ConversationStatuses.isTerminal(ConversationStatuses.failed), true);
  });
}
