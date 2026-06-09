// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-extracting-callbacks
// Required: UI callbacks stay local to their widgets.
// ignore_for_file: prefer-single-widget-per-file
// Required: Feature widgets keep closely related private widgets together.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/features/chats/widgets/sidebar_conversations_widget.dart';
import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_dropdown_item.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

/// A sidebar widget that handles business logic and navigation state.
///
/// This widget manages the sidebar's expand/collapse state, responsive behavior,
/// and navigation logic. It uses a hybrid approach:
/// - Desktop: Shows persistent collapsible sidebar
/// - Mobile: Uses Scaffold's drawer pattern for native platform behavior
/// It delegates the visual presentation to AuraSidebarOrganism
/// from the auravibes_ui package.

final List<AuraNavigationData> _navigationItems = [
  // const AuraNavigationData(
  //   icon: Icon(Icons.dashboard_outlined),
  //   label: TextLocale(LocaleKeys.menu_home),
  // ),
  const AuraNavigationData(
    icon: Icon(Icons.chat_outlined),
    label: TextLocale(LocaleKeys.menu_new_chat),
  ),
  const AuraNavigationData(
    icon: Icon(Icons.settings_applications_outlined),
    label: TextLocale(LocaleKeys.menu_more),
  ),
  const AuraNavigationData(
    icon: Icon(Icons.settings_outlined),
    label: TextLocale(LocaleKeys.settings_screen_title),
    footer: true,
  ),
];

/// Calculates the correct sidebar navigation index based on the current route
/// path.
///
/// Returns -1 when viewing a specific conversation (/chats/:chatId), as no
/// navigation item should be highlighted - the conversation itself is selected
/// in the sidebar's middle section.
int _calculateSelectedIndex(BuildContext context, int shellIndex) {
  final router = GoRouter.of(context);
  final pathSegments = router.routeInformationProvider.value.uri.pathSegments;

  for (var i = 0; i < pathSegments.length; i++) {
    if (pathSegments[i] == 'chats' && i + 1 < pathSegments.length) {
      final nextSegment = pathSegments[i + 1];

      if (nextSegment.isNotEmpty && !nextSegment.startsWith('new')) {
        return -1;
      }
    }
  }

  return switch (shellIndex) {
    0 => 0, // New Chat
    1 => 1, // App Settings
    2 => 2, // Settings (footer)
    _ => -1,
  };
}

class AuraSidebarWrapper extends HookConsumerWidget {
  /// Creates a Aura sidebar widget.
  const AuraSidebarWrapper({
    required this.navigationShell,
    required this.workspaceId,
    super.key,
  });

  static final Logger _logger = Logger('AuraSidebarWrapper');

  /// The main content to display next to the sidebar.
  final StatefulNavigationShell navigationShell;

  /// The current workspace ID from the route.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // useListenable keeps GoRouter.of(context).routeInformationProvider updates
    // active for _calculateSelectedIndex.
    final _ = useListenable(GoRouter.of(context).routeInformationProvider);
    final selectedIndex = _calculateSelectedIndex(
      context,
      navigationShell.currentIndex,
    );

    return AppWithResponsiveDrawer(
      child: navigationShell,
      navigationItems: _navigationItems,
      onNavigationTap: (index) {
        if (workspaceId.isEmpty) {
          _logger.fine(
            '[Navigation] onNavigationTap: workspaceId missing, ignoring tap',
          );
          return;
        }

        _goBranch(context, index, workspaceId);
      },
      selectedIndex: selectedIndex,
      workspaceId: workspaceId,
    );
  }

  void _goBranch(BuildContext context, int index, String workspaceId) {
    switch (index) {
      case 0:
        NewChatRoute(workspaceId: workspaceId).go(context);
      case 1:
        MoreRoute(workspaceId: workspaceId).go(context);
      case 2:
        SettingsRoute(workspaceId: workspaceId).go(context);
    }
  }
}

class AppWithResponsiveDrawer extends StatefulWidget {
  const AppWithResponsiveDrawer({
    required this.child,
    required this.navigationItems,
    required this.onNavigationTap,
    required this.selectedIndex,
    required this.workspaceId,
    super.key,
  });

  final Widget child;
  final List<AuraNavigationData> navigationItems;
  final void Function(int) onNavigationTap;
  final int selectedIndex;
  final String workspaceId;

  @override
  State<AppWithResponsiveDrawer> createState() =>
      _AppWithResponsiveDrawerState();
}

class _AppWithResponsiveDrawerState extends State<AppWithResponsiveDrawer> {
  final ResponsiveSlidingDrawerController _controller =
      ResponsiveSlidingDrawerController();
  GoRouter? _router;
  Uri? _previousRoute;

  GoRouter get _requiredRouter {
    final router = _router;
    if (router == null) {
      throw StateError('_router is not initialized');
    }

    return router;
  }

  @override
  void initState() {
    super.initState();
    _router = GoRouter.of(context);
    _previousRoute = _router?.routeInformationProvider.value.uri;
    _router?.routeInformationProvider.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    final currentRoute = _requiredRouter.routeInformationProvider.value.uri;
    if (currentRoute != _previousRoute) {
      _controller.closeIfMobile();

      setState(() {
        _previousRoute = currentRoute;
      });
    }
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveSlidingDrawer(
      drawer: Material(
        child: AuraSidebar(
          navigationItems: widget.navigationItems,
          onNavigationTap: widget.onNavigationTap,
          selectedIndex: widget.selectedIndex,
          header: _WorkspaceDropdownHeader(workspaceId: widget.workspaceId),
          middleSection: SidebarConversationsWidget(
            workspaceId: widget.workspaceId,
          ),
        ),
      ),
      body: ResponsiveSlidingDrawerProvider(
        controller: _controller,
        child: widget.child,
      ),
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      controller: _controller,
    );
  }
}

class _WorkspaceDropdownHeader extends ConsumerWidget {
  const _WorkspaceDropdownHeader({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(allWorkspacesProvider);
    final switcherState = ref.watch(workspaceSwitcherProvider);

    final Widget dropdownWidget;
    switch (workspacesAsync) {
      case AsyncData(:final value):
        final items = value
            .map(
              (w) => WorkspaceDropdownItem(
                id: w.id,
                name: w.name,
              ),
            )
            .toList();

        final isLoading = switcherState.status == SwitchStatus.loading;
        final errorKey = switcherState.errorLocalizationKey;

        dropdownWidget = WorkspaceDropdown(
          workspaces: items,
          activeWorkspaceId: workspaceId,
          onSelected: (item) {
            if (item.id == workspaceId) return;
            ref
                .read(workspaceSwitcherProvider.notifier)
                .switchToWorkspace(item.id);
          },
          isLoading: isLoading,
          errorLocalizationKey: errorKey,
        );
      case AsyncLoading():
        dropdownWidget = const AuraContainer(
          child: Center(
            child: TextLocale(LocaleKeys.workspace_management_loading),
          ),
          height: 48,
        );
      case AsyncError(:final error):
        debugPrint('Workspace dropdown stream error: $error');
        dropdownWidget = const AuraText(
          child: TextLocale(LocaleKeys.workspace_management_unexpected_error),
        );
    }

    return SafeArea(
      bottom: false,
      child: AuraPadding(
        child: dropdownWidget,
        padding: .small,
      ),
    );
  }
}
