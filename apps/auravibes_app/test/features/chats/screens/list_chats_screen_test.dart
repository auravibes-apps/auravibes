import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../helpers/test_app.dart';

@Dependencies([
  workspaceModelSelectionById,
  workspaceSession,
  cloudWorkspaceStateGateway,
  serviceConnectionOperations,
  serviceConnections,
  ConversationChatNotifier,
  conversationBusyState,
  pendingToolCalls,
  contextUsage,
  chatMessages,
  childConversationsStream,
  conversationByIdStream,
  messageConversationById,
])
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
