// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/features/workspaces/usecases/resolve_workspace_selection_usecase.dart';
import 'package:auravibes_app/providers/workspace_route_resolver.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/change_notifier_with_code_gen_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'workspace_route_resolver.dart';

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
    observers: [routeObserver],
    navigatorKey: rootNavigatorKey,
  );
}

final routerInformationProvider = Provider<GoRouteInformationProvider>((ref) {
  final router = ref.watch(routerProvider);

  return ref.listenAndDisposeChangeNotifier(router.routeInformationProvider);
});

final currentRouteWorkspaceIdProvider = Provider<String?>((ref) {
  final _ = ref.watch(routerProvider);
  final routeInformationProvider = ref.watch(routerInformationProvider);

  return WorkspaceRouteResolver.matchWorkspaceId(
    routeInformationProvider.value.uri,
  );
});

// Top-level API/provider declarations are required by their consumers.
