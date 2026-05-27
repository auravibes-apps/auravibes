// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.

import 'package:auravibes_app/providers/router_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchWorkspaceId additional', () {
    test('handles URI with only workspaces segment', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces')),
        isNull,
      );
    });

    test('handles URI with encoded characters', () {
      expect(
        matchWorkspaceId(Uri.parse('/workspaces/ws%20space/chats')),
        'ws space',
      );
    });
  });

  group('_mapLegacyRoute logic', () {
    test('maps chat/new to NewChatRoute', () {
      final result = mapLegacyRoute(
        Uri.parse('/chat/new'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, '/workspaces/ws-1/chat/new');
    });

    test('maps chats to ChatsRoute', () {
      final result = mapLegacyRoute(
        Uri.parse('/chats'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, '/workspaces/ws-1/chats');
    });

    test('maps chats/:chatId to ConversationRoute', () {
      final result = mapLegacyRoute(
        Uri.parse('/chats/chat-123'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, '/workspaces/ws-1/chats/chat-123');
    });

    test('maps tools to ToolsRoute', () {
      final result = mapLegacyRoute(
        Uri.parse('/tools'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, '/workspaces/ws-1/tools');
    });

    test('maps models to ModelsRoute', () {
      final result = mapLegacyRoute(
        Uri.parse('/models'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, '/workspaces/ws-1/models');
    });

    test('maps settings to SettingsRoute', () {
      final result = mapLegacyRoute(
        Uri.parse('/settings'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, '/workspaces/ws-1/settings');
    });

    test('returns null for unknown paths', () {
      final result = mapLegacyRoute(
        Uri.parse('/unknown/path'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, isNull);
    });

    test('returns null for empty path', () {
      final result = mapLegacyRoute(
        Uri.parse('/'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, isNull);
    });

    test('preserves query parameters', () {
      final result = mapLegacyRoute(
        Uri.parse('/chat/new?tab=open'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, contains('tab=open'));
    });

    test('preserves fragment', () {
      final result = mapLegacyRoute(
        Uri.parse('/tools#section'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, contains('#section'));
    });

    test('preserves both query and fragment', () {
      final result = mapLegacyRoute(
        Uri.parse('/models?type=gpt#top'),
        fallbackWorkspaceId: 'ws-1',
      );
      expect(result, contains('type=gpt'));
      expect(result, contains('#top'));
    });
  });
}

String? mapLegacyRoute(Uri uri, {required String fallbackWorkspaceId}) {
  final pathSegments = uri.pathSegments;

  if (pathSegments.isEmpty) {
    return null;
  }

  final location = switch (pathSegments) {
    ['chat', 'new'] => '/workspaces/$fallbackWorkspaceId/chat/new',
    ['chats'] => '/workspaces/$fallbackWorkspaceId/chats',
    ['chats', final chatId] => '/workspaces/$fallbackWorkspaceId/chats/$chatId',
    ['tools'] => '/workspaces/$fallbackWorkspaceId/tools',
    ['models'] => '/workspaces/$fallbackWorkspaceId/models',
    ['settings'] => '/workspaces/$fallbackWorkspaceId/settings',
    _ => null,
  };

  if (location == null) {
    return null;
  }

  if (!uri.hasQuery && uri.fragment.isEmpty) {
    return location;
  }

  return Uri.parse(
    location,
  ).replace(query: uri.query, fragment: uri.fragment).toString();
}
