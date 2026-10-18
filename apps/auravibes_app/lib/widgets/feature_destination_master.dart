import 'dart:async';

import 'package:auravibes_app/widgets/app_drawer_menu_button.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const FeatureDestinationMaster({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String currentLocation,
  required final bool useStackNavigation,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _FeatureDestinationMasterContent(
        destinations: destinations,
        selectedLocation: selectedLocation,
        currentLocation: currentLocation,
        useStackNavigation: useStackNavigation,
        pending: useState(false),
      );
}

class const _FeatureDestinationMasterContent({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String currentLocation,
  required final bool useStackNavigation,
  required final ValueNotifier<bool> pending,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final list = _FeatureDestinationList(
      destinations: destinations,
      selectedLocation: selectedLocation,
      currentLocation: currentLocation,
      useStackNavigation: useStackNavigation,
      pending: pending,
    );
    if (useStackNavigation) return list;

    return _DockedFeatureDestinationMaster(child: list);
  }
}

class const _DockedFeatureDestinationMaster({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppDrawerMenuButton(),
          ),
        ),
      ),
      Expanded(child: child),
    ],
  );
}

class const _FeatureDestinationList({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String currentLocation,
  required final bool useStackNavigation,
  required final ValueNotifier<bool> pending,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      for (final destination in destinations)
        _FeatureDestinationTile(
          destination: destination,
          isSelected: destination.location == selectedLocation,
          currentLocation: currentLocation,
          useStackNavigation: useStackNavigation,
          pending: pending,
        ),
    ],
  );
}

class const _FeatureDestinationTile({
  required final FeatureNavigationDestination destination,
  required final bool isSelected,
  required final String currentLocation,
  required final bool useStackNavigation,
  required final ValueNotifier<bool> pending,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: _FeatureDestinationTileSemantics(
      isSelected: isSelected,
      child: _FeatureDestinationTileControl(
        destination: destination,
        isSelected: isSelected,
        onTap: () => _navigate(context, ref),
      ),
    ),
  );

  void _navigate(BuildContext context, WidgetRef ref) => unawaited(
    FeatureDestinations.navigate((
      context: context,
      ref: ref,
      pending: pending,
      currentLocation: currentLocation,
      location: destination.location,
      push: useStackNavigation,
    )),
  );
}

class const _FeatureDestinationTileSemantics({
  required final bool isSelected,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Semantics(child: child, selected: isSelected);
}

class const _FeatureDestinationTileControl({
  required final FeatureNavigationDestination destination,
  required final bool isSelected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _FeatureDestinationTileLabel(labelKey: destination.labelKey),
    key: ValueKey('feature-destination-${destination.location}'),
    onTap: onTap,
    variant: isSelected ? .selected : .ghost,
    semanticLabel: destination.labelKey.tr(context: context),
  );
}

class const _FeatureDestinationTileLabel({required final String labelKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextLocale(labelKey),
  );
}
