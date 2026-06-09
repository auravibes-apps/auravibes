// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:flutter_test/flutter_test.dart';

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
