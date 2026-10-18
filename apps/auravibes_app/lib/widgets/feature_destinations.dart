import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/feature_destination_shell_scope.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef FeatureNavigationDestination = ({String labelKey, String location});
typedef FeatureDestinationNavigationRequest = ({
  BuildContext context,
  WidgetRef ref,
  ValueNotifier<bool> pending,
  String currentLocation,
  String location,
  bool push,
});

abstract final class FeatureDestinations {
  static const _listQuery = 'destinationList';

  static String masterLocation(String location) {
    final uri = Uri.parse(location);

    return uri
        .replace(queryParameters: {...uri.queryParameters, _listQuery: 'true'})
        .toString();
  }

  static bool isMasterLocation(Uri uri) =>
      uri.queryParameters[_listQuery] == 'true';

  static Future<T?> push<T>(BuildContext context, String location) {
    final router = GoRouter.of(context);
    final featureShell = FeatureDestinationShellScope.maybeOf(context);
    final returnLocation = currentUri(context) ?? router.state.uri;

    return router.push<T>(
      location,
      extra: _FeatureDestinationNavigation._stackPush(
        featureShell,
        returnLocation,
      ),
    );
  }

  static Uri? currentUri(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return null;
    final route = ModalRoute.of(context);
    if (route?.settings is Page) return GoRouterState.of(context).uri;

    return router.state.uri;
  }

  static List<FeatureNavigationDestination> connections(String workspaceId) => [
    for (final destination in const [
      ConnectionDestination.overview,
      ConnectionDestination.providers,
      ConnectionDestination.services,
      ConnectionDestination.tools,
      ConnectionDestination.credentials,
    ])
      (
        labelKey: switch (destination) {
          .overview => LocaleKeys.related_lists_overview,
          .providers => LocaleKeys.related_lists_providers,
          .services => LocaleKeys.related_lists_services,
          .tools => LocaleKeys.related_lists_tools,
          .credentials => LocaleKeys.related_lists_credentials,
        },
        location: connectionLocation(workspaceId, destination),
      ),
  ];

  static List<FeatureNavigationDestination> agents(String workspaceId) => [
    (
      labelKey: LocaleKeys.related_lists_agents,
      location: AgentsRoute(workspaceId: workspaceId).location,
    ),
    (
      labelKey: LocaleKeys.related_lists_skills,
      location: SkillsRoute(workspaceId: workspaceId).location,
    ),
  ];

  static String connectionLocation(
    String workspaceId,
    ConnectionDestination destination,
  ) => switch (destination) {
    .tools => ToolsRoute(workspaceId: workspaceId).location,
    .overview => ServiceConnectionsRoute(workspaceId: workspaceId).location,
    _ => ServiceConnectionsRoute(
      workspaceId: workspaceId,
      view: destination.name,
    ).location,
  };

  static Future<void> navigate(FeatureDestinationNavigationRequest request) =>
      _FeatureDestinationNavigation.navigate(request);
}

abstract final class _FeatureDestinationNavigation {
  static Future<void> navigate(
    FeatureDestinationNavigationRequest request,
  ) async {
    if (_shouldSkip(request)) return;
    request.pending.value = true;
    final router = GoRouter.of(request.context);
    final registry = request.ref.read(draftExitRegistryProvider);
    try {
      await _approveAndNavigate(request, router, registry);
    } finally {
      if (request.context.mounted) request.pending.value = false;
    }
  }

  static bool _shouldSkip(FeatureDestinationNavigationRequest request) =>
      request.pending.value || request.currentLocation == request.location;

  static Future<void> _approveAndNavigate(
    FeatureDestinationNavigationRequest request,
    GoRouter router,
    DraftExitRegistry registry,
  ) async {
    final canExit = await registry.canExitActive(router);
    if (canExit && request.context.mounted) {
      _navigateToDestination(request, router);

      return;
    }
    registry.releaseApprovals();
  }

  static FeatureDestinationStackPush _stackPush(
    FeatureDestinationShellScope? featureShell,
    Uri returnLocation,
  ) => FeatureDestinationStackPush(
    returnLocation: returnLocation.toString(),
    sourceNavigatorKey: featureShell?.navigatorKey,
    parentNavigatorKey: featureShell?.parentNavigatorKey,
  );

  static void _navigateToDestination(
    FeatureDestinationNavigationRequest request,
    GoRouter router,
  ) {
    if (request.push ||
        FeatureDestinations.isMasterLocation(.parse(request.currentLocation))) {
      _pushDestination(router, request.location);

      return;
    }
    if (_replaceInsideShell(request.context, router, request.location)) return;
    router.go(request.location);
  }

  static void _pushDestination(GoRouter router, String location) => unawaited(
    router.push<void>(location, extra: const FeatureDestinationStackPush()),
  );

  static bool _replaceInsideShell(
    BuildContext context,
    GoRouter router,
    String location,
  ) {
    if (FeatureDestinationShellScope.maybeOf(context) == null) return false;
    unawaited(
      router.replace<void>(
        location,
        extra: const FeatureDestinationStackPush(),
      ),
    );

    return true;
  }
}
