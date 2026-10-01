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
    final owner = useMemoized(() => guard, [workspaceId]);
    final workspaces = ref.watch(allWorkspacesProvider).asData?.value;
    final workspace = workspaces
        ?.where((item) => item.id == workspaceId)
        .firstOrNull;
    final settings = ref.watch(compactionSettingsProvider(workspaceId));
    final loaded = useRef(false);
    if (settings is AsyncData) loaded.value = true;

    return DraftExitScope(
      guard: owner,
      child: AuraScreen(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AuraText(
              child: Text(workspace?.name ?? workspaceId),
              style: .heading6,
            ),
            const TextLocale(LocaleKeys.navigation_workspace_settings_scope),
            if (loaded.value)
              AuraColumn(
                children: [
                  if (settings.hasError)
                    _SettingsLoadError(workspaceId: workspaceId),
                  CompactionSettingsSection(
                    workspaceId: workspaceId,
                    guard: owner,
                    key: ValueKey(workspaceId),
                  ),
                ],
              )
            else if (settings.hasError)
              _SettingsLoadError(workspaceId: workspaceId)
            else
              switch (settings) {
                AsyncData() => const SizedBox.shrink(),
                AsyncLoading() => const Center(child: AuraSpinner()),
                AsyncError() => _SettingsLoadError(workspaceId: workspaceId),
              },
          ],
        ),
        appBar: const AuraAppBarWithDrawer(
          title: TextLocale(LocaleKeys.navigation_workspace_settings),
        ),
      ),
    );
  }
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
