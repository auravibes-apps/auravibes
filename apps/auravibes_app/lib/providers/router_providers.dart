import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/utils/ref_extensions.dart';
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
      initialLocation: '/chat/new',
      navigatorKey: rootNavigatorKey,
      observers: [
        routeObserver,
      ],
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
    final router = ref.watch(routerProvider);
    ref.watch(routerInformationProvider);
    return router.state.uri.pathSegments;
  },
);
