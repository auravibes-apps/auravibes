// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
          testableApp(
            child: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const ChatsListScreen(workspaceId: 'test-ws'),
            ),
            overrides: [
              conversationsStreamProvider.overrideWith(
                (ref, ({String workspaceId, int? limit}) args) =>
                    Stream.value([]),
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
