import 'dart:async';

import 'package:auravibes_app/widgets/feature_destination_master.dart';
import 'package:auravibes_app/widgets/feature_destination_shell_scope.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class const FeatureDestinationShell({
  required final GlobalKey<NavigatorState> navigatorKey,
  required final GlobalKey<NavigatorState> parentNavigatorKey,
  required final List<FeatureNavigationDestination> destinations,
  required final Widget child,
  required final String? initialLocation,
  super.key,
}) extends StatefulWidget {
  @override
  State<FeatureDestinationShell> createState() =>
      _FeatureDestinationShellState();
}

class _FeatureDestinationShellState extends State<FeatureDestinationShell> {
  bool _restoringLocation = false;
  bool _restoreScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleRestore();
  }

  @override
  void didUpdateWidget(covariant FeatureDestinationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLocation != widget.initialLocation) {
      _restoreScheduled = false;
      _scheduleRestore();
    }
  }

  @override
  Widget build(BuildContext context) =>
      _FeatureDestinationShellRouterView(state: this, router: .of(context));

  void _scheduleRestore() {
    final location = widget.initialLocation;
    if (location == null || _restoreScheduled) return;
    _restoreScheduled = true;
    _restoringLocation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore(location));
  }

  void _restore(String location) {
    if (!mounted) return;
    final navigation = GoRouter.of(context)
        .push<void>(location, extra: const FeatureDestinationStackPush());
    unawaited(navigation);
    setState(() => _restoringLocation = false);
  }
}

class const _FeatureDestinationShellRouterView({
  required final _FeatureDestinationShellState state,
  required final GoRouter router,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: router.routerDelegate,
    builder: (context, _) => _FeatureDestinationShellViewport(
      state: state,
      currentUri: router.state.uri,
    ),
  );
}

class const _FeatureDestinationShellViewport({
  required final _FeatureDestinationShellState state,
  required final Uri currentUri,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _FeatureDestinationShellFrame(
      state: state,
      currentUri: currentUri,
      isCompact:
          constraints.maxWidth <
          FeatureDestinationShellLayout.masterDetailBreakpoint,
    ),
  );
}

class const _FeatureDestinationShellFrame({
  required final _FeatureDestinationShellState state,
  required final Uri currentUri,
  required final bool isCompact,
}) extends StatelessWidget {
  ({bool isMasterList, String selectedLocation}) get _routeState {
    final isMasterList = FeatureDestinations.isMasterLocation(currentUri);

    return (
      isMasterList: isMasterList,
      selectedLocation: isMasterList
          ? ''
          : _selectedLocation(currentUri, state.widget.destinations),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeState = _routeState;

    return Stack(
      fit: .expand,
      children: [
        _FeatureDestinationShellOffstage(
          state: state,
          currentUri: currentUri,
          selectedLocation: routeState.selectedLocation,
          isCompact: isCompact,
          isMasterList: routeState.isMasterList,
        ),
        if (state._restoringLocation)
          _FeatureDestinationShellRestoring(context.auraColors.surface),
      ],
    );
  }
}

class const _FeatureDestinationShellOffstage({
  required final _FeatureDestinationShellState state,
  required final Uri currentUri,
  required final String selectedLocation,
  required final bool isCompact,
  required final bool isMasterList,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Offstage(
    offstage: state._restoringLocation,
    child: _FeatureDestinationShellRoute(
      state: state,
      currentUri: currentUri,
      selectedLocation: selectedLocation,
      isCompact: isCompact,
      canPop: !isMasterList,
    ),
  );
}

class const _FeatureDestinationShellRoute({
  required final _FeatureDestinationShellState state,
  required final Uri currentUri,
  required final String selectedLocation,
  required final bool isCompact,
  required final bool canPop,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FeatureDestinationShellScope(
    isCompact: isCompact,
    navigatorKey: state.widget.navigatorKey,
    parentNavigatorKey: state.widget.parentNavigatorKey,
    child: PopScope(
      child: _FeatureDestinationShellSurface(
        state: state,
        currentUri: currentUri,
        selectedLocation: selectedLocation,
        isCompact: isCompact,
      ),
      canPop: canPop,
    ),
  );
}

class const _FeatureDestinationShellSurface({
  required final _FeatureDestinationShellState state,
  required final Uri currentUri,
  required final String selectedLocation,
  required final bool isCompact,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.auraColors.surface,
    child: isCompact
        ? state.widget.child
        : _FeatureDestinationShellWideContent(
            state: state,
            currentUri: currentUri,
            selectedLocation: selectedLocation,
          ),
  );
}

class const _FeatureDestinationShellWideContent({
  required final _FeatureDestinationShellState state,
  required final Uri currentUri,
  required final String selectedLocation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _FeatureDestinationShellMasterPane(
        state: state,
        currentUri: currentUri,
        selectedLocation: selectedLocation,
      ),
      VerticalDivider(
        width: 1,
        thickness: 1,
        color: context.auraColors.outline,
      ),
      Expanded(child: state.widget.child),
    ],
  );
}

class const _FeatureDestinationShellMasterPane({
  required final _FeatureDestinationShellState state,
  required final Uri currentUri,
  required final String selectedLocation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: FeatureDestinationShellLayout.masterPaneWidth,
    child: SafeArea(
      left: Directionality.of(context) == .ltr,
      top: false,
      right: Directionality.of(context) == .rtl,
      bottom: false,
      child: FeatureDestinationMaster(
        destinations: state.widget.destinations,
        selectedLocation: selectedLocation,
        currentLocation: currentUri.toString(),
        useStackNavigation: false,
      ),
    ),
  );
}

class const _FeatureDestinationShellRestoring(final Color color)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: const Center(child: AuraSpinner()),
  );
}

String _selectedLocation(
  Uri currentUri,
  List<FeatureNavigationDestination> destinations,
) {
  final location = _withoutMasterQuery(currentUri);
  final selected = _selectedDestination(location, destinations).firstOrNull;

  return selected?.location ?? destinations.firstOrNull?.location ?? '';
}

Uri _withoutMasterQuery(Uri uri) {
  final queryParameters = {
    for (final entry in uri.queryParameters.entries)
      if (entry.key != 'destinationList') entry.key: entry.value,
  };

  return uri.replace(
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  );
}

Iterable<FeatureNavigationDestination> _selectedDestination(
  Uri location,
  List<FeatureNavigationDestination> destinations,
) => destinations.where(
  (destination) => _matchesDestination(location, destination),
);

bool _matchesDestination(
  Uri location,
  FeatureNavigationDestination destination,
) {
  final destinationUri = Uri.parse(destination.location);
  if (location.path == destinationUri.path &&
      location.toString() == destination.location) {
    return true;
  }
  if (!location.path.startsWith('${destinationUri.path}/')) return false;

  final nestedView = switch (location.queryParameters['type']) {
    'connector' => 'connectors',
    'modelProvider' => 'providers',
    _ => location.queryParameters['view'],
  };

  return destinationUri.queryParameters['view'] == nestedView;
}
