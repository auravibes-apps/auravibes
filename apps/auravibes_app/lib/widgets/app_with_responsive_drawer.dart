import 'package:auravibes_app/features/chats/widgets/sidebar_conversations_widget.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_selector.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/responsive_shell_layout.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// App shell with a responsive navigation drawer.
class AppWithResponsiveDrawer extends StatefulWidget {
  /// Creates a responsive drawer app shell.
  const new({
    required this.child,
    required this.navigationItems,
    required this.onNavigationTap,
    required this.selectedIndex,
    required this.workspaceId,
    super.key,
  });

  /// Main content.
  final Widget child;

  /// Navigation items.
  final List<AuraNavigationData> navigationItems;

  /// Navigation callback.
  final void Function(int) onNavigationTap;

  /// Selected navigation index.
  final int selectedIndex;

  /// Workspace id.
  final String workspaceId;

  @override
  State<AppWithResponsiveDrawer> createState() =>
      _AppWithResponsiveDrawerState();
}

class _AppWithResponsiveDrawerState extends State<AppWithResponsiveDrawer> {
  final ResponsiveSlidingDrawerController _controller = .new();
  GoRouter? _router;
  Uri? _previousRoute;
  bool _isSidebarCompact = false;

  GoRouter get _requiredRouter {
    final router = _router;
    if (router == null) throw StateError('_router is not initialized');

    return router;
  }

  @override
  void initState() {
    super.initState();
    _router = .of(context);
    _previousRoute = _router?.routeInformationProvider.value.uri;
    _router?.routeInformationProvider.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ResponsiveDrawerView(state: this);

  void _onRouteChanged() {
    final currentRoute = _requiredRouter.routeInformationProvider.value.uri;
    if (currentRoute == _previousRoute) return;

    _controller.closeIfMobile();
    setState(() => _previousRoute = currentRoute);
  }

  void _toggleDesktopSidebar() {
    if (!ResponsiveShellLayout.isDesktop(MediaQuery.sizeOf(context).width)) {
      return;
    }
    setState(() => _isSidebarCompact = !_isSidebarCompact);
  }
}

class const _ResponsiveDrawerView({
  required final _AppWithResponsiveDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveShellLayout.isDesktop(
      MediaQuery.sizeOf(context).width,
    );
    final isCompact = isDesktop && state._isSidebarCompact;

    return _ResponsiveDrawerShell(
      state: state,
      isDesktop: isDesktop,
      isCompact: isCompact,
    );
  }
}

class const _ResponsiveDrawerShell({
  required final _AppWithResponsiveDrawerState state,
  required final bool isDesktop,
  required final bool isCompact,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ResponsiveSlidingDrawer(
    drawer: _AppDrawerNavigation(
      state: state,
      isDesktop: isDesktop,
      isExpanded: !isCompact,
    ),
    body: _ResponsiveDrawerBody(state: state),
    isDarkMode: Theme.of(context).brightness == Brightness.dark,
    controller: state._controller,
    initiallyOpen: isDesktop,
    isDesktopCompact: isCompact,
  );
}

class const _ResponsiveDrawerBody({
  required final _AppWithResponsiveDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ResponsiveSlidingDrawerProvider(
    controller: state._controller,
    child: state.widget.child,
  );
}

class const _AppDrawerNavigation({
  required final _AppWithResponsiveDrawerState state,
  required final bool isDesktop,
  required final bool isExpanded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    child: AuraSidebar(
      navigationItems: state.widget.navigationItems,
      onNavigationTap: state.widget.onNavigationTap,
      isExpanded: isExpanded,
      selectedIndex: state.widget.selectedIndex,
      header: _AppDrawerHeader(
        state: state,
        isDesktop: isDesktop,
        isExpanded: isExpanded,
      ),
      middleSection: isExpanded
          ? _SidebarConversationsSection(workspaceId: state.widget.workspaceId)
          : null,
    ),
  );
}

class const _AppDrawerHeader({
  required final _AppWithResponsiveDrawerState state,
  required final bool isDesktop,
  required final bool isExpanded,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _WorkspaceHeader(
    workspaceId: state.widget.workspaceId,
    isDesktop: isDesktop,
    isExpanded: isExpanded,
    onToggle: state._toggleDesktopSidebar,
  );
}

class const _WorkspaceHeader({
  required final String workspaceId,
  required final bool isDesktop,
  required final bool isExpanded,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkspaceHeaderContent(
    workspaceId: workspaceId,
    isDesktop: isDesktop,
    isExpanded: isExpanded,
    onToggle: onToggle,
  );
}

class const _WorkspaceHeaderContent({
  required final String workspaceId,
  required final bool isDesktop,
  required final bool isExpanded,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toggleTooltip = _sidebarToggleTooltip(isExpanded, context);

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: .min,
        children: [
          if (isDesktop)
            _DesktopSidebarToggle(
              isExpanded: isExpanded,
              onToggle: onToggle,
              tooltip: toggleTooltip,
            ),
          if (isExpanded) _WorkspaceSelectorHeader(workspaceId: workspaceId),
        ],
      ),
    );
  }
}

class const _DesktopSidebarToggle({
  required final bool isExpanded,
  required final VoidCallback onToggle,
  required final String tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPadding(
    child: Align(
      alignment: .centerRight,
      child: AuraIconButton(
        icon: isExpanded ? Icons.menu_open : Icons.menu,
        onPressed: onToggle,
        semanticLabel: tooltip,
        tooltip: tooltip,
      ),
    ),
    padding: .small,
  );
}

class const _WorkspaceSelectorHeader({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPadding(
    child: WorkspaceSelector(workspaceId: workspaceId),
    padding: .small,
  );
}

class const _SidebarConversationsSection({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SidebarConversationsWidget(workspaceId: workspaceId);
}

String _sidebarToggleTooltip(bool isExpanded, BuildContext context) =>
    isExpanded
    ? LocaleKeys.navigation_drawer_collapse_sidebar_tooltip.tr(context: context)
    : LocaleKeys.navigation_drawer_expand_sidebar_tooltip.tr(context: context);
