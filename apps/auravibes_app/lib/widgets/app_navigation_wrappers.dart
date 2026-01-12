import 'package:auravibes_app/flavors.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
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
/// 'from the auravibes_ui package.

final List<AuraNavigationData> _navigationItems = [
  // const AuraNavigationData(
  //   icon: Icon(Icons.dashboard_outlined),
  //   label: TextLocale(LocaleKeys.menu_home),
  // ),
  const AuraNavigationData(
    icon: Icon(Icons.chat_outlined),
    label: TextLocale(LocaleKeys.menu_chats),
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

    if (isSmallScreen) {
      // Mobile: Use Scaffold drawer pattern
      return AppWithNavbar(
        navigationItems: _navigationItems,
        onNavigationTap: _goBranch,
        selectedIndex: navigationShell.currentIndex,
        child: navigationShell,
      );
    } else {
      // Desktop: Use persistent sidebar
      return AppWithNavRail(
        navigationItems: _navigationItems,
        onNavigationTap: _goBranch,
        selectedIndex: navigationShell.currentIndex,
        child: navigationShell,
      );
    }
  }
}

class AppWithNavbar extends StatelessWidget {
  const AppWithNavbar({
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AuraBottomBar(
        navigationItems: navigationItems,
        selectedIndex: selectedIndex,
        onNavigationTap: onNavigationTap,
      ),
    );
  }
}

class AppWithNavRail extends StatelessWidget {
  const AppWithNavRail({
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Row(
        children: [
          // Sidebar UI Component
          AuraSidebar(
            navigationItems: navigationItems,
            onNavigationTap: onNavigationTap,
            header: const _AppLogo(),
            selectedIndex: selectedIndex,
          ),
          // Main Content
          Expanded(
            child: child,
          ),
        ],
      ),
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.auraColors.primary,
            borderRadius: BorderRadius.circular(
              context.auraTheme.borderRadius.lg,
            ),
          ),
          child: AuraPadding(
            padding: const .only(
              top: AuraSpacing.sm,
              bottom: AuraSpacing.sm,
            ),
            child: Center(
              child: AuraText(
                style: AuraTextStyle.heading5,
                color: AuraColorVariant.onPrimary,
                child: Text(title),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
