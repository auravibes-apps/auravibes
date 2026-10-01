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

class const AgentsSkillsTabs({
  required final String workspaceId,
  required final AgentDestination value,
  super.key,
}) extends HookConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = useState(false);

    return AuraTabs<AgentDestination>.selector(
      options: [
        AuraTabOption(
          value: .agents,
          title: const TextLocale(LocaleKeys.related_lists_agents),
          semanticLabel: LocaleKeys.related_lists_agents.tr(),
        ),
        AuraTabOption(
          value: .skills,
          title: const TextLocale(LocaleKeys.related_lists_skills),
          semanticLabel: LocaleKeys.related_lists_skills.tr(),
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
    ({ValueNotifier<bool> pending, AgentDestination next}) request,
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

  String _location(AgentDestination value) {
    return value == .agents
        ? AgentsRoute(workspaceId: workspaceId).location
        : SkillsRoute(workspaceId: workspaceId).location;
  }
}
