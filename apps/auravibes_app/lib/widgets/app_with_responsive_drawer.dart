import 'package:auravibes_app/features/chats/widgets/sidebar_conversations_widget.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app_with_responsive_drawer');

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
  final ResponsiveSlidingDrawerController _controller =
      ResponsiveSlidingDrawerController();
  GoRouter? _router;
  Uri? _previousRoute;

  GoRouter get _requiredRouter {
    final router = _router;
    if (router == null) throw StateError('_router is not initialized');

    return router;
  }

  @override
  void initState() {
    super.initState();
    _router = GoRouter.of(context);
    _previousRoute = _router?.routeInformationProvider.value.uri;
    _router?.routeInformationProvider.addListener(_onRouteChanged);
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
          header: _WorkspaceHeader(workspaceId: widget.workspaceId),
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

  void _onRouteChanged() {
    final currentRoute = _requiredRouter.routeInformationProvider.value.uri;
    if (currentRoute == _previousRoute) return;

    _controller.closeIfMobile();
    setState(() => _previousRoute = currentRoute);
  }
}

class const _WorkspaceHeader({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(allWorkspacesProvider);
    final Widget header;
    switch (workspacesAsync) {
      case AsyncData(:final value):
        final workspace = value
            .where((item) => item.id == workspaceId)
            .firstOrNull;
        header = AuraText(
          child: Text(
            workspace?.name ?? LocaleKeys.workspace_management_loading.tr(),
          ),
          style: AuraTextStyle.heading6,
        );
      case AsyncLoading():
        header = const AuraContainer(
          child: Center(
            child: TextLocale(LocaleKeys.workspace_management_loading),
          ),
          height: 48,
        );
      case AsyncError(:final error, :final stackTrace):
        _logger.warning('Workspace dropdown stream error', error, stackTrace);
        header = const AuraText(
          child: TextLocale(LocaleKeys.workspace_management_unexpected_error),
        );
    }

    return SafeArea(
      bottom: false,
      child: AuraPadding(child: header, padding: .small),
    );
  }
}
