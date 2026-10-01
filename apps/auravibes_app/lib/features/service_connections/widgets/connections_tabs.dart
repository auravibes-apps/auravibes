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
      options: [
        AuraTabOption(
          value: .overview,
          title: const TextLocale(LocaleKeys.related_lists_overview),
          semanticLabel: LocaleKeys.related_lists_overview.tr(),
        ),
        AuraTabOption(
          value: .providers,
          title: const TextLocale(LocaleKeys.related_lists_providers),
          semanticLabel: LocaleKeys.related_lists_providers.tr(),
        ),
        AuraTabOption(
          value: .services,
          title: const TextLocale(LocaleKeys.related_lists_services),
          semanticLabel: LocaleKeys.related_lists_services.tr(),
        ),
        AuraTabOption(
          value: .tools,
          title: const TextLocale(LocaleKeys.related_lists_tools),
          semanticLabel: LocaleKeys.related_lists_tools.tr(),
        ),
        AuraTabOption(
          value: .credentials,
          title: const TextLocale(LocaleKeys.related_lists_credentials),
          semanticLabel: LocaleKeys.related_lists_credentials.tr(),
        ),
      ],
      value: value,
      onChanged: (next) =>
          unawaited(_navigate(context, ref, (pending: pending, next: next))),
    );
  }

  Future<void> _navigate(
    BuildContext context,
    WidgetRef ref,
    ({ValueNotifier<bool> pending, ConnectionDestination next}) request,
  ) async {
    if (request.pending.value || request.next == value) return;
    request.pending.value = true;
    final router = GoRouter.of(context);
    final registry = ref.read(draftExitRegistryProvider);
    try {
      if (await registry.canExitActive(router) && context.mounted) {
        router.go(_location(request.next));
      } else {
        registry.releaseApprovals();
      }
    } finally {
      if (context.mounted) request.pending.value = false;
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
