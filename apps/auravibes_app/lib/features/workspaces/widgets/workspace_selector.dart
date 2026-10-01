import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Shared shell control. WorkspaceSwitcher owns confirmation and persistence.
class const WorkspaceSelector({required final String workspaceId, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = useFocusNode();
    final pending = useState(false);
    final switchState = ref.watch(workspaceSwitcherProvider);
    ref.listen(workspaceSwitcherProvider, (_, next) {
      final errorKey = next.errorLocalizationKey;
      if (next.status != .error || errorKey == null) return;
      final _ = AuraSnackBars.show(
        context: context,
        content: TextLocale(errorKey),
        variant: .error,
      );
    });
    final workspaces = ref.watch(allWorkspacesProvider);

    return Semantics(
      key: const ValueKey<String>('workspace_selector'),
      child: AuraColumn(
        children: [
          if (switchState.status == .loading)
            Semantics(
              child: const TextLocale(
                LocaleKeys.workspace_management_switch_loading,
              ),
              container: true,
              excludeSemantics: true,
              label: LocaleKeys.workspace_management_switch_loading.tr(),
              role: .status,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _WorkspaceChoices(
                    workspaces: workspaces,
                    workspaceId: workspaceId,
                    focus: focus,
                    onChanged: (value) => _switch(ref, value),
                  ),
                ),
                if (switchState.status == .error)
                  AuraIconButton(
                    icon: Icons.refresh,
                    onPressed: () =>
                        _switch(ref, switchState.targetWorkspaceId),
                    key: const ValueKey<String>('workspace_switch_retry'),
                    tooltip: LocaleKeys.workspace_management_switch_retry.tr(),
                  ),
              ],
            ),
          AuraDropdownSelector<String>(
            options: const [
              AuraDropdownOption(
                value: 'manage',
                child: TextLocale(LocaleKeys.workspace_management_title),
              ),
              AuraDropdownOption(
                value: 'create',
                child: TextLocale(LocaleKeys.navigation_create_workspace),
              ),
              AuraDropdownOption(
                value: 'connect',
                child: TextLocale(LocaleKeys.navigation_connect_cloud),
              ),
              AuraDropdownOption(
                value: 'settings',
                child: TextLocale(LocaleKeys.navigation_workspace_settings),
              ),
            ],
            key: const ValueKey<String>('workspace_actions'),
            onChanged: (value) =>
                unawaited(_navigate(context, ref, pending, value)),
            placeholder: const TextLocale(
              LocaleKeys.navigation_workspace_actions,
            ),
            isEnabled: !pending.value && switchState.status != .loading,
          ),
        ],
        crossAxisAlignment: .stretch,
      ),
      identifier: 'workspace_selector',
    );
  }

  void _switch(WidgetRef ref, String? target) {
    if (target == null || target == workspaceId) return;
    ref.read(workspaceSwitcherProvider.notifier).switchToWorkspace(target);
  }

  Future<void> _navigate(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> pending,
    String? action,
  ) async {
    if (pending.value || action == null) return;
    final location = switch (action) {
      'manage' => WorkspaceManagementRoute(workspaceId: workspaceId).location,
      'create' => WorkspaceCreateRoute(workspaceId: workspaceId).location,
      'connect' => WorkspaceManagementRoute(
        workspaceId: workspaceId,
        view: 'connect',
      ).location,
      'settings' => WorkspaceSettingsRoute(workspaceId: workspaceId).location,
      _ => null,
    };
    if (location == null) return;
    final router = GoRouter.of(context);
    if (router.state.uri.toString() == location) return;
    pending.value = true;
    final registry = ref.read(draftExitRegistryProvider);
    try {
      if (!await registry.canExitActive(router) || !context.mounted) {
        registry.releaseApprovals();

        return;
      }
      router.go(location);
    } finally {
      if (context.mounted) pending.value = false;
    }
  }
}

class const _WorkspaceChoices({
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
  required final String workspaceId,
  required final FocusNode focus,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (workspaces) {
    AsyncData(:final value) => AuraDropdownSelector<String>(
      options: [
        for (final workspace in value)
          AuraDropdownOption(
            value: workspace.id,
            child: Text('${workspace.name} / ${_identity(workspace)}'),
          ),
      ],
      key: const ValueKey<String>('workspace_choice'),
      value: value.any((workspace) => workspace.id == workspaceId)
          ? workspaceId
          : null,
      onChanged: onChanged,
      focusNode: focus,
      semanticLabel: LocaleKeys.workspace_management_title.tr(),
    ),
    AsyncLoading() => const TextLocale(LocaleKeys.workspace_management_loading),
    AsyncError() => const TextLocale(
      LocaleKeys.workspace_management_unexpected_error,
    ),
  };

  String _identity(WorkspaceEntity workspace) =>
      (workspace.type == .local
              ? LocaleKeys.navigation_local_workspace
              : LocaleKeys.navigation_cloud_workspace)
          .tr();
}
