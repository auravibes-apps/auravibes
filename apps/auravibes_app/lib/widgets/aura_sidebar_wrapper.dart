import 'dart:async';

import 'package:auravibes_app/features/workspaces/notifiers/workspace_navigation_notifier.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_with_responsive_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

export 'app_with_responsive_drawer.dart';

/// A sidebar widget that handles business logic and navigation state.
///
/// This widget manages the sidebar's expand/collapse state, responsive
/// behavior,
/// and navigation logic. It uses a hybrid approach:
/// - Desktop: Shows persistent collapsible sidebar
/// - Mobile: Uses Scaffold's drawer pattern for native platform behavior
/// It delegates the visual presentation to AuraSidebarOrganism
/// from the auravibes_ui package.

List<AuraNavigationData> _navigationItems(BuildContext context) => [
  _navigationItem(
    context,
    LocaleKeys.navigation_chats,
    const Icon(Icons.chat_outlined),
  ),
  _navigationItem(
    context,
    LocaleKeys.navigation_agents_skills,
    const Icon(Icons.smart_toy_outlined),
  ),
  _navigationItem(
    context,
    LocaleKeys.navigation_connections,
    const Icon(Icons.link),
  ),
  _navigationItem(
    context,
    LocaleKeys.settings_screen_title,
    const Icon(Icons.settings_outlined),
    footer: true,
  ),
  _navigationItem(
    context,
    LocaleKeys.cloud_accounts_title,
    const Icon(Icons.cloud_outlined),
    footer: true,
  ),
];

AuraNavigationData _navigationItem(
  BuildContext context,
  String translationKey,
  Widget icon, {
  bool footer = false,
}) => AuraNavigationData(
  icon: icon,
  label: TextLocale(translationKey),
  footer: footer,
  semanticLabel: translationKey.tr(context: context),
);

class AuraSidebarWrapper extends HookConsumerWidget {
  /// Creates a Aura sidebar widget.
  const new({
    required this.navigationShell,
    required this.workspaceId,
    super.key,
  });

  /// The main content to display next to the sidebar.
  final StatefulNavigationShell navigationShell;

  /// The current workspace ID from the route.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _SidebarNavigationContent(
        navigationShell: navigationShell,
        workspaceId: workspaceId,
      );
}

class _SidebarNavigationContent extends HookConsumerWidget {
  const new({required this.navigationShell, required this.workspaceId});

  final StatefulNavigationShell navigationShell;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final route = _useRememberedWorkspaceRoute((
      context: context,
      ref: ref,
      router: router,
      workspaceId: workspaceId,
    ));
    final pending = useState(false);

    return _SidebarNavigationView(
      navigationShell: navigationShell,
      workspaceId: workspaceId,
      route: route,
      tapOwner: (context: context, ref: ref, pending: pending),
    );
  }
}

class _SidebarNavigationView extends StatelessWidget {
  const new({
    required this.navigationShell,
    required this.workspaceId,
    required this.route,
    required this.tapOwner,
  });

  final StatefulNavigationShell navigationShell;
  final String workspaceId;
  final Uri route;
  final _NavigationTapOwner tapOwner;

  @override
  Widget build(BuildContext context) => AppWithResponsiveDrawer(
    child: navigationShell,
    navigationItems: _navigationItems(context),
    onNavigationTap: _navigationTapHandler(
      tapOwner,
      navigationShell,
      workspaceId,
    ),
    selectedIndex: _selectedNavigationIndex(route),
    workspaceId: workspaceId,
  );
}

typedef _WorkspaceRouteOwner = ({
  BuildContext context,
  WidgetRef ref,
  GoRouter router,
  String workspaceId,
});

Uri _useRememberedWorkspaceRoute(_WorkspaceRouteOwner owner) {
  final _ = useListenable(owner.router.routerDelegate);
  final route = owner.router.state.uri;
  useEffect(() => _rememberedRouteEffect(owner, route), [
    route,
    owner.workspaceId,
  ]);

  return route;
}

void Function()? _rememberedRouteEffect(_WorkspaceRouteOwner owner, Uri route) {
  _scheduleRememberedRoute(owner, route);

  return null;
}

void _scheduleRememberedRoute(_WorkspaceRouteOwner owner, Uri route) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _rememberWorkspaceRoute(owner, route);
  });
}

void _rememberWorkspaceRoute(_WorkspaceRouteOwner owner, Uri route) {
  if (!owner.context.mounted || owner.router.state.uri != route) return;
  owner.ref
      .read(workspaceNavigationProvider(owner.workspaceId).notifier)
      .remember(route);
}

int _selectedNavigationIndex(Uri route) =>
    WorkspaceNavigation.isConversation(route)
    ? -1
    : WorkspaceNavigation.classify(route)?.index ?? -1;

typedef _NavigationTap = ({
  BuildContext context,
  WidgetRef ref,
  int index,
  ValueNotifier<bool> pending,
  StatefulNavigationShell navigationShell,
  String workspaceId,
});

typedef _NavigationTapOwner = ({
  BuildContext context,
  WidgetRef ref,
  ValueNotifier<bool> pending,
});

ValueChanged<int> _navigationTapHandler(
  _NavigationTapOwner owner,
  StatefulNavigationShell navigationShell,
  String workspaceId,
) =>
    (index) => unawaited(
      _handleNavigationTap((
        context: owner.context,
        ref: owner.ref,
        index: index,
        pending: owner.pending,
        navigationShell: navigationShell,
        workspaceId: workspaceId,
      )),
    );

Future<void> _handleNavigationTap(_NavigationTap tap) async {
  if (_shouldIgnoreNavigationTap(tap)) return;
  final router = GoRouter.of(tap.context);
  final target = _navigationTarget(tap);
  if (target == router.state.uri.toString()) return;

  await _navigateFromNavigationTap(tap, router, target);
}

Future<void> _navigateFromNavigationTap(
  _NavigationTap tap,
  GoRouter router,
  String? target,
) async {
  tap.pending.value = true;
  try {
    await _approveAndNavigate(tap, router, target);
  } finally {
    if (tap.context.mounted) tap.pending.value = false;
  }
}

Future<void> _approveAndNavigate(
  _NavigationTap tap,
  GoRouter router,
  String? target,
) async {
  final registry = tap.ref.read(draftExitRegistryProvider);
  if (!await _approveNavigationExit(tap.context, router, registry)) return;

  _navigateToTarget(router, target, tap.navigationShell);
}

bool _shouldIgnoreNavigationTap(_NavigationTap tap) {
  if (tap.workspaceId.isEmpty || tap.pending.value) return true;

  return tap.index == WorkspaceDestination.chats.index &&
      tap.navigationShell.currentIndex == 0;
}

String? _navigationTarget(_NavigationTap tap) {
  final navigation = tap.ref.read(
    workspaceNavigationProvider(tap.workspaceId).notifier,
  );

  return switch (WorkspaceDestination.values[tap.index]) {
    .chats => null,
    .agentsAndSkills => navigation.agentsLocation(),
    .connections => navigation.connectionsLocation(),
    .appSettings => SettingsRoute(workspaceId: tap.workspaceId).location,
    .cloudAccounts => CloudAccountsRoute(workspaceId: tap.workspaceId).location,
  };
}

Future<bool> _approveNavigationExit(
  BuildContext context,
  GoRouter router,
  DraftExitRegistry registry,
) async {
  if (await registry.canExitActive(router) && context.mounted) return true;
  registry.releaseApprovals();

  return false;
}

void _navigateToTarget(
  GoRouter router,
  String? target,
  StatefulNavigationShell navigationShell,
) {
  if (target == null) {
    navigationShell.goBranch(0);
  } else {
    router.go(target);
  }
}
