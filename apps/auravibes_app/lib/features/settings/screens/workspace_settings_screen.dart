import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/settings/models/workspace_settings_draft_guards.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/widgets/compaction_settings_section.dart';
import 'package:auravibes_app/features/settings/widgets/scoped_verification_section.dart';
import 'package:auravibes_app/features/settings/widgets/workspace_agent_lifecycle_hooks_section.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceSettingsScreen({
  required final String workspaceId,
  required final DraftExitGuard guard,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = _useWorkspaceSettingsSnapshot(ref, workspaceId, guard);

    return DraftExitScope(
      guard: guard,
      child: _WorkspaceSettingsView(
        workspaceId: workspaceId,
        workspaceName: view.workspaceName,
        guards: view.guards,
        settings: view.settings,
        loaded: view.loaded,
      ),
    );
  }
}

typedef _WorkspaceSettingsSnapshot = ({
  WorkspaceSettingsDraftGuards guards,
  String workspaceName,
  AsyncValue<CompactionSettings> settings,
  bool loaded,
});

_WorkspaceSettingsSnapshot _useWorkspaceSettingsSnapshot(
  WidgetRef ref,
  String workspaceId,
  DraftExitGuard guard,
) {
  final guards = _useWorkspaceSettingsDraftGuards(guard, workspaceId);
  final settings = ref.watch(compactionSettingsProvider(workspaceId));

  return (
    guards: guards,
    workspaceName: _workspaceSettingsName(ref, workspaceId),
    settings: settings,
    loaded: _useWorkspaceSettingsLoaded(settings),
  );
}

WorkspaceSettingsDraftGuards _useWorkspaceSettingsDraftGuards(
  DraftExitGuard guard,
  String workspaceId,
) {
  final guards = useMemoized(() => WorkspaceSettingsDraftGuards(guard), [
    guard,
    workspaceId,
  ]);
  useEffect(() => guards.dispose, [guards]);

  return guards;
}

bool _useWorkspaceSettingsLoaded(AsyncValue<CompactionSettings> settings) {
  final loaded = useRef(false);
  if (settings is AsyncData) loaded.value = true;

  return loaded.value;
}

String _workspaceSettingsName(WidgetRef ref, String workspaceId) {
  final workspaces = ref.watch(allWorkspacesProvider).asData?.value;
  final workspace = workspaces
      ?.where((item) => item.id == workspaceId)
      .firstOrNull;

  return workspace?.name ?? workspaceId;
}

class const _WorkspaceSettingsView({
  required final String workspaceId,
  required final String workspaceName,
  required final WorkspaceSettingsDraftGuards guards,
  required final AsyncValue<CompactionSettings> settings,
  required final bool loaded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _WorkspaceSettingsHeading(workspaceName: workspaceName),
        _WorkspaceSetupPreflightEntry(workspaceId: workspaceId),
        _WorkspaceSettingsContent(
          workspaceId: workspaceId,
          guards: guards,
          settings: settings,
          loaded: loaded,
        ),
      ],
    ),
    appBar: const AuraAppBarWithDrawer(
      title: TextLocale(LocaleKeys.navigation_workspace_settings),
    ),
  );
}

class const _WorkspaceSettingsHeading({required final String workspaceName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: Text(workspaceName), style: .heading6),
      const TextLocale(LocaleKeys.navigation_workspace_settings_scope),
    ],
  );
}

class const _WorkspaceSetupPreflightEntry({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    style: .border,
    child: AuraColumn(
      crossAxisAlignment: .start,
      children: [
        AuraText(
          child: const TextLocale('workspace_setup_preflight.entry_title'),
          style: .heading6,
        ),
        const TextLocale('workspace_setup_preflight.entry_description'),
        AuraButton(
          onPressed: () => unawaited(
            FeatureDestinations.push<void>(
              context,
              WorkspaceSetupPreflightRoute(workspaceId: workspaceId).location,
            ),
          ),
          child: const TextLocale('workspace_setup_preflight.open'),
          variant: .ghost,
          key: const ValueKey('workspace_settings_setup_preflight'),
        ),
      ],
    ),
  );
}

class const _WorkspaceSettingsContent({
  required final String workspaceId,
  required final WorkspaceSettingsDraftGuards guards,
  required final AsyncValue<CompactionSettings> settings,
  required final bool loaded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (loaded) {
      return _LoadedWorkspaceSettings(
        workspaceId: workspaceId,
        guards: guards,
        settings: settings,
      );
    }
    if (settings.hasError) return _SettingsLoadError(workspaceId: workspaceId);

    return switch (settings) {
      AsyncData() => const SizedBox.shrink(),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError() => _SettingsLoadError(workspaceId: workspaceId),
    };
  }
}

class const _LoadedWorkspaceSettings({
  required final String workspaceId,
  required final WorkspaceSettingsDraftGuards guards,
  required final AsyncValue<CompactionSettings> settings,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (settings.hasError) _SettingsLoadError(workspaceId: workspaceId),
      CompactionSettingsSection(
        workspaceId: workspaceId,
        guard: guards.compaction,
        key: ValueKey((workspaceId: workspaceId, section: 'compaction')),
      ),
      ScopedVerificationSection(
        workspaceId: workspaceId,
        guard: guards.verification,
        key: ValueKey(workspaceId),
      ),
      WorkspaceAgentLifecycleHooksSection(
        workspaceId: workspaceId,
        key: ValueKey('hooks-$workspaceId'),
      ),
    ],
  );
}

class const _SettingsLoadError({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraColumn(
    children: [
      const TextLocale(LocaleKeys.navigation_workspace_settings_error),
      AuraButton(
        onPressed: () =>
            ref.invalidate(compactionSettingsProvider(workspaceId)),
        child: const TextLocale(LocaleKeys.route_state_retry),
      ),
    ],
  );
}
