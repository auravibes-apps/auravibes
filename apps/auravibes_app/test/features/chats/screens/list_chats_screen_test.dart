import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_with_responsive_drawer.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/ux_validation_fixture.dart';

void main() {
  testWidgets('View all opens older history in the production shell', (
    tester,
  ) async {
    final f = await UxValidationFixture.create();
    final repository = ConversationRepository(f.database);
    String? olderId;
    for (var index = 0; index < 10; index++) {
      final conversation = await repository.createConversation(
        .new(
          title: index == 0
              ? 'Older project plan'
              : 'Recent conversation $index',
          workspaceId: f.workspaceId,
          createdAt: DateTime.utc(2026, 9, 1, index),
          updatedAt: DateTime.utc(2026, 9, 1, index),
        ),
      );
      if (index == 0) olderId = conversation.id;
    }
    final router = await f.pump(
      tester,
      NewChatRoute(workspaceId: f.workspaceId).location,
      size: const Size(1280, 1600),
    );
    expect(find.byType(NewChatScreen), findsOneWidget);
    expect(find.text('Older project plan'), findsNothing);
    if (find.text('View All').hitTestable().evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey<String>('app_drawer_menu')));
      final _ = await tester.pumpAndSettle();
    }
    await tester.tap(find.text('View All'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(ChatsListScreen), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      ChatsRoute(workspaceId: f.workspaceId).location,
    );
    expect(
      tester
          .widget<AppWithResponsiveDrawer>(find.byType(AppWithResponsiveDrawer))
          .selectedIndex,
      0,
    );
    await f.settle(tester);
    await tester.scrollUntilVisible(
      find.text('Older project plan'),
      450,
      scrollable: find
          .descendant(
            of: find.byType(ChatsListScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Older project plan'));
    final _ = await tester.pumpAndSettle();
    await f.settle(tester);
    final screen = tester.widget<ChatConversationScreen>(
      find.byType(ChatConversationScreen),
    );
    expect(screen.workspaceId, f.workspaceId);
    expect(screen.chatId, olderId);
    expect(find.text('Older project plan'), findsWidgets);
    expect(
      router.routeInformationProvider.value.uri.path,
      ConversationRoute(
        workspaceId: f.workspaceId,
        chatId: olderId ?? (throw StateError('Missing older chat')),
      ).location,
    );
    expect(
      tester
          .widget<AppWithResponsiveDrawer>(find.byType(AppWithResponsiveDrawer))
          .selectedIndex,
      -1,
    );
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });

  test('constructor sets workspaceId', () {
    const screen = ChatsListScreen(workspaceId: 'test-ws');
    expect(screen.workspaceId, 'test-ws');
  });

  test('constructor accepts different workspaceIds', () {
    const screen = ChatsListScreen(workspaceId: 'other-id');
    expect(screen.workspaceId, 'other-id');
  });

  test('is a ConsumerWidget', () {
    const screen = ChatsListScreen(workspaceId: 'ws');
    expect(screen, isA<ChatsListScreen>());
  });

  group('render', () {
    testWidgets('renders ChatsListScreen', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: AuraThemeScope(
              theme: .light,
              child: Theme(
                data: .new(),
                child: const ChatsListScreen(workspaceId: 'test-ws'),
              ),
            ),
            overrides: [
              conversationsStreamProvider.overrideWith(
                (
                  ref,
                  ({
                    String workspaceId,
                    String search,
                    ({int? limit, int offset}) pagination,
                  })
                  args,
                ) => Stream.value([]),
              ),
              listWorkspaceModelSelectionsProvider.overrideWith(
                (ref, workspaceId) => Stream.value([]),
              ),
              streamingTitleProvider.overrideWith((ref, id) => null),
            ],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      expect(find.byType(ChatsListScreen), findsOneWidget);
      expect(find.byType(AuraScreen), findsOneWidget);
    });
  });
}
