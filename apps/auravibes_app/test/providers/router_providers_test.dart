import 'package:auravibes_app/providers/router_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('matchWorkspaceId', () {
    test('returns null for root path', () {
      expect(matchWorkspaceId(Uri.parse('/')), isNull);
    });

    test('returns null for non-workspace path', () {
      expect(matchWorkspaceId(Uri.parse('/chat/new')), isNull);
    });

    test('returns null for single segment', () {
      expect(matchWorkspaceId(Uri.parse('/workspaces')), isNull);
    });

    test('returns workspace ID for valid workspace URL', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces/ws-123/chats')),
        'ws-123',
      );
    });

    test('returns workspace ID for deeply nested paths', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces/ws-456/chats/chat-789')),
        'ws-456',
      );
    });

    test('handles workspace ID with special characters', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces/ws_abc-123/tools')),
        'ws_abc-123',
      );
    });

    test('returns null for empty path segments', () {
      expect(matchWorkspaceId(Uri.parse('')), isNull);
    });

    test('returns null when first segment is not workspaces', () {
      expect(
        matchWorkspaceId(Uri.parse('/chats/ws-123')),
        isNull,
      );
    });

    test('returns workspace ID with only two segments', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces/ws-abc')),
        'ws-abc',
      );
    });

    test('handles URI with query parameters', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces/ws-1/chats?tab=open')),
        'ws-1',
      );
    });

    test('handles URI with fragment', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces/ws-1/tools#section')),
        'ws-1',
      );
    });

    test('returns first workspace ID segment even with many segments', () {
      expect(
        matchWorkspaceId(
          Uri.parse('/workspaces/ws-first/a/b/c/d/e'),
        ),
        'ws-first',
      );
    });
  });

  group('routeObserverProvider', () {
    test('returns a RouteObserver instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final observer = container.read(routeObserverProvider);
      expect(observer, isA<RouteObserver<ModalRoute<void>>>());
    });

    test('returns same instance on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(routeObserverProvider);
      final second = container.read(routeObserverProvider);
      expect(identical(first, second), isTrue);
    });
  });

  group('routerProvider', () {
    test('returns a GoRouter instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(router, isA<GoRouter>());
    });

    test('router has routes configured', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(router, isNotNull);
      expect(router.configuration.routes, isNotEmpty);
    });

    test('router has initial location as root', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(router.routeInformationProvider.value.uri.path, '/');
    });

    test('router uses rootNavigatorKey', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(router.configuration.navigatorKey, isNotNull);
    });
  });

  group('routerInformationProvider', () {
    test('returns a GoRouteInformationProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(routerInformationProvider);
      expect(provider, isA<GoRouteInformationProvider>());
    });

    test('has a value with uri', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(routerInformationProvider);
      expect(provider.value.uri, isNotNull);
    });
  });

  group('routerPathSegmentsProvider', () {
    test('returns a list of strings', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final segments = container.read(routerPathSegmentsProvider);
      expect(segments, isA<List<String>>());
    });

    test('returns path segments from initial location', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final segments = container.read(routerPathSegmentsProvider);
      expect(segments, isA<List>());
    });
  });

  group('currentRouteWorkspaceIdProvider', () {
    test('returns null for root path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workspaceId = container.read(currentRouteWorkspaceIdProvider);
      expect(workspaceId, isNull);
    });

    test('returns null for non-workspace segments', () {
      final container = ProviderContainer(
        overrides: [
          routerPathSegmentsProvider.overrideWithValue([
            'chat',
            'new',
          ]),
        ],
      );
      addTearDown(container.dispose);

      final workspaceId = container.read(currentRouteWorkspaceIdProvider);
      expect(workspaceId, isNull);
    });

    test('returns null for insufficient segments', () {
      final container = ProviderContainer(
        overrides: [
          routerPathSegmentsProvider.overrideWithValue([
            'workspaces',
          ]),
        ],
      );
      addTearDown(container.dispose);

      final workspaceId = container.read(currentRouteWorkspaceIdProvider);
      expect(workspaceId, isNull);
    });

    test('returns null when first segment is not workspaces', () {
      final container = ProviderContainer(
        overrides: [
          routerPathSegmentsProvider.overrideWithValue([
            'tools',
            'ws-42',
          ]),
        ],
      );
      addTearDown(container.dispose);

      final workspaceId = container.read(currentRouteWorkspaceIdProvider);
      expect(workspaceId, isNull);
    });

    test('returns workspaceId when segments match workspace path', () {
      final container = ProviderContainer(
        overrides: [
          routerInformationProvider.overrideWithValue(
            GoRouteInformationProvider(
              initialLocation: '/workspaces/ws-99/chats',
              initialExtra: null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final workspaceId = container.read(currentRouteWorkspaceIdProvider);
      expect(workspaceId, 'ws-99');
    });

    test('returns workspaceId with only two segments', () {
      final container = ProviderContainer(
        overrides: [
          routerInformationProvider.overrideWithValue(
            GoRouteInformationProvider(
              initialLocation: '/workspaces/ws-abc',
              initialExtra: null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final workspaceId = container.read(currentRouteWorkspaceIdProvider);
      expect(workspaceId, 'ws-abc');
    });
  });

  group('routerInformationProvider', () {
    test('provider value uri path starts with /', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(routerInformationProvider);
      expect(provider.value.uri.path, startsWith('/'));
    });
  });

  group('matchWorkspaceId additional edge cases', () {
    test('returns workspace ID for minimal valid URI', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces/abc')),
        'abc',
      );
    });

    test('returns null for deeply nested non-workspace path', () {
      expect(
        matchWorkspaceId(Uri.parse('/other/ws-1/deep/path')),
        isNull,
      );
    });

    test('returns workspace ID when trailing slash present', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces/ws-1/')),
        'ws-1',
      );
    });
  });
}
