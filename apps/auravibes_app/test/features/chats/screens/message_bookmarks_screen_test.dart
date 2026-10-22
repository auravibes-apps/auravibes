import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/features/chats/providers/message_bookmarks_provider.dart';
import 'package:auravibes_app/features/chats/screens/message_bookmarks_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('shows the author role for each saved message', (tester) async {
    final userBookmark = MessageBookmarkEntity(
      details: .new(
        messageId: 'user-message',
        conversationId: 'conversation-1',
        excerpt: 'Question',
        workspaceName: 'Local workspace',
        createdAt: .utc(2026),
        isUser: true,
      ),
      workspace: const MessageBookmarkWorkspace(workspaceId: 'local'),
    );
    final assistantBookmark = MessageBookmarkEntity(
      details: .new(
        messageId: 'assistant-message',
        conversationId: 'conversation-1',
        excerpt: 'Answer',
        workspaceName: 'Local workspace',
        createdAt: .utc(2026),
        isUser: false,
      ),
      workspace: const MessageBookmarkWorkspace(workspaceId: 'local'),
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: const MessageBookmarksScreen(workspaceId: 'local'),
          overrides: [
            cloudMessageBookmarksProvider.overrideWith((ref) async => const []),
            messageBookmarksProvider('local').overrideWith(
              (ref) => Stream.value([userBookmark, assistantBookmark]),
            ),
          ],
          workspaceId: 'local',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Assistant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lists bookmarks from the selected workspace and conversation', (
    tester,
  ) async {
    final selectedBookmark = MessageBookmarkEntity(
      details: .new(
        messageId: 'selected-message',
        conversationId: 'conversation-1',
        excerpt: 'Selected conversation message',
        workspaceName: 'Local workspace',
        createdAt: .utc(2026),
      ),
      workspace: const MessageBookmarkWorkspace(workspaceId: 'local'),
    );
    final otherBookmark = MessageBookmarkEntity(
      details: .new(
        messageId: 'other-message',
        conversationId: 'conversation-2',
        excerpt: 'Other conversation message',
        workspaceName: 'Local workspace',
        createdAt: .utc(2026),
      ),
      workspace: const MessageBookmarkWorkspace(workspaceId: 'local'),
    );
    final sameConversationInOtherWorkspace = MessageBookmarkEntity(
      details: .new(
        messageId: 'foreign-message',
        conversationId: 'conversation-1',
        excerpt: 'Other workspace message',
        workspaceName: 'Other workspace',
        createdAt: .utc(2026),
      ),
      workspace: const MessageBookmarkWorkspace(
        workspaceId: 'other-workspace',
        cloudServerUrl: 'https://cloud.example',
        cloudAccountId: 'account-2',
        cloudWorkspaceId: 27,
      ),
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: const MessageBookmarksScreen(
            workspaceId: 'local',
            conversationId: 'conversation-1',
          ),
          overrides: [
            cloudMessageBookmarksProvider.overrideWith((ref) async => const []),
            messageBookmarksProvider('local').overrideWith(
              (ref) => Stream.value([
                selectedBookmark,
                otherBookmark,
                sameConversationInOtherWorkspace,
              ]),
            ),
          ],
          workspaceId: 'local',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Selected conversation message'), findsOneWidget);
    expect(find.text('Other conversation message'), findsNothing);
    expect(find.text('Other workspace message'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
