import 'package:auravibes_app/domain/entities/workspace_entity.dart';
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
  final ResponsiveSlidingDrawerController _controller = .new();
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
}

class const _ResponsiveDrawerView({
  required final _AppWithResponsiveDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ResponsiveSlidingDrawer(
    drawer: _AppDrawerNavigation(state: state),
    body: ResponsiveSlidingDrawerProvider(
      controller: state._controller,
      child: state.widget.child,
    ),
    isDarkMode: Theme.of(context).brightness == Brightness.dark,
    controller: state._controller,
  );
}

class const _AppDrawerNavigation({
  required final _AppWithResponsiveDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    child: AuraSidebar(
      navigationItems: state.widget.navigationItems,
      onNavigationTap: state.widget.onNavigationTap,
      selectedIndex: state.widget.selectedIndex,
      header: _WorkspaceHeader(workspaceId: state.widget.workspaceId),
      middleSection: SidebarConversationsWidget(
        workspaceId: state.widget.workspaceId,
      ),
    ),
  );
}

class const _WorkspaceHeader({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    bottom: false,
    child: AuraPadding(
      child: _WorkspaceHeaderContent(workspaceId: workspaceId),
      padding: .small,
    ),
  );
}

class const _WorkspaceHeaderContent({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext _, WidgetRef ref) => _WorkspaceHeaderResult(
    workspaceId: workspaceId,
    workspaces: ref.watch(allWorkspacesProvider),
  );
}

class _WorkspaceHeaderResult extends StatelessWidget {
  new({
    required String workspaceId,
    required AsyncValue<List<WorkspaceEntity>> workspaces,
  }) : _child = switch (workspaces) {
         AsyncData(:final value) => _WorkspaceHeaderValue(
           workspaceId: workspaceId,
           workspaces: value,
         ),
         AsyncLoading() => const AuraContainer(
           child: Center(
             child: TextLocale(LocaleKeys.workspace_management_loading),
           ),
           height: 48,
         ),
         AsyncError(:final error, :final stackTrace) => _WorkspaceHeaderError(
           error: error,
           stackTrace: stackTrace,
         ),
       };

  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class const _WorkspaceHeaderValue({
  required final String workspaceId,
  required final List<WorkspaceEntity> workspaces,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workspace = workspaces
        .where((item) => item.id == workspaceId)
        .firstOrNull;

    return AuraText(
      child: Text(
        workspace?.name ?? LocaleKeys.workspace_management_loading.tr(),
      ),
      style: .heading6,
    );
  }
}

class const _WorkspaceHeaderError({
  required final Object error,
  required final StackTrace stackTrace,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _logger.warning('Workspace dropdown stream error', error, stackTrace);

    return const AuraText(
      child: TextLocale(LocaleKeys.workspace_management_unexpected_error),
    );
  }
}
