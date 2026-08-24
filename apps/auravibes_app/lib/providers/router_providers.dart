// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/usecases/resolve_workspace_selection_usecase.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/change_notifier_with_code_gen_extension.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_providers.g.dart';

/// Global route observer for listening to navigation events across the app.
///
/// This observer allows widgets to react to route changes, such as when
/// navigating between conversations within the same branch.
final routeObserverProvider = Provider<RouteObserver<ModalRoute<void>>>(
  (ref) => RouteObserver<ModalRoute<void>>(),
);

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final routeObserver = ref.read(routeObserverProvider);

  return GoRouter(
    routes: $appRoutes,
    redirect: (context, state) async {
      final selection = await ref
          .read(resolveWorkspaceSelectionUsecaseProvider)
          .call();

      if (selection == null) return null;

      return WorkspaceRouteResolver.resolveWorkspaceRedirect(
        state.uri,
        selection.workspaces,
        savedWorkspaceId: selection.savedWorkspaceId,
      );
    },
    initialLocation: '/',
    observers: [
      routeObserver,
    ],
    navigatorKey: rootNavigatorKey,
  );
}

final routerInformationProvider = Provider<GoRouteInformationProvider>(
  (ref) {
    final router = ref.watch(routerProvider);

    return ref.listenAndDisposeChangeNotifier(router.routeInformationProvider);
  },
);

final currentRouteWorkspaceIdProvider = Provider<String?>(
  (ref) {
    final _ = ref.watch(routerProvider);
    final routeInformationProvider = ref.watch(routerInformationProvider);

    return WorkspaceRouteResolver.matchWorkspaceId(
      routeInformationProvider.value.uri,
    );
  },
);

abstract final class WorkspaceRouteResolver {
  static String? matchWorkspaceId(Uri uri) {
    final pathSegments = uri.pathSegments;

    if (pathSegments.length < 2) {
      return null;
    }

    if (pathSegments.firstOrNull != 'workspaces') {
      return null;
    }

    return pathSegments[1];
  }

  @visibleForTesting
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
      if (currentUri.path == introPath) {
        return null;
      }

      return introPath;
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

    if (pathSegments.isEmpty) {
      return null;
    }

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
}
// Top-level API/provider declarations are required by their consumers.
