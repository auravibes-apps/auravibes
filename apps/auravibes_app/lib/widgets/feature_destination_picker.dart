import 'dart:async';

import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const FeatureDestinationPicker({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = destinations.firstWhere(
      (destination) => destination.location == selectedLocation,
    );

    return _FeatureDestinationPickerMenu(
      destinations: destinations,
      selected: selected,
      selectedLocation: selectedLocation,
      pending: useState(false),
      controller: useMemoized(AuraPopupMenuController.new),
    );
  }
}

class const _FeatureDestinationPickerMenu({
  required final List<FeatureNavigationDestination> destinations,
  required final FeatureNavigationDestination selected,
  required final String selectedLocation,
  required final ValueNotifier<bool> pending,
  required final AuraPopupMenuController controller,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraPopupMenu(
    child: _FeatureDestinationPickerButton(
      selected: selected,
      controller: controller,
    ),
    items: _items(context, ref),
    controller: controller,
  );

  List<AuraPopupMenuItem> _items(BuildContext context, WidgetRef ref) => [
    for (final destination in destinations) _item(context, ref, destination),
  ];

  AuraPopupMenuItem _item(
    BuildContext context,
    WidgetRef ref,
    FeatureNavigationDestination destination,
  ) => .new(
    title: TextLocale(destination.labelKey),
    onTap: _navigate(context, ref, destination),
    trailing: destination.location == selectedLocation
        ? const Icon(Icons.check)
        : null,
    variant: destination.location == selectedLocation ? .selected : .ghost,
  );

  VoidCallback _navigate(
    BuildContext context,
    WidgetRef ref,
    FeatureNavigationDestination destination,
  ) =>
      () => unawaited(
        FeatureDestinations.navigate((
          context: context,
          ref: ref,
          pending: pending,
          currentLocation: selectedLocation,
          location: destination.location,
          push: false,
        )),
      );
}

class const _FeatureDestinationPickerButton({
  required final FeatureNavigationDestination selected,
  required final AuraPopupMenuController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: controller.toggle,
    child: _FeatureDestinationPickerLabel(labelKey: selected.labelKey),
    key: const ValueKey('feature_destination_picker'),
    variant: .ghost,
    size: .small,
    identifier: 'feature_destination_picker',
    semanticLabel: selected.labelKey.tr(context: context),
  );
}

class const _FeatureDestinationPickerLabel({required final String labelKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      Flexible(child: TextLocale(labelKey, maxLines: 1)),
      const SizedBox(width: 4),
      const AuraIcon(Icons.arrow_drop_down, size: .small),
    ],
  );
}
