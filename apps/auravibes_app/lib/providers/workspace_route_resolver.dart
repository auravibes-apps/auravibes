import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:collection/collection.dart';

const _workspacePathSegmentCount = 2;

/// Resolves workspace-aware routes and legacy locations.
abstract final class WorkspaceRouteResolver {
  /// Returns the workspace id encoded in a route, if present.
  static String? matchWorkspaceId(Uri uri) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < _workspacePathSegmentCount) return null;
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
    if (firstWorkspaceId == null) {
      return _redirectWithoutWorkspace(currentUri);
    }

    final fallbackWorkspaceId = _fallbackWorkspaceId(
      workspaces,
      firstWorkspaceId,
      savedWorkspaceId,
    );

    return _redirectForWorkspace(currentUri, (
      workspaces: workspaces,
      workspaceMatch: workspaceMatch,
      fallbackWorkspaceId: fallbackWorkspaceId,
      firstWorkspaceId: firstWorkspaceId,
    ));
  }

  static String _fallbackWorkspaceId(
    List<WorkspaceEntity> workspaces,
    String firstWorkspaceId,
    String? savedWorkspaceId,
  ) =>
      workspaces
          .firstWhereOrNull((workspace) => workspace.id == savedWorkspaceId)
          ?.id ??
      firstWorkspaceId;

  static String? _redirectForWorkspace(
    Uri currentUri,
    ({
      List<WorkspaceEntity> workspaces,
      String? workspaceMatch,
      String fallbackWorkspaceId,
      String firstWorkspaceId,
    })
    context,
  ) {
    if (currentUri.path == introPath) {
      return NewChatRoute(workspaceId: context.fallbackWorkspaceId).location;
    }
    if (context.workspaceMatch == null) {
      return _legacyRedirect(currentUri, context.fallbackWorkspaceId);
    }

    return context.workspaces.any(
          (workspace) => workspace.id == context.workspaceMatch,
        )
        ? null
        : NewChatRoute(workspaceId: context.firstWorkspaceId).location;
  }

  static String _legacyRedirect(Uri uri, String fallbackWorkspaceId) =>
      _mapLegacyRoute(uri, fallbackWorkspaceId: fallbackWorkspaceId) ??
      NewChatRoute(workspaceId: fallbackWorkspaceId).location;

  static String? _redirectWithoutWorkspace(Uri uri) {
    return uri.path == introPath ? null : introPath;
  }

  static String? _mapLegacyRoute(
    Uri uri, {
    required String fallbackWorkspaceId,
  }) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return null;

    final location = _legacyLocation(pathSegments, fallbackWorkspaceId);
    if (location == null) return null;

    return _preserveRouteSuffix(uri, location);
  }

  static String? _legacyLocation(
    List<String> pathSegments,
    String fallbackWorkspaceId,
  ) {
    if (pathSegments.length == _workspacePathSegmentCount) {
      final location = _twoSegmentLegacyLocation(
        pathSegments,
        fallbackWorkspaceId,
      );
      if (location != null) return location;
    }
    if (pathSegments.length != 1) return null;

    return _singleLegacyLocation(pathSegments.single, fallbackWorkspaceId);
  }

  static String? _singleLegacyLocation(
    String segment,
    String fallbackWorkspaceId,
  ) => switch (segment) {
    'chats' => ChatsRoute(workspaceId: fallbackWorkspaceId).location,
    'tools' => ToolsRoute(workspaceId: fallbackWorkspaceId).location,
    'models' => ServiceConnectionsRoute(
      workspaceId: fallbackWorkspaceId,
    ).location,
    'service-connections' => ServiceConnectionsRoute(
      workspaceId: fallbackWorkspaceId,
    ).location,
    'settings' => SettingsRoute(workspaceId: fallbackWorkspaceId).location,
    _ => null,
  };

  static String _preserveRouteSuffix(Uri uri, String location) {
    if (!uri.hasQuery && uri.fragment.isEmpty) return location;

    return Uri.parse(location)
        .replace(query: uri.query, fragment: uri.fragment)
        .toString();
  }
}

String? _twoSegmentLegacyLocation(
  List<String> pathSegments,
  String fallbackWorkspaceId,
) {
  if (pathSegments.firstOrNull == 'chat' && pathSegments.lastOrNull == 'new') {
    return NewChatRoute(workspaceId: fallbackWorkspaceId).location;
  }
  if (pathSegments.firstOrNull != 'chats') return null;
  final chatId = pathSegments.lastOrNull;
  if (chatId == null) return null;

  return ConversationRoute(
    workspaceId: fallbackWorkspaceId,
    chatId: chatId,
  ).location;
}
