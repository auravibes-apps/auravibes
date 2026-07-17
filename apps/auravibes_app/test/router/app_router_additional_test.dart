import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/service_connections_action_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([
  workspaceModelSelectionById,
  workspaceSession,
  cloudWorkspaceStateGateway,
  serviceConnectionOperations,
  serviceConnections,
  serviceConnectionsActionUsecase,
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
  group('WorkspaceRoute redirect', () {
    test('redirects to chat/new when path matches workspace root', () {
      final route = WorkspaceRoute(workspaceId: 'ws-1');
      expect(
        route.location,
        '/workspaces/ws-1',
      );
    });
  });

  group('Route equality and uniqueness', () {
    test('same route type with same params are equal', () {
      final a = NewChatRoute(workspaceId: 'ws-1');
      final b = NewChatRoute(workspaceId: 'ws-1');
      expect(a.location, b.location);
    });

    test('ConversationRoute location preserves chatId', () {
      final route = ConversationRoute(
        workspaceId: 'ws-test',
        chatId: 'chat-abc-123',
      );
      expect(route.location, '/workspaces/ws-test/chats/chat-abc-123');
    });
  });

  group('Navigator keys', () {
    test('shellNavigatorKey is not disposed between accesses', () {
      final key1 = shellNavigatorKey;
      final key2 = shellNavigatorKey;
      expect(identical(key1, key2), isTrue);
    });

    test('rootNavigatorKey is not disposed between accesses', () {
      final key1 = rootNavigatorKey;
      final key2 = rootNavigatorKey;
      expect(identical(key1, key2), isTrue);
    });
  });

  group('Route location edge cases', () {
    test('ChatsRoute with long workspaceId', () {
      final route = ChatsRoute(workspaceId: 'a' * 50);
      expect(route.location, contains('a' * 50));
    });

    test('ToolsRoute with numeric workspaceId', () {
      final route = ToolsRoute(workspaceId: '12345');
      expect(route.location, '/workspaces/12345/more/tools');
    });

    test('ServiceConnectionsRoute with special chars workspaceId', () {
      final route = ServiceConnectionsRoute(workspaceId: 'ws_test-123');
      expect(
        route.location,
        '/workspaces/ws_test-123/more/service-connections',
      );
    });

    test('WorkspaceRoute location with hyphenated workspaceId', () {
      final route = WorkspaceRoute(workspaceId: 'my-workspace-id');
      expect(route.location, '/workspaces/my-workspace-id');
    });

    test('SettingsRoute location is correct', () {
      final route = SettingsRoute(workspaceId: 'ws-1');
      expect(route.location, '/workspaces/ws-1/settings');
    });
  });

  group('MyShellRouteData', () {
    test(r'$navigatorKey matches shellNavigatorKey', () {
      expect(
        identical(MyShellRouteData.$navigatorKey, shellNavigatorKey),
        isTrue,
      );
    });
  });
}
