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
      options: _agentsSkillsTabOptions(),
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
    final pending = request.pending;
    if (pending.value || request.next == value) return;

    await _runPendingAgentTabNavigation((
      pending: pending,
      context: context,
      navigate: () => _finishNavigation(
        _agentTabNavigation(context, ref, workspaceId, request.next),
      ),
    ));
  }
}

typedef _PendingAgentTabNavigation = ({
  ValueNotifier<bool> pending,
  BuildContext context,
  Future<void> Function() navigate,
});

Future<void> _runPendingAgentTabNavigation(
  _PendingAgentTabNavigation request,
) async {
  request.pending.value = true;
  try {
    await request.navigate();
  } finally {
    if (request.context.mounted) request.pending.value = false;
  }
}

List<AuraTabOption<AgentDestination>> _agentsSkillsTabOptions() => [
  _agentTabOption(.agents, LocaleKeys.related_lists_agents),
  _agentTabOption(.skills, LocaleKeys.related_lists_skills),
];

AuraTabOption<AgentDestination> _agentTabOption(
  AgentDestination destination,
  String titleKey,
) => AuraTabOption(
  value: destination,
  title: TextLocale(titleKey),
  semanticLabel: titleKey.tr(),
);

typedef _AgentTabNavigation = ({
  BuildContext context,
  GoRouter router,
  DraftExitRegistry registry,
  String workspaceId,
  AgentDestination next,
});

_AgentTabNavigation _agentTabNavigation(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  AgentDestination next,
) => (
  context: context,
  router: GoRouter.of(context),
  registry: ref.read(draftExitRegistryProvider),
  workspaceId: workspaceId,
  next: next,
);

Future<void> _finishNavigation(_AgentTabNavigation request) async {
  final canExit = await request.registry.canExitActive(request.router);
  if (canExit && request.context.mounted) {
    request.router.go(
      _agentDestinationLocation(request.next, request.workspaceId),
    );
  } else {
    request.registry.releaseApprovals();
  }
}

String _agentDestinationLocation(
  AgentDestination destination,
  String workspaceId,
) => destination == .agents
    ? AgentsRoute(workspaceId: workspaceId).location
    : SkillsRoute(workspaceId: workspaceId).location;
