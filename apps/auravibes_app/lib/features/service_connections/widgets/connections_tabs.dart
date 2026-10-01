import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ConnectionsTabs({
  required final String workspaceId,
  required final ConnectionDestination value,
  super.key,
}) extends HookConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = useState(false);

    return AuraTabs<ConnectionDestination>.selector(
      options: _connectionTabOptions(),
      value: value,
      onChanged: (next) =>
          unawaited(_navigate(context, ref, (pending: pending, next: next))),
    );
  }

  List<AuraTabOption<ConnectionDestination>> _connectionTabOptions() => [
    for (final destination in _connectionTabOrder)
      _connectionTabOption(destination),
  ];

  AuraTabOption<ConnectionDestination> _connectionTabOption(
    ConnectionDestination destination,
  ) {
    final key = switch (destination) {
      .overview => LocaleKeys.related_lists_overview,
      .providers => LocaleKeys.related_lists_providers,
      .services => LocaleKeys.related_lists_services,
      .tools => LocaleKeys.related_lists_tools,
      .credentials => LocaleKeys.related_lists_credentials,
    };

    return AuraTabOption(
      value: destination,
      title: TextLocale(key),
      semanticLabel: key.tr(),
    );
  }

  Future<void> _navigate(
    BuildContext context,
    WidgetRef ref,
    ({ValueNotifier<bool> pending, ConnectionDestination next}) request,
  ) async {
    final pending = request.pending;
    final next = request.next;
    if (pending.value || next == value) return;
    pending.value = true;
    await _continueNavigation(context, ref, pending, next);
  }

  Future<void> _continueNavigation(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> pending,
    ConnectionDestination next,
  ) async {
    final router = GoRouter.of(context);
    final registry = ref.read(draftExitRegistryProvider);
    try {
      await _navigateAfterExitApproval(context, registry, router, next);
    } finally {
      if (context.mounted) pending.value = false;
    }
  }

  Future<void> _navigateAfterExitApproval(
    BuildContext context,
    DraftExitRegistry registry,
    GoRouter router,
    ConnectionDestination next,
  ) async {
    final canExit = await registry.canExitActive(router);
    if (canExit && context.mounted) {
      router.go(_location(next));
    } else {
      registry.releaseApprovals();
    }
  }

  String _location(ConnectionDestination value) {
    if (value == .tools) return ToolsRoute(workspaceId: workspaceId).location;

    return ServiceConnectionsRoute(
      workspaceId: workspaceId,
      view: value == .overview ? null : value.name,
    ).location;
  }
}

const List<ConnectionDestination> _connectionTabOrder = [
  ConnectionDestination.overview,
  ConnectionDestination.providers,
  ConnectionDestination.services,
  ConnectionDestination.tools,
  ConnectionDestination.credentials,
];
