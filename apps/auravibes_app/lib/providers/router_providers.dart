import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/utils/ref_extensions.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Global route observer for listening to navigation events across the app.
///
/// This observer allows widgets to react to route changes, such as when
/// navigating between conversations within the same branch.
final routeObserverProvider = Provider<RouteObserver<ModalRoute<void>>>(
  (ref) => RouteObserver<ModalRoute<void>>(),
);

final routerProvider = Provider<GoRouter>(
  (ref) {
    final routeObserver = ref.read(routeObserverProvider);

    return GoRouter(
      routes: $appRoutes,
      initialLocation: '/',
      navigatorKey: rootNavigatorKey,
      observers: [
        routeObserver,
      ],
      redirect: (context, state) async {
        final currentUri = state.uri;
        final workspaceMatch = matchWorkspaceId(currentUri);
        final workspaces = await ref.read(allWorkspacesProvider.future);
        final firstWorkspaceId = workspaces.firstOrNull?.id;

        if (firstWorkspaceId == null) {
          // No workspaces exist yet; let navigation proceed.
          // The UI should handle this case with an empty state.
          return null;
        }

        if (workspaceMatch == null) {
          return _mapLegacyRoute(
                currentUri,
                fallbackWorkspaceId: firstWorkspaceId,
              ) ??
              NewChatRoute(workspaceId: firstWorkspaceId).location;
        }

        if (workspaces.any((workspace) => workspace.id == workspaceMatch)) {
          return null;
        }

        return NewChatRoute(workspaceId: firstWorkspaceId).location;
      },
    );
  },
);

final routerInformationProvider = Provider<GoRouteInformationProvider>(
  (ref) {
    final router = ref.watch(routerProvider);

    return ref.listenAndDisposeChangeNotifier(router.routeInformationProvider);
  },
);

final routerPathSegmentsProvider = Provider<List<String>>(
  (ref) {
    ref.watch(routerProvider);
    final routeInformationProvider = ref.watch(routerInformationProvider);
    return routeInformationProvider.value.uri.pathSegments;
  },
);

final currentRouteWorkspaceIdProvider = Provider<String?>(
  (ref) {
    ref.watch(routerProvider);
    final routeInformationProvider = ref.watch(routerInformationProvider);
    return matchWorkspaceId(routeInformationProvider.value.uri);
  },
);

String? matchWorkspaceId(Uri uri) {
  final pathSegments = uri.pathSegments;

  if (pathSegments.length < 2) {
    return null;
  }

  if (pathSegments.first != 'workspaces') {
    return null;
  }

  return pathSegments[1];
}

String? _mapLegacyRoute(Uri uri, {required String fallbackWorkspaceId}) {
  final pathSegments = uri.pathSegments;

  if (pathSegments.isEmpty) {
    return null;
  }

  final location = switch (pathSegments) {
    ['chat', 'new'] => NewChatRoute(workspaceId: fallbackWorkspaceId).location,
    ['chats'] => ChatsRoute(workspaceId: fallbackWorkspaceId).location,
    ['chats', final chatId] => ConversationRoute(
      workspaceId: fallbackWorkspaceId,
      chatId: chatId,
    ).location,
    ['tools'] => ToolsRoute(workspaceId: fallbackWorkspaceId).location,
    ['models'] => ModelsRoute(workspaceId: fallbackWorkspaceId).location,
    ['settings'] => SettingsRoute(workspaceId: fallbackWorkspaceId).location,
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
