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
      details: .new(
        messageId: 'message-1',
        conversationId: 'conversation-1',
        excerpt: 'Local saved message',
        workspaceName: 'Local workspace',
        createdAt: .utc(2026),
      ),
      workspace: const MessageBookmarkWorkspace(workspaceId: 'local'),
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

  testWidgets('retries loading cloud bookmarks after a failure', (
    tester,
  ) async {
    var attempts = 0;
    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: const MessageBookmarksScreen(workspaceId: 'local'),
          overrides: [
            cloudMessageBookmarksProvider.overrideWith((ref) async {
              attempts++;
              if (attempts == 1) throw StateError('Cloud unavailable.');

              return const [];
            }),
            messageBookmarksProvider('local')
                .overrideWith((ref) => Stream.value(const [])),
          ],
          workspaceId: 'local',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(
      find.text('The cloud service is unavailable. Try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    final _ = await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(
      find.text('The cloud service is unavailable. Try again.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
