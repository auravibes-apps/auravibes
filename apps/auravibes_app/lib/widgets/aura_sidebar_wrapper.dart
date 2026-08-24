// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_with_responsive_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

export 'app_with_responsive_drawer.dart';

/// A sidebar widget that handles business logic and navigation state.
///
/// This widget manages the sidebar's expand/collapse state, responsive behavior,
/// and navigation logic. It uses a hybrid approach:
/// - Desktop: Shows persistent collapsible sidebar
/// - Mobile: Uses Scaffold's drawer pattern for native platform behavior
/// It delegates the visual presentation to AuraSidebarOrganism
/// from the auravibes_ui package.

final List<AuraNavigationData> _navigationItems = [
  // Const AuraNavigationData(.
  //   Icon: Icon(Icons.dashboard_outlined),.
  //   Label: TextLocale(LocaleKeys.menu_home),.
  // ),.
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

  const newChatIndex = 0;
  const appSettingsIndex = 1;
  const footerSettingsIndex = 2;
  return switch (shellIndex) {
    newChatIndex => newChatIndex, // New Chat.
    appSettingsIndex => appSettingsIndex, // App Settings.
    footerSettingsIndex => footerSettingsIndex, // Settings (footer).
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
    // UseListenable keeps GoRouter route information updates active for
    // _calculateSelectedIndex.
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

        _goBranch(index);
      },
      selectedIndex: selectedIndex,
      workspaceId: workspaceId,
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(index, initialLocation: true);
  }
}
