import 'package:auravibes_app/widgets/feature_destination_master.dart';
import 'package:auravibes_app/widgets/feature_destination_shell_scope.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const AdaptiveMasterDetailLayout({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUri = FeatureDestinations.currentUri(context);

    return _AdaptiveMasterDetailContent(
      destinations: destinations,
      selectedLocation: selectedLocation,
      currentLocation: currentUri?.toString() ?? selectedLocation,
      isMasterList:
          currentUri != null &&
          FeatureDestinations.isMasterLocation(currentUri),
      shell: .maybeOf(context),
      child: child,
    );
  }
}

class const _AdaptiveMasterDetailContent({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String currentLocation,
  required final bool isMasterList,
  required final FeatureDestinationShellScope? shell,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final shell = this.shell;
    if (shell != null) {
      return _ScopedMasterDetailContent(
        destinations: destinations,
        currentLocation: currentLocation,
        isMasterList: isMasterList,
        shell: shell,
        child: child,
      );
    }

    return _UnscopedMasterDetailLayout(
      destinations: destinations,
      selectedLocation: selectedLocation,
      currentLocation: currentLocation,
      isMasterList: isMasterList,
      child: child,
    );
  }
}

class const _UnscopedMasterDetailLayout({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String currentLocation,
  required final bool isMasterList,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _UnscopedMasterDetailContent(
      destinations: destinations,
      selectedLocation: selectedLocation,
      currentLocation: currentLocation,
      isMasterList: isMasterList,
      isCompact:
          constraints.maxWidth <
          FeatureDestinationShellLayout.masterDetailBreakpoint,
      child: child,
    ),
  );
}

class const _ScopedMasterDetailContent({
  required final List<FeatureNavigationDestination> destinations,
  required final String currentLocation,
  required final bool isMasterList,
  required final FeatureDestinationShellScope shell,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (shell.isCompact && isMasterList) {
      return FeatureDestinationMaster(
        destinations: destinations,
        selectedLocation: '',
        currentLocation: currentLocation,
        useStackNavigation: true,
      );
    }

    return isMasterList && !shell.isCompact ? const SizedBox.shrink() : child;
  }
}

class const _UnscopedMasterDetailContent({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String currentLocation,
  required final bool isMasterList,
  required final bool isCompact,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isCompact
      ? _CompactMasterDetailContent(
          destinations: destinations,
          currentLocation: currentLocation,
          isMasterList: isMasterList,
          child: child,
        )
      : _WideMasterDetailContent(
          destinations: destinations,
          selectedLocation: selectedLocation,
          currentLocation: currentLocation,
          isMasterList: isMasterList,
          child: child,
        );
}

class const _CompactMasterDetailContent({
  required final List<FeatureNavigationDestination> destinations,
  required final String currentLocation,
  required final bool isMasterList,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isMasterList
      ? FeatureDestinationMaster(
          destinations: destinations,
          selectedLocation: '',
          currentLocation: currentLocation,
          useStackNavigation: true,
        )
      : child;
}

class const _WideMasterDetailContent({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String currentLocation,
  required final bool isMasterList,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: FeatureDestinationShellLayout.masterPaneWidth,
        child: FeatureDestinationMaster(
          destinations: destinations,
          selectedLocation: isMasterList ? '' : selectedLocation,
          currentLocation: currentLocation,
          useStackNavigation: false,
        ),
      ),
      VerticalDivider(
        width: 1,
        thickness: 1,
        color: context.auraColors.outline,
      ),
      Expanded(child: isMasterList ? const SizedBox.shrink() : child),
    ],
  );
}
