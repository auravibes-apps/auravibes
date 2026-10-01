import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
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

    return _WorkspaceSelectorRuntime(
      workspaceId: workspaceId,
      focus: focus,
      pending: pending,
    );
  }
}

class const _WorkspaceSelectorRuntime({
  required final String workspaceId,
  required final FocusNode focus,
  required final ValueNotifier<bool> pending,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listenForWorkspaceSwitchErrors(ref, context);

    return _WorkspaceSelectorViewState(
      workspaceId: workspaceId,
      focus: focus,
      pending: pending,
    );
  }
}

class const _WorkspaceSelectorViewState({
  required final String workspaceId,
  required final FocusNode focus,
  required final ValueNotifier<bool> pending,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final switchState = ref.watch(workspaceSwitcherProvider);
    final workspaces = ref.watch(allWorkspacesProvider);

    return _WorkspaceSelectorActionsView(
      workspaceId: workspaceId,
      focus: focus,
      pending: pending,
      switchState: switchState,
      workspaces: workspaces,
    );
  }
}

class const _WorkspaceSelectorActionsView({
  required final String workspaceId,
  required final FocusNode focus,
  required final ValueNotifier<bool> pending,
  required final WorkspaceSwitchState switchState,
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = _workspaceSelectorController(
      context: context,
      ref: ref,
      pending: pending,
      workspaceId: workspaceId,
    );

    return _WorkspaceSelectorSemantics(
      workspaces: workspaces,
      workspaceId: workspaceId,
      switchState: switchState,
      focus: focus,
      isNavigationPending: pending.value,
      onSwitch: controller.switchWorkspace,
      onNavigate: controller.selectAction,
    );
  }
}

void _listenForWorkspaceSwitchErrors(WidgetRef ref, BuildContext context) {
  ref.listen(
    workspaceSwitcherProvider,
    (_, next) => _showWorkspaceSwitchError(context, next),
  );
}

void _showWorkspaceSwitchError(
  BuildContext context,
  WorkspaceSwitchState state,
) {
  final errorKey = state.errorLocalizationKey;
  if (state.status != .error || errorKey == null) return;
  final _ = AuraSnackBars.show(
    context: context,
    content: TextLocale(errorKey),
    variant: .error,
  );
}

class const _WorkspaceSelectorSemantics({
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
  required final String workspaceId,
  required final WorkspaceSwitchState switchState,
  required final FocusNode focus,
  required final bool isNavigationPending,
  required final ValueChanged<String?> onSwitch,
  required final ValueChanged<String?> onNavigate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('workspace_selector'),
    child: _WorkspaceSelectorContent(
      workspaces: workspaces,
      workspaceId: workspaceId,
      switchState: switchState,
      focus: focus,
      isNavigationPending: isNavigationPending,
      onSwitch: onSwitch,
      onNavigate: onNavigate,
    ),
    identifier: 'workspace_selector',
  );
}

class const _WorkspaceSelectorController({
  required final BuildContext context,
  required final WidgetRef ref,
  required final ValueNotifier<bool> pending,
  required final String workspaceId,
}) {
  bool get _isPending => pending.value;
  set _isPending(bool value) => pending.value = value;

  void switchWorkspace(String? target) {
    if (target == null || target == workspaceId) return;
    ref.read(workspaceSwitcherProvider.notifier).switchToWorkspace(target);
  }

  void selectAction(String? action) => unawaited(_navigateToAction(action));

  Future<void> _navigateToAction(String? action) async {
    if (_isPending) return;
    final location = _workspaceActionLocation(workspaceId, action);
    if (location == null) return;
    final router = GoRouter.of(context);
    if (router.state.uri.toString() == location) return;
    _isPending = true;
    try {
      if (await _canNavigateWorkspace(router)) router.go(location);
    } finally {
      if (context.mounted) _isPending = false;
    }
  }

  Future<bool> _canNavigateWorkspace(GoRouter router) async {
    final registry = ref.read(draftExitRegistryProvider);
    if (await registry.canExitActive(router) && context.mounted) return true;
    registry.releaseApprovals();

    return false;
  }
}

_WorkspaceSelectorController _workspaceSelectorController({
  required BuildContext context,
  required WidgetRef ref,
  required ValueNotifier<bool> pending,
  required String workspaceId,
}) => .new(
  context: context,
  ref: ref,
  pending: pending,
  workspaceId: workspaceId,
);

String? _workspaceActionLocation(String workspaceId, String? action) =>
    switch (action) {
      'manage' => WorkspaceManagementRoute(workspaceId: workspaceId).location,
      'create' => WorkspaceCreateRoute(workspaceId: workspaceId).location,
      'connect' => WorkspaceManagementRoute(
        workspaceId: workspaceId,
        view: 'connect',
      ).location,
      'settings' => WorkspaceSettingsRoute(workspaceId: workspaceId).location,
      _ => null,
    };

class const _WorkspaceSelectorContent({
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
  required final String workspaceId,
  required final WorkspaceSwitchState switchState,
  required final FocusNode focus,
  required final bool isNavigationPending,
  required final ValueChanged<String?> onSwitch,
  required final ValueChanged<String?> onNavigate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _WorkspaceSwitchControl(
        workspaces: workspaces,
        workspaceId: workspaceId,
        switchState: switchState,
        focus: focus,
        onSwitch: onSwitch,
      ),
      _WorkspaceActionSelector(
        switchState: switchState,
        isNavigationPending: isNavigationPending,
        onNavigate: onNavigate,
      ),
    ],
    crossAxisAlignment: .stretch,
  );
}

class const _WorkspaceSwitchControl({
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
  required final String workspaceId,
  required final WorkspaceSwitchState switchState,
  required final FocusNode focus,
  required final ValueChanged<String?> onSwitch,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (switchState.status) {
    .loading => const _WorkspaceSwitchLoading(),
    _ => _WorkspaceSwitchOptions(
      workspaces: workspaces,
      workspaceId: workspaceId,
      switchState: switchState,
      focus: focus,
      onSwitch: onSwitch,
    ),
  };
}

class const _WorkspaceSwitchLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: const TextLocale(LocaleKeys.workspace_management_switch_loading),
    container: true,
    excludeSemantics: true,
    label: LocaleKeys.workspace_management_switch_loading.tr(),
    role: .status,
  );
}

class const _WorkspaceSwitchOptions({
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
  required final String workspaceId,
  required final WorkspaceSwitchState switchState,
  required final FocusNode focus,
  required final ValueChanged<String?> onSwitch,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _WorkspaceChoices(
          workspaces: workspaces,
          workspaceId: workspaceId,
          focus: focus,
          onChanged: onSwitch,
        ),
      ),
      if (switchState.status == .error)
        _WorkspaceSwitchRetryButton(
          workspaceId: switchState.targetWorkspaceId,
          onSwitch: onSwitch,
        ),
    ],
  );
}

class const _WorkspaceSwitchRetryButton({
  required final String? workspaceId,
  required final ValueChanged<String?> onSwitch,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.refresh,
    onPressed: () => onSwitch(workspaceId),
    key: const ValueKey<String>('workspace_switch_retry'),
    tooltip: LocaleKeys.workspace_management_switch_retry.tr(),
  );
}

class const _WorkspaceActionSelector({
  required final WorkspaceSwitchState switchState,
  required final bool isNavigationPending,
  required final ValueChanged<String?> onNavigate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: _workspaceActionOptions,
    key: const ValueKey<String>('workspace_actions'),
    onChanged: onNavigate,
    placeholder: const TextLocale(LocaleKeys.navigation_workspace_actions),
    isEnabled: !isNavigationPending && switchState.status != .loading,
  );
}

const _workspaceActionOptions = <AuraDropdownOption<String>>[
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
];

class const _WorkspaceChoices({
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
  required final String workspaceId,
  required final FocusNode focus,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (workspaces) {
    AsyncData(:final value) => _WorkspaceOptionsLoaded.fromWorkspaces(
      workspaces: value,
      workspaceId: workspaceId,
      focus: focus,
      onChanged: onChanged,
    ),
    AsyncLoading() => const TextLocale(LocaleKeys.workspace_management_loading),
    AsyncError() => const TextLocale(
      LocaleKeys.workspace_management_unexpected_error,
    ),
  };
}

class _WorkspaceOptionsLoaded extends StatelessWidget {
  new fromWorkspaces({
    required List<WorkspaceEntity> workspaces,
    required String workspaceId,
    required FocusNode focus,
    required ValueChanged<String?> onChanged,
  }) : this._(
         options: [
           for (final workspace in workspaces)
             AuraDropdownOption(
               value: workspace.id,
               child: Text('${workspace.name} / ${_identity(workspace)}'),
             ),
         ],
         value: _selectedWorkspaceId(workspaces, workspaceId),
         focus: focus,
         onChanged: onChanged,
       );

  const new _({
    required this.options,
    required this.value,
    required this.focus,
    required this.onChanged,
  });

  final List<AuraDropdownOption<String>> options;
  final String? value;
  final FocusNode focus;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: options,
    key: const ValueKey<String>('workspace_choice'),
    value: value,
    onChanged: onChanged,
    focusNode: focus,
    semanticLabel: LocaleKeys.workspace_management_title.tr(),
  );
}

String? _selectedWorkspaceId(
  List<WorkspaceEntity> workspaces,
  String workspaceId,
) => _containsWorkspace(workspaces, workspaceId) ? workspaceId : null;

bool _containsWorkspace(List<WorkspaceEntity> workspaces, String workspaceId) =>
    workspaces.any((workspace) => workspace.id == workspaceId);

String _identity(WorkspaceEntity workspace) =>
    (workspace.type == .local
            ? LocaleKeys.navigation_local_workspace
            : LocaleKeys.navigation_cloud_workspace)
        .tr();
