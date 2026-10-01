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
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final _ = useListenable(router.routerDelegate);
    final route = router.state.uri;
    final pending = useState(false);
    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || router.state.uri != route) return;
          ref
              .read(workspaceNavigationProvider(workspaceId).notifier)
              .remember(route);
        });

        return null;
      },
      [
        // The committed URI and owner determine the safe list memory.
        route,
        workspaceId,
      ],
    );
    final selectedIndex = WorkspaceNavigation.isConversation(route)
        ? -1
        : WorkspaceNavigation.classify(route)?.index ?? -1;

    return AppWithResponsiveDrawer(
      child: navigationShell,
      navigationItems: _navigationItems(context),
      onNavigationTap: (index) =>
          unawaited(_handleNavigationTap(context, ref, index, pending)),
      selectedIndex: selectedIndex,
      workspaceId: workspaceId,
    );
  }

  Future<void> _handleNavigationTap(
    BuildContext context,
    WidgetRef ref,
    int index,
    ValueNotifier<bool> pending,
  ) async {
    if (workspaceId.isEmpty || pending.value) return;
    final router = GoRouter.of(context);
    if (index == WorkspaceDestination.chats.index &&
        navigationShell.currentIndex == 0) {
      return;
    }
    final navigation = ref.read(
      workspaceNavigationProvider(workspaceId).notifier,
    );
    final target = switch (WorkspaceDestination.values[index]) {
      .chats => null,
      .agentsAndSkills => navigation.agentsLocation(),
      .connections => navigation.connectionsLocation(),
      .appSettings => SettingsRoute(workspaceId: workspaceId).location,
      .cloudAccounts => CloudAccountsRoute(workspaceId: workspaceId).location,
    };
    if (target == router.state.uri.toString()) return;
    pending.value = true;
    final registry = ref.read(draftExitRegistryProvider);
    try {
      if (!await registry.canExitActive(router) || !context.mounted) {
        registry.releaseApprovals();

        return;
      }
      if (target == null) {
        navigationShell.goBranch(0);
      } else {
        router.go(target);
      }
    } finally {
      if (context.mounted) pending.value = false;
    }
  }
}
