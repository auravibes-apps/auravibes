import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/feature_destination_picker.dart';
import 'package:auravibes_app/widgets/feature_destination_shell_scope.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _FeatureDestinationAppBarState = ({
  bool isMasterList,
  bool isCompact,
  bool canPop,
});

class const FeatureDestinationAppBar({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String masterTitleKey,
  final List<Widget>? actions,
  super.key,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final currentUri = FeatureDestinations.currentUri(context);

    return _FeatureDestinationAppBarLayout(
      destinations: destinations,
      selectedLocation: selectedLocation,
      masterTitleKey: masterTitleKey,
      isMasterList:
          currentUri != null &&
          FeatureDestinations.isMasterLocation(currentUri),
      shell: .maybeOf(context),
      canPop: router?.canPop() ?? false,
      actions: actions,
    );
  }
}

class const _FeatureDestinationAppBarLayout({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String masterTitleKey,
  required final bool isMasterList,
  required final FeatureDestinationShellScope? shell,
  required final bool canPop,
  final List<Widget>? actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildContent);

  Widget _buildContent(BuildContext _, BoxConstraints constraints) =>
      _FeatureDestinationAppBarContent(
        destinations: destinations,
        selectedLocation: selectedLocation,
        masterTitleKey: masterTitleKey,
        state: _appBarState(constraints.maxWidth),
        actions: actions,
      );

  _FeatureDestinationAppBarState _appBarState(double maxWidth) => (
    isMasterList: isMasterList,
    isCompact:
        shell?.isCompact ??
        maxWidth < FeatureDestinationShellLayout.masterDetailBreakpoint,
    canPop: shell?.navigatorKey.currentState?.canPop() ?? canPop,
  );
}

class const _FeatureDestinationAppBarContent({
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
  required final String masterTitleKey,
  required final _FeatureDestinationAppBarState state,
  final List<Widget>? actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMasterList = state.isMasterList;
    final showBackButton = state.isCompact && !isMasterList && state.canPop;

    return AuraAppBarWithDrawer(
      title: _FeatureDestinationAppBarTitle(
        isMasterList: isMasterList,
        masterTitleKey: masterTitleKey,
        destinations: destinations,
        selectedLocation: selectedLocation,
      ),
      actions: isMasterList ? null : actions,
      leading: showBackButton ? const _FeatureDestinationBackButton() : null,
      showBackButton: showBackButton,
    );
  }
}

class const _FeatureDestinationAppBarTitle({
  required final bool isMasterList,
  required final String masterTitleKey,
  required final List<FeatureNavigationDestination> destinations,
  required final String selectedLocation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isMasterList
      ? TextLocale(masterTitleKey)
      : FeatureDestinationPicker(
          destinations: destinations,
          selectedLocation: selectedLocation,
        );
}

class const _FeatureDestinationBackButton() extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = useState(false);
    final backLabel = LocaleKeys.common_back.tr(context: context);

    return AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => unawaited(
        _popFeatureDestination(context, ref, pending, .maybeOf(context)),
      ),
      identifier: 'feature_destination_back',
      semanticLabel: backLabel,
      tooltip: backLabel,
    );
  }
}

Future<void> _popFeatureDestination(
  BuildContext context,
  WidgetRef ref,
  ValueNotifier<bool> pending,
  FeatureDestinationShellScope? shell,
) async {
  if (pending.value) return;
  pending.value = true;
  final router = GoRouter.of(context);
  final registry = ref.read(draftExitRegistryProvider);
  try {
    if (await registry.canExitActive(router) && context.mounted) {
      _popOrReleaseFeatureDestination(router, registry, shell);
    } else {
      registry.releaseApprovals();
    }
  } finally {
    if (context.mounted) pending.value = false;
  }
}

void _popOrReleaseFeatureDestination(
  GoRouter router,
  DraftExitRegistry registry,
  FeatureDestinationShellScope? shell,
) {
  if (shell?.navigatorKey.currentState?.canPop() ?? router.canPop()) {
    router.pop();
  } else {
    registry.releaseApprovals();
  }
}
