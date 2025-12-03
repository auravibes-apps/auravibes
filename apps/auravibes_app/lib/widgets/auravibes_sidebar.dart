import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A sidebar widget that handles business logic and navigation state.
///
/// This widget manages the sidebar's expand/collapse state, responsive behavior,
/// and navigation logic. It uses a hybrid approach:
/// - Desktop: Shows persistent collapsible sidebar
/// - Mobile: Uses Scaffold's drawer pattern for native platform behavior
/// It delegates the visual presentation to AuraSidebarOrganism
/// 'from the auravibes_ui package.
class AuraSidebarWrapper extends StatefulWidget {
  /// Creates a Aura sidebar widget.
  const AuraSidebarWrapper({
    required this.child,
    super.key,
    this.isInitiallyExpanded = true,
  });

  /// The main content to display next to the sidebar.
  final Widget child;

  /// Whether the sidebar should be expanded initially (desktop only).
  final bool isInitiallyExpanded;

  @override
  State<AuraSidebarWrapper> createState() => _AuraSidebarWrapperState();
}

enum NavigationItemType {
  home,
  chats,
  tools,
  models,
  agents,
  prompts
  ;

  GoRouteData router() {
    return switch (this) {
      NavigationItemType.home => const HomeRoute(),
      NavigationItemType.chats => ChatsRoute(),
      NavigationItemType.tools => ToolsRoute(),
      NavigationItemType.models => ModelsRoute(),
      NavigationItemType.agents => AgentsRoute(),
      NavigationItemType.prompts => PromptsRoute(),
    };
  }
}

class _AuraSidebarWrapperState extends State<AuraSidebarWrapper>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<AuraNavigationData<NavigationItemType>> _navigationItems = [
    const AuraNavigationData(
      icon: Icons.dashboard_outlined,
      label: TextLocale(LocaleKeys.menu_home),
      value: NavigationItemType.home,
    ),
    const AuraNavigationData(
      icon: Icons.chat_outlined,
      label: TextLocale(LocaleKeys.menu_chats),
      value: NavigationItemType.chats,
    ),
    const AuraNavigationData(
      icon: Icons.build_circle_outlined,
      label: TextLocale(LocaleKeys.menu_tools),
      value: NavigationItemType.tools,
    ),
    const AuraNavigationData(
      icon: Icons.memory_outlined,
      label: TextLocale(LocaleKeys.menu_models),
      value: NavigationItemType.models,
    ),
    // const AuraNavigationData(
    //   icon: Icons.smart_toy_outlined,
    //   label: TextLocale(LocaleKeys.menu_agents),
    //   value: NavigationItemType.agents,
    // ),
    // const AuraNavigationData(
    //   icon: Icons.description_outlined,
    //   label: TextLocale(LocaleKeys.menu_prompts),
    //   value: NavigationItemType.prompts,
    // ),
  ];

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handles navigation when a navigation item is tapped.
  void _handleNavigation(NavigationItemType route) {
    // Close drawer if open (mobile)
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }

    route.router().go(context);
  }

  /// Handles settings navigation.
  void _handleSettingsNavigation() {
    SettingsRoute().go(context);
  }

  /// Builds the list of navigation items with active state.
  List<AuraNavigationData<NavigationItemType>> _buildNavigationItems() {
    final currentRoute = GoRouterState.of(context).uri.toString();

    return _navigationItems.map((item) {
      final isActive = item.value.router().location.startsWith(currentRoute);

      return item.copyWith(isActive: isActive);
    }).toList();
  }

  /// Builds the header widget with the AURA logo.
  Widget _buildHeader(BuildContext context, {bool isDrawer = false}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.auraColors.primary,
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.lg),
      ),
      child: Center(
        child: AuraText(
          style: AuraTextStyle.heading5,
          color: AuraColorVariant.onPrimary,
          child: Text(isDrawer ? 'AURA' : (_isExpanded ? 'AURA' : 'T')),
        ),
      ),
    );
  }

  /// Builds the footer widget with settings.
  Widget _buildFooter(BuildContext context, {bool isDrawer = false}) {
    final isActive = GoRouterState.of(context).uri.toString() == '/settings';

    return AuraTile(
      variant: isActive ? AuraTileVariant.primary : AuraTileVariant.ghost,
      leading: Icon(
        Icons.settings_outlined,
        size: 24,
        color: isActive
            ? context.auraColors.onPrimary
            : context.auraColors.onSurfaceVariant,
      ),
      onTap: _handleSettingsNavigation,
      child: (isDrawer || _isExpanded)
          ? AuraText(
              style: AuraTextStyle.bodySmall,
              color: isActive
                  ? AuraColorVariant.onPrimary
                  : AuraColorVariant.onSurface,
              child: const Text('Settings'),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    // Auto-collapse on small screens, auto-expand on large screens
    if (isSmallScreen && _isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isExpanded = false;
            _animationController.reverse();
          });
        }
      });
    } else if (!isSmallScreen && !_isExpanded && widget.isInitiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isExpanded = true;
            _animationController.forward();
          });
        }
      });
    }

    if (isSmallScreen) {
      // Mobile: Use Scaffold drawer pattern
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('AURA'),
          backgroundColor: context.auraColors.primary,
          foregroundColor: context.auraColors.onPrimary,
          elevation: 0,
        ),
        drawer: Drawer(
          backgroundColor: context.auraColors.surface,
          child: AuraSidebar<NavigationItemType>(
            isExpanded: true, // Always expanded in drawer mode
            animation: const AlwaysStoppedAnimation(1),
            navigationItems: _buildNavigationItems(),
            onNavigationTap: _handleNavigation,
            header: _buildHeader(context, isDrawer: true),
            footer: _buildFooter(context, isDrawer: true),
          ),
        ),
        body: widget.child,
      );
    } else {
      // Desktop: Use persistent sidebar
      return Scaffold(
        body: Row(
          children: [
            // Sidebar UI Component
            AuraSidebar(
              isExpanded: _isExpanded,
              animation: _animation,
              navigationItems: _buildNavigationItems(),
              onNavigationTap: _handleNavigation,
              header: _buildHeader(context),
              footer: _buildFooter(context),
            ),

            // Main Content
            Expanded(child: widget.child),
          ],
        ),
      );
    }
  }
}
