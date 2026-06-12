// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/change_notifier_with_code_gen_extension.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

/// Global route observer for listening to navigation events across the app.
///
/// This observer allows widgets to react to route changes, such as when
/// navigating between conversations within the same branch.
final routeObserverProvider = Provider<RouteObserver<ModalRoute<void>>>(
  (ref) => RouteObserver<ModalRoute<void>>(),
);

final _logger = Logger('routerProvider');

final routerProvider = Provider<GoRouter>(
  (ref) {
    final routeObserver = ref.read(routeObserverProvider);

    return GoRouter(
      routes: $appRoutes,
      redirect: (context, state) async {
        final workspaces = await ref
            .read(workspaceRepositoryProvider)
            .getAllWorkspaces()
            .onError(
              (error, stackTrace) {
                _logger.severe(
                  'Failed to load workspaces for router redirect',
                  error,
                  stackTrace,
                );

                return [];
              },
            );

        return resolveWorkspaceRedirect(state.uri, workspaces);
      },
      initialLocation: '/',
      observers: [
        routeObserver,
      ],
      navigatorKey: rootNavigatorKey,
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
    final _ = ref.watch(routerProvider);
    final routeInformationProvider = ref.watch(routerInformationProvider);

    return routeInformationProvider.value.uri.pathSegments;
  },
);

final currentRouteWorkspaceIdProvider = Provider<String?>(
  (ref) {
    final _ = ref.watch(routerProvider);
    final routeInformationProvider = ref.watch(routerInformationProvider);

    return matchWorkspaceId(routeInformationProvider.value.uri);
  },
);

String? matchWorkspaceId(Uri uri) {
  final pathSegments = uri.pathSegments;

  if (pathSegments.length < 2) {
    return null;
  }

  if (pathSegments.firstOrNull != 'workspaces') {
    return null;
  }

  return pathSegments[1];
}

String? resolveWorkspaceRedirect(
  Uri currentUri,
  List<WorkspaceEntity> workspaces,
) {
  final workspaceMatch = matchWorkspaceId(currentUri);
  final firstWorkspaceId = workspaces.firstOrNull?.id;

  if (firstWorkspaceId == null) {
    if (currentUri.path == introPath) {
      return null;
    }

    return introPath;
  }

  if (currentUri.path == introPath) {
    return NewChatRoute(workspaceId: firstWorkspaceId).location;
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
    ['models'] => ServiceConnectionsRoute(
      workspaceId: fallbackWorkspaceId,
    ).location,
    ['service-connections'] => ServiceConnectionsRoute(
      workspaceId: fallbackWorkspaceId,
    ).location,
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
