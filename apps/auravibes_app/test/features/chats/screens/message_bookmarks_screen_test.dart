import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/features/chats/providers/message_bookmarks_provider.dart';
import 'package:auravibes_app/features/chats/screens/message_bookmarks_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('shows local bookmarks when cloud bookmarks fail', (
    tester,
  ) async {
    final bookmark = MessageBookmarkEntity(
      workspaceId: 'local',
      messageId: 'message-1',
      conversationId: 'conversation-1',
      excerpt: 'Local saved message',
      workspaceName: 'Local workspace',
      createdAt: .utc(2026),
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: const MessageBookmarksScreen(workspaceId: 'local'),
          overrides: [
            cloudMessageBookmarksProvider.overrideWith(
              (ref) async => throw StateError('Cloud unavailable.'),
            ),
            messageBookmarksProvider('local')
                .overrideWith((ref) => Stream.value([bookmark])),
          ],
          workspaceId: 'local',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Local saved message'), findsOneWidget);
    expect(
      find.text('The cloud service is unavailable. Try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
