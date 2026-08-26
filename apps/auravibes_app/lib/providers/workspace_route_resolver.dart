import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:collection/collection.dart';

/// Resolves workspace-aware routes and legacy locations.
abstract final class WorkspaceRouteResolver {
  /// Returns the workspace id encoded in a route, if present.
  static String? matchWorkspaceId(Uri uri) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) return null;
    if (pathSegments.firstOrNull != 'workspaces') return null;

    return pathSegments[1];
  }

  /// Resolves redirects for workspace selection and legacy routes.
  static String? resolveWorkspaceRedirect(
    Uri currentUri,
    List<WorkspaceEntity> workspaces, {
    String? savedWorkspaceId,
  }) {
    final workspaceMatch = matchWorkspaceId(currentUri);
    final firstWorkspaceId = workspaces.firstOrNull?.id;
    final savedWorkspace = workspaces.firstWhereOrNull(
      (workspace) => workspace.id == savedWorkspaceId,
    );
    if (firstWorkspaceId == null) {
      return currentUri.path == introPath ? null : introPath;
    }

    final fallbackWorkspaceId = savedWorkspace?.id ?? firstWorkspaceId;
    if (currentUri.path == introPath) {
      return NewChatRoute(workspaceId: fallbackWorkspaceId).location;
    }
    if (workspaceMatch == null) {
      return _mapLegacyRoute(
            currentUri,
            fallbackWorkspaceId: fallbackWorkspaceId,
          ) ??
          NewChatRoute(workspaceId: fallbackWorkspaceId).location;
    }
    if (workspaces.any((workspace) => workspace.id == workspaceMatch)) {
      return null;
    }

    return NewChatRoute(workspaceId: firstWorkspaceId).location;
  }

  static String? _mapLegacyRoute(
    Uri uri, {
    required String fallbackWorkspaceId,
  }) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return null;

    final location = switch (pathSegments) {
      ['chat', 'new'] => NewChatRoute(
        workspaceId: fallbackWorkspaceId,
      ).location,
      ['chats'] => ChatsRoute(workspaceId: fallbackWorkspaceId).location,
      ['chats', final chatId] => ConversationRoute(
        workspaceId: fallbackWorkspaceId,
        chatId: chatId,
      ).location,
      ['tools'] => ToolsRoute(workspaceId: fallbackWorkspaceId).location,
      ['models'] => ServiceConnectionsRoute(
        workspaceId: fallbackWorkspaceId,
      ).location,
      ['service-connections'] => ServiceConnectionsRoute(
        workspaceId: fallbackWorkspaceId,
      ).location,
      ['settings'] => SettingsRoute(workspaceId: fallbackWorkspaceId).location,
      _ => null,
    };
    if (location == null) return null;
    if (!uri.hasQuery && uri.fragment.isEmpty) return location;

    return Uri.parse(
      location,
    ).replace(query: uri.query, fragment: uri.fragment).toString();
  }
}
