import 'package:auravibes_server/src/features/conversations/domain/message_bookmark_view_mapper.dart';
import 'package:test/test.dart';

void main() {
  test('uses saved message metadata when the live message is unavailable', () {
    final messageCreatedAt = DateTime.utc(2026, 10, 20, 12);
    final contentSnapshot = List.filled(161, 'x').join();

    final view = mapMessageBookmarkView(
      conversationId: 'source-conversation',
      messageId: 'deleted-message',
      contentSnapshot: contentSnapshot,
      roleSnapshot: 'user',
      messageCreatedAtSnapshot: messageCreatedAt,
      content: null,
      role: null,
      createdAt: null,
      conversationTitle: 'Source',
      workspaceName: 'Bookmarks',
    );

    expect(view.conversationId, 'source-conversation');
    expect(view.messageId, 'deleted-message');
    expect(view.excerpt, '${List.filled(160, 'x').join()}...');
    expect(view.isUser, isTrue);
    expect(view.conversationTitle, 'Source');
    expect(view.workspaceName, 'Bookmarks');
    expect(view.createdAt, messageCreatedAt);
  });

  test('preserves assistant role from the saved snapshot', () {
    final view = mapMessageBookmarkView(
      conversationId: 'source-conversation',
      messageId: 'deleted-assistant-message',
      contentSnapshot: 'Saved response',
      roleSnapshot: 'assistant',
      messageCreatedAtSnapshot: DateTime.utc(2026, 10, 20, 12),
      content: null,
      role: null,
      createdAt: null,
      conversationTitle: 'Source',
      workspaceName: 'Bookmarks',
    );

    expect(view, isNotNull);
    expect(view.isUser, isFalse);
  });
}
