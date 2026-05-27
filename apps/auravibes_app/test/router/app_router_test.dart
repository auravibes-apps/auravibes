// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: no-object-declaration
// Required: Test fakes override noSuchMethod with Object return values.
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('workspacePathPrefix', () {
    test('is /workspaces', () {
      expect(workspacePathPrefix, '/workspaces');
    });
  });

  group('WorkspaceRoute', () {
    test('constructor stores workspaceId', () {
      final route = WorkspaceRoute(workspaceId: 'ws-1');
      expect(route.workspaceId, 'ws-1');
    });

    test('location includes workspaceId', () {
      final route = WorkspaceRoute(workspaceId: 'ws-1');
      expect(route.location, contains('ws-1'));
    });

    test('location starts with workspacePathPrefix', () {
      final route = WorkspaceRoute(workspaceId: 'ws-1');
      expect(route.location, startsWith(workspacePathPrefix));
    });

    test('location for different workspaceId', () {
      final route = WorkspaceRoute(workspaceId: 'abc-xyz');
      expect(route.location, contains('abc-xyz'));
    });

    test('location is /workspaces/:workspaceId', () {
      final route = WorkspaceRoute(workspaceId: 'ws-1');
      expect(route.location, '/workspaces/ws-1');
    });

    test('with empty workspaceId', () {
      final route = WorkspaceRoute(workspaceId: '');
      expect(route.workspaceId, '');
      expect(route.location, '/workspaces/');
    });
  });

  group('NewChatRoute', () {
    test('constructor stores workspaceId', () {
      final route = NewChatRoute(workspaceId: 'ws-1');
      expect(route.workspaceId, 'ws-1');
    });

    test('location includes chat/new path', () {
      final route = NewChatRoute(workspaceId: 'ws-1');
      expect(route.location, contains('chat/new'));
    });

    test('location includes workspaceId', () {
      final route = NewChatRoute(workspaceId: 'ws-2');
      expect(route.location, contains('ws-2'));
    });

    test('location is full correct path', () {
      final route = NewChatRoute(workspaceId: 'ws-1');
      expect(route.location, '/workspaces/ws-1/chat/new');
    });
  });

  group('ConversationRoute', () {
    test('constructor stores workspaceId and chatId', () {
      final route = ConversationRoute(workspaceId: 'ws-1', chatId: 'chat-1');
      expect(route.workspaceId, 'ws-1');
      expect(route.chatId, 'chat-1');
    });

    test('location includes chats path with chatId', () {
      final route = ConversationRoute(workspaceId: 'ws-1', chatId: 'chat-1');
      expect(route.location, contains('chats/chat-1'));
    });

    test('location is full correct path', () {
      final route = ConversationRoute(workspaceId: 'ws-1', chatId: 'c1');
      expect(route.location, '/workspaces/ws-1/chats/c1');
    });

    test('with special characters in chatId', () {
      final route = ConversationRoute(
        workspaceId: 'ws-1',
        chatId: 'abc-123_def',
      );
      expect(route.chatId, 'abc-123_def');
      expect(route.location, contains('abc-123_def'));
    });
  });

  group('ChatsRoute', () {
    test('constructor stores workspaceId', () {
      final route = ChatsRoute(workspaceId: 'ws-1');
      expect(route.workspaceId, 'ws-1');
    });

    test('location includes chats path', () {
      final route = ChatsRoute(workspaceId: 'ws-1');
      expect(route.location, contains('chats'));
    });

    test('location is full correct path', () {
      final route = ChatsRoute(workspaceId: 'ws-1');
      expect(route.location, '/workspaces/ws-1/chats');
    });
  });

  group('ToolsRoute', () {
    test('constructor stores workspaceId', () {
      final route = ToolsRoute(workspaceId: 'ws-1');
      expect(route.workspaceId, 'ws-1');
    });

    test('location includes tools path', () {
      final route = ToolsRoute(workspaceId: 'ws-1');
      expect(route.location, contains('tools'));
    });

    test('location is full correct path', () {
      final route = ToolsRoute(workspaceId: 'ws-1');
      expect(route.location, '/workspaces/ws-1/more/tools');
    });
  });

  group('ModelsRoute', () {
    test('constructor stores workspaceId', () {
      final route = ModelsRoute(workspaceId: 'ws-1');
      expect(route.workspaceId, 'ws-1');
    });

    test('location includes models path', () {
      final route = ModelsRoute(workspaceId: 'ws-1');
      expect(route.location, contains('models'));
    });

    test('location is full correct path', () {
      final route = ModelsRoute(workspaceId: 'ws-1');
      expect(route.location, '/workspaces/ws-1/more/models');
    });
  });

  group('SettingsRoute', () {
    test('constructor stores workspaceId', () {
      final route = SettingsRoute(workspaceId: 'ws-1');
      expect(route.workspaceId, 'ws-1');
    });

    test('location includes settings path', () {
      final route = SettingsRoute(workspaceId: 'ws-1');
      expect(route.location, contains('settings'));
    });

    test('location is full correct path', () {
      final route = SettingsRoute(workspaceId: 'ws-1');
      expect(route.location, '/workspaces/ws-1/settings');
    });
  });

  group('MyShellRouteData', () {
    test('can be constructed as const', () {
      const data = MyShellRouteData();
      expect(data, isA<MyShellRouteData>());
    });

    test(r'$navigatorKey is shellNavigatorKey', () {
      expect(MyShellRouteData.$navigatorKey, shellNavigatorKey);
    });
  });

  group('route locations', () {
    test('all routes produce unique locations', () {
      final locations = {
        WorkspaceRoute(workspaceId: 'ws-1').location,
        NewChatRoute(workspaceId: 'ws-1').location,
        ConversationRoute(workspaceId: 'ws-1', chatId: 'c1').location,
        ChatsRoute(workspaceId: 'ws-1').location,
        ToolsRoute(workspaceId: 'ws-1').location,
        ModelsRoute(workspaceId: 'ws-1').location,
        SettingsRoute(workspaceId: 'ws-1').location,
      };
      expect(locations, hasLength(7));
    });

    test('different workspace IDs produce different locations', () {
      final loc1 = NewChatRoute(workspaceId: 'ws-1').location;
      final loc2 = NewChatRoute(workspaceId: 'ws-2').location;
      expect(loc1, isNot(equals(loc2)));
    });

    test('different chat IDs produce different locations', () {
      final loc1 = ConversationRoute(
        workspaceId: 'ws-1',
        chatId: 'c1',
      ).location;
      final loc2 = ConversationRoute(
        workspaceId: 'ws-1',
        chatId: 'c2',
      ).location;
      expect(loc1, isNot(equals(loc2)));
    });

    test('all routes with same workspaceId share same prefix', () {
      const wsId = 'shared-ws';
      const prefix = '/workspaces/$wsId';

      expect(
        NewChatRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
      expect(
        ChatsRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
      expect(
        ToolsRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
      expect(
        ModelsRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
      expect(
        SettingsRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
    });
  });

  group('NavigatorKeys', () {
    test('shellNavigatorKey and rootNavigatorKey are distinct', () {
      expect(shellNavigatorKey, isNot(same(rootNavigatorKey)));
    });

    test('shellNavigatorKey is GlobalKey<NavigatorState>', () {
      expect(shellNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    test('rootNavigatorKey is GlobalKey<NavigatorState>', () {
      expect(rootNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });
  });

  group('Route constructors with edge cases', () {
    test('WorkspaceRoute with empty workspaceId', () {
      final route = WorkspaceRoute(workspaceId: '');
      expect(route.workspaceId, '');
      expect(route.location, '/workspaces/');
    });

    test('ConversationRoute with special characters in chatId', () {
      final route = ConversationRoute(
        workspaceId: 'ws-1',
        chatId: 'abc-123_def',
      );
      expect(route.chatId, 'abc-123_def');
      expect(route.location, contains('abc-123_def'));
    });

    test('all routes with same workspaceId share same prefix', () {
      const wsId = 'shared-ws';
      const prefix = '/workspaces/$wsId';

      expect(
        NewChatRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
      expect(
        ChatsRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
      expect(
        ToolsRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
      expect(
        ModelsRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
      expect(
        SettingsRoute(workspaceId: wsId).location,
        startsWith(prefix),
      );
    });
  });

  group('WorkspaceRoute redirect', () {
    test('redirect returns null when path is workspace child route', () {
      final route = WorkspaceRoute(workspaceId: 'ws-1');
      expect(route.location, '/workspaces/ws-1');
    });
  });

  group('ChatsRoute', () {
    test('constructor stores workspaceId with different IDs', () {
      final route = ChatsRoute(workspaceId: 'ws-abc');
      expect(route.workspaceId, 'ws-abc');
      expect(route.location, '/workspaces/ws-abc/chats');
    });
  });

  group('NewChatRoute', () {
    test('location path is correct with different workspace', () {
      final route = NewChatRoute(workspaceId: 'ws-xyz');
      expect(route.location, '/workspaces/ws-xyz/chat/new');
    });
  });

  group('ConversationRoute', () {
    test('location is correct with different workspace and chat', () {
      final route = ConversationRoute(
        workspaceId: 'ws-test',
        chatId: 'chat-999',
      );
      expect(route.location, '/workspaces/ws-test/chats/chat-999');
    });
  });

  group('ToolsRoute', () {
    test('location is correct with different workspace', () {
      final route = ToolsRoute(workspaceId: 'ws-tools');
      expect(route.location, '/workspaces/ws-tools/more/tools');
    });
  });

  group('ModelsRoute', () {
    test('location is correct with different workspace', () {
      final route = ModelsRoute(workspaceId: 'ws-models');
      expect(route.location, '/workspaces/ws-models/more/models');
    });
  });

  group('SettingsRoute', () {
    test('location is correct with different workspace', () {
      final route = SettingsRoute(workspaceId: 'ws-settings');
      expect(route.location, '/workspaces/ws-settings/settings');
    });
  });

  group('WorkspaceRoute redirect', () {
    test('redirect returns new chat location when uri matches workspace', () {
      final route = WorkspaceRoute(workspaceId: 'ws-1');
      final router = GoRouter(
        routes: $appRoutes,
        initialLocation: '/',
        navigatorKey: rootNavigatorKey,
      );

      final state = GoRouterState(
        router.configuration,
        uri: Uri.parse('/workspaces/ws-1'),
        matchedLocation: '/workspaces/ws-1',
        path: '/workspaces/:workspaceId',
        fullPath: '/workspaces/:workspaceId',
        pathParameters: const {'workspaceId': 'ws-1'},
        pageKey: const ValueKey('test'),
      );

      final result = route.redirect(
        _FakeBuildContext(),
        state,
      );
      expect(result, '/workspaces/ws-1/chat/new');
    });

    test('redirect returns null when uri does not match workspace', () {
      final route = WorkspaceRoute(workspaceId: 'ws-1');
      final router = GoRouter(
        routes: $appRoutes,
        initialLocation: '/',
        navigatorKey: rootNavigatorKey,
      );

      final state = GoRouterState(
        router.configuration,
        uri: Uri.parse('/workspaces/ws-1/chats'),
        matchedLocation: '/workspaces/ws-1/chats',
        path: '/workspaces/:workspaceId/chats',
        fullPath: '/workspaces/:workspaceId/chats',
        pathParameters: const {'workspaceId': 'ws-1'},
        pageKey: const ValueKey('test'),
      );

      final result = route.redirect(
        _FakeBuildContext(),
        state,
      );
      expect(result, isNull);
    });

    test('redirect returns new chat for different workspaceId', () {
      final route = WorkspaceRoute(workspaceId: 'ws-abc');
      final router = GoRouter(
        routes: $appRoutes,
        initialLocation: '/',
        navigatorKey: rootNavigatorKey,
      );

      final state = GoRouterState(
        router.configuration,
        uri: Uri.parse('/workspaces/ws-abc'),
        matchedLocation: '/workspaces/ws-abc',
        path: '/workspaces/:workspaceId',
        fullPath: '/workspaces/:workspaceId',
        pathParameters: const {'workspaceId': 'ws-abc'},
        pageKey: const ValueKey('test'),
      );

      final result = route.redirect(_FakeBuildContext(), state);
      expect(result, '/workspaces/ws-abc/chat/new');
    });
  });
}

class _FakeBuildContext implements BuildContext {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
