import 'package:auravibes_app/features/chats/widgets/sidebar_conversations_widget.dart';
import 'package:auravibes_app/flavors.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

/// A sidebar widget that handles business logic and navigation state.
///
/// This widget manages the sidebar's expand/collapse state, responsive behavior,
/// and navigation logic. It uses a hybrid approach:
/// - Desktop: Shows persistent collapsible sidebar
/// - Mobile: Uses Scaffold's drawer pattern for native platform behavior
/// It delegates the visual presentation to AuraSidebarOrganism
/// 'from auravibes_ui package.

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
    icon: Icon(Icons.build_circle_outlined),
    label: TextLocale(LocaleKeys.menu_tools),
  ),
  const AuraNavigationData(
    icon: Icon(Icons.memory_outlined),
    label: TextLocale(LocaleKeys.menu_models),
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

  return shellIndex;
}

class AuraSidebarWrapper extends HookWidget {
  /// Creates a Aura sidebar widget.
  const AuraSidebarWrapper({
    required this.navigationShell,
    super.key,
  });

  /// The main content to display next to the sidebar.
  final StatefulNavigationShell navigationShell;
  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active. This example demonstrates how to support this behavior,
      // using the initialLocation parameter of goBranch.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    final selectedIndex = _calculateSelectedIndex(
      context,
      navigationShell.currentIndex,
    );

    if (isSmallScreen) {
      // Mobile: Use Scaffold drawer pattern
      return AppWithResponsiveDrawer(
        navigationItems: _navigationItems,
        onNavigationTap: _goBranch,
        selectedIndex: selectedIndex,
        child: navigationShell,
      );
    } else {
      // Desktop: Use persistent sidebar
      return AppWithResponsiveDrawer(
        navigationItems: _navigationItems,
        onNavigationTap: _goBranch,
        selectedIndex: selectedIndex,
        child: navigationShell,
      );
    }
  }
}

class AppWithResponsiveDrawer extends StatefulWidget {
  const AppWithResponsiveDrawer({
    required this.child,
    required this.navigationItems,
    required this.onNavigationTap,
    required this.selectedIndex,
    super.key,
  });

  final Widget child;
  final List<AuraNavigationData> navigationItems;
  final void Function(int) onNavigationTap;
  final int selectedIndex;

  @override
  State<AppWithResponsiveDrawer> createState() =>
      _AppWithResponsiveDrawerState();
}

class _AppWithResponsiveDrawerState extends State<AppWithResponsiveDrawer> {
  late final ResponsiveSlidingDrawerController _controller =
      ResponsiveSlidingDrawerController();

  @override
  Widget build(BuildContext context) {
    return ResponsiveSlidingDrawer(
      controller: _controller,
      drawer: Material(
        child: AuraSidebar(
          navigationItems: widget.navigationItems,
          onNavigationTap: widget.onNavigationTap,
          header: const _AppLogo(),
          middleSection: const SidebarConversationsWidget(),
          selectedIndex: widget.selectedIndex,
        ),
      ),
      body: ResponsiveSlidingDrawerProvider(
        controller: _controller,
        child: widget.child,
      ),
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    final title = F.title;
    return SafeArea(
      bottom: false,
      child: AuraPadding(
        padding: .small,
        child: AuraText(
          style: AuraTextStyle.heading5,
          color: AuraColorVariant.onSurface,
          child: Text(title),
        ),
      ),
    );
  }
}
