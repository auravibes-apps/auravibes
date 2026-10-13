import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/widgets/compaction_settings_section.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
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
      guard: view.guard,
      child: _WorkspaceSettingsView(
        workspaceId: workspaceId,
        workspaceName: view.workspaceName,
        guard: view.guard,
        settings: view.settings,
        loaded: view.loaded,
      ),
    );
  }
}

typedef _WorkspaceSettingsSnapshot = ({
  DraftExitGuard guard,
  String workspaceName,
  AsyncValue<CompactionSettings> settings,
  bool loaded,
});

_WorkspaceSettingsSnapshot _useWorkspaceSettingsSnapshot(
  WidgetRef ref,
  String workspaceId,
  DraftExitGuard guard,
) {
  final owner = useMemoized(() => guard, [workspaceId]);
  final settings = ref.watch(compactionSettingsProvider(workspaceId));
  final loaded = useRef(false);
  if (settings is AsyncData) loaded.value = true;

  return (
    guard: owner,
    workspaceName: _workspaceSettingsName(ref, workspaceId),
    settings: settings,
    loaded: loaded.value,
  );
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
  required final DraftExitGuard guard,
  required final AsyncValue<CompactionSettings> settings,
  required final bool loaded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _WorkspaceSettingsHeading(workspaceName: workspaceName),
        _WorkspaceSettingsContent(
          workspaceId: workspaceId,
          guard: guard,
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

class const _WorkspaceSettingsContent({
  required final String workspaceId,
  required final DraftExitGuard guard,
  required final AsyncValue<CompactionSettings> settings,
  required final bool loaded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (loaded) {
      return _LoadedWorkspaceSettings(
        workspaceId: workspaceId,
        guard: guard,
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
  required final DraftExitGuard guard,
  required final AsyncValue<CompactionSettings> settings,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (settings.hasError) _SettingsLoadError(workspaceId: workspaceId),
      CompactionSettingsSection(
        workspaceId: workspaceId,
        guard: guard,
        key: ValueKey(workspaceId),
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
