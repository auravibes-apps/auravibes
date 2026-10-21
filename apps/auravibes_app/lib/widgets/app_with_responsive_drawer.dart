import 'package:auravibes_app/features/chats/widgets/sidebar_conversations_widget.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_selector.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/responsive_shell_layout.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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
    required this.canPopCurrentRoute,
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

  /// Whether the active app route has a page beneath it in its own navigator.
  final bool Function() canPopCurrentRoute;

  @override
  State<AppWithResponsiveDrawer> createState() =>
      _AppWithResponsiveDrawerState();
}

class _AppWithResponsiveDrawerState extends State<AppWithResponsiveDrawer> {
  final ResponsiveSlidingDrawerController _controller = .new();
  GoRouter? _router;
  Uri? _previousRoute;
  bool? _isSidebarCompactOverride;

  GoRouter get _requiredRouter {
    final router = _router;
    if (router == null) throw StateError('_router is not initialized');

    return router;
  }

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

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
    final width = MediaQuery.sizeOf(context).width;
    if (!ResponsiveShellLayout.isDesktop(width)) {
      return;
    }
    setState(
      () => _isSidebarCompactOverride =
          !(_isSidebarCompactOverride ??
              ResponsiveShellLayout.isCompactDesktop(width)),
    );
  }

  bool _isSidebarCompactAt(double width) =>
      _isSidebarCompactOverride ??
      ResponsiveShellLayout.isCompactDesktop(width);
}

class const _ResponsiveDrawerView({
  required final _AppWithResponsiveDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = ResponsiveShellLayout.isDesktop(width);
    final isCompact = isDesktop && state._isSidebarCompactAt(width);

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
    isDarkMode: state._isDarkMode,
    controller: state._controller,
    initiallyOpen: isDesktop,
    isDesktopCompact: isCompact,
    canPopCurrentRoute: state.widget.canPopCurrentRoute,
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
  Widget build(BuildContext context) {
    return _AppDrawerSurface(
      state: state,
      isDesktop: isDesktop,
      isExpanded: isExpanded,
      padding: _safePadding(context),
    );
  }

  static EdgeInsetsDirectional _safePadding(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context)
        .resolve(Directionality.of(context));
    final isLtr = Directionality.of(context) == TextDirection.ltr;

    return EdgeInsetsDirectional.only(
      start: isLtr ? safePadding.left : safePadding.right,
      top: safePadding.top,
      bottom: safePadding.bottom,
    );
  }
}

class const _AppDrawerSurface({
  required final _AppWithResponsiveDrawerState state,
  required final bool isDesktop,
  required final bool isExpanded,
  required final EdgeInsetsDirectional padding,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    child: _AppDrawerSidebar(
      state: state,
      isDesktop: isDesktop,
      isExpanded: isExpanded,
      padding: padding,
    ),
  );
}

class const _AppDrawerSidebar({
  required final _AppWithResponsiveDrawerState state,
  required final bool isDesktop,
  required final bool isExpanded,
  required final EdgeInsetsDirectional padding,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = state.widget;

    return AuraSidebar(
      navigationItems: app.navigationItems,
      onNavigationTap: app.onNavigationTap,
      isExpanded: isExpanded,
      selectedIndex: app.selectedIndex,
      header: _AppDrawerHeader(
        state: state,
        isDesktop: isDesktop,
        isExpanded: isExpanded,
      ),
      middleSection: isExpanded
          ? _SidebarConversationsSection(workspaceId: app.workspaceId)
          : null,
      padding: padding,
    );
  }
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
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      if (isExpanded)
        _ExpandedWorkspaceHeader(
          workspaceId: workspaceId,
          isDesktop: isDesktop,
          onToggle: onToggle,
        ),
      if (isDesktop && !isExpanded) _CompactWorkspaceHeader(onToggle: onToggle),
    ],
  );
}

class const _ExpandedWorkspaceHeader({
  required final String workspaceId,
  required final bool isDesktop,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkspaceSelectorHeader(
    workspaceId: workspaceId,
    trailingAction: isDesktop
        ? _DesktopSidebarToggle(
            isExpanded: true,
            onToggle: onToggle,
            tooltip: _sidebarToggleTooltip(true, context),
          )
        : null,
  );
}

class const _CompactWorkspaceHeader({required final VoidCallback onToggle})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _DesktopSidebarToggle(
    isExpanded: false,
    onToggle: onToggle,
    tooltip: _sidebarToggleTooltip(false, context),
  );
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

class const _WorkspaceSelectorHeader({
  required final String workspaceId,
  required final Widget? trailingAction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPadding(
    child: WorkspaceSelector(
      workspaceId: workspaceId,
      trailingAction: trailingAction,
    ),
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
