import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
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
