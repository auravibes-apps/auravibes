import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/delete_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/duplicate_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/edit_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/select_workspace_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/stable_ui_selector.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/experimental/mutation.dart';

final _logger = Logger('workspace_management_screen');

const _deleteConfirmationActions = AuraConfirmDialogActions(
  confirmLabel: TextLocale(LocaleKeys.common_delete),
  cancelLabel: TextLocale(LocaleKeys.common_cancel),
);
const _removeConfirmationActions = AuraConfirmDialogActions(
  confirmLabel: TextLocale(LocaleKeys.common_remove),
  cancelLabel: TextLocale(LocaleKeys.common_cancel),
);
const _switchConfirmationActions = AuraConfirmDialogActions(
  confirmLabel: TextLocale(LocaleKeys.common_confirm),
  cancelLabel: TextLocale(LocaleKeys.common_cancel),
);

class const WorkspaceManagementScreen({
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _WorkspaceManagementView(workspaceId: workspaceId);
}

class const _WorkspaceManagementView({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(allWorkspacesProvider);
    final accounts = ref.watch(cloudAccountsProvider);
    final editingWorkspace = ref.watch(
      workspaceManagementModeProvider.select((state) => state.editingWorkspace),
    );

    return _WorkspaceManagementLayout(
      activeWorkspaceId: workspaceId,
      accounts: accounts,
      editingWorkspace: editingWorkspace,
      workspaces: workspaces,
    );
  }
}

class const _WorkspaceManagementLayout({
  required final String activeWorkspaceId,
  required final AsyncValue<List<CloudAccountSession>> accounts,
  required final WorkspaceEntity? editingWorkspace,
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _WorkspaceManagementContent(
        activeWorkspaceId: activeWorkspaceId,
        accounts: accounts,
        editingWorkspace: editingWorkspace,
        workspaces: workspaces,
      ),
      appBar: const _WorkspaceManagementAppBar(),
    );
  }
}

class const _WorkspaceManagementAppBar()
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBarWithDrawer(
      title: const TextLocale(LocaleKeys.workspace_management_title),
      leading: Semantics(
        key: const ValueKey<String>('workspace_management_back'),
        child: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        identifier: 'workspace_management_back',
      ),
    );
  }
}

class const _WorkspaceManagementContent({
  required final String activeWorkspaceId,
  required final AsyncValue<List<CloudAccountSession>> accounts,
  required final WorkspaceEntity? editingWorkspace,
  required final AsyncValue<List<WorkspaceEntity>> workspaces,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (workspaces) {
      AsyncData(:final value) => _WorkspaceList(
        activeWorkspaceId: activeWorkspaceId,
        accounts: accounts,
        editingWorkspace: editingWorkspace,
        workspaces: value,
      ),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError() => const Center(
        child: TextLocale(LocaleKeys.workspace_management_load_error),
      ),
    };
  }
}

class const _WorkspaceList({
  required final String activeWorkspaceId,
  required final AsyncValue<List<CloudAccountSession>> accounts,
  required final WorkspaceEntity? editingWorkspace,
  required final List<WorkspaceEntity> workspaces,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _WorkspaceListView(
    activeWorkspaceId: activeWorkspaceId,
    accounts: accounts,
    editingWorkspace: editingWorkspace,
    workspaces: workspaces,
  );
}

class const _WorkspaceListView({
  required final String activeWorkspaceId,
  required final AsyncValue<List<CloudAccountSession>> accounts,
  required final WorkspaceEntity? editingWorkspace,
  required final List<WorkspaceEntity> workspaces,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WorkspaceListView> createState() => _WorkspaceListViewState();
}

class _WorkspaceListViewState extends ConsumerState<_WorkspaceListView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return _WorkspaceListSections(
      data: _data(),
      actions: _actions(context),
      onSearchChanged: _updateSearchQuery,
    );
  }

  _WorkspaceListData _data() {
    final searchQuery = _searchQuery.trim().toLowerCase();
    final filteredWorkspaces = _filterWorkspaces(
      widget.workspaces,
      searchQuery,
    );

    return _WorkspaceListData(
      activeWorkspaceId: widget.activeWorkspaceId,
      accounts: widget.accounts,
      editingWorkspace: widget.editingWorkspace,
      isSearchActive: searchQuery.isNotEmpty,
      local: _localWorkspaces(filteredWorkspaces),
      connected: _connectedWorkspaces(filteredWorkspaces),
      searchQuery: searchQuery,
      workspaces: widget.workspaces,
    );
  }

  void _updateSearchQuery(String query) {
    setState(() => _searchQuery = query);
  }

  List<WorkspaceEntity> _localWorkspaces(List<WorkspaceEntity> workspaces) {
    return workspaces.where((item) => item.cloudWorkspaceId == null).toList();
  }

  List<WorkspaceEntity> _connectedWorkspaces(List<WorkspaceEntity> workspaces) {
    return workspaces.where((item) => item.cloudWorkspaceId != null).toList();
  }

  _WorkspaceListActions _actions(BuildContext context) {
    return _WorkspaceListActions(
      context: context,
      ref: ref,
      activeWorkspaceId: widget.activeWorkspaceId,
    );
  }
}

List<WorkspaceEntity> _filterWorkspaces(
  List<WorkspaceEntity> workspaces,
  String query,
) {
  if (query.isEmpty) return workspaces;

  return workspaces
      .where((workspace) => _matchesWorkspaceName(workspace.name, query))
      .toList();
}

bool _matchesWorkspaceName(String name, String query) =>
    query.isEmpty || name.toLowerCase().contains(query);

List<CloudWorkspaceSummary> _matchingCloudWorkspaces(
  List<CloudWorkspaceSummary> workspaces,
  String query,
) => workspaces
    .where((workspace) => _matchesWorkspaceName(workspace.name, query))
    .toList();

bool _isAvailableCloudWorkspace(
  CloudWorkspaceSummary workspace,
  String accountId,
  List<WorkspaceEntity> localWorkspaces,
) => !localWorkspaces.any(
  (local) =>
      local.cloudWorkspaceId == workspace.id.toString() &&
      local.cloudAccountId == accountId,
);

List<CloudWorkspaceSummary> _availableCloudWorkspaces(
  List<CloudWorkspaceSummary> workspaces,
  CloudAccountSession account,
  List<WorkspaceEntity> localWorkspaces,
) => workspaces
    .where(
      (workspace) => _isAvailableCloudWorkspace(
        workspace,
        account.userId,
        localWorkspaces,
      ),
    )
    .toList();

bool _hasLoadedCloudWorkspaceData(AsyncValue<CloudWorkspaceViewState?> state) =>
    switch (state) {
      AsyncData(value: null) => true,
      AsyncData(value: final value?) => !value.authenticationRequired,
      AsyncLoading() || AsyncError() => false,
    };

typedef _CloudAccountWorkspaceState = ({
  CloudAccountSession account,
  AsyncValue<CloudWorkspaceViewState?> state,
});

List<_CloudAccountWorkspaceState> _watchCloudAccountStates(
  WidgetRef ref,
  List<CloudAccountSession> accounts,
) => [
  for (final account in accounts)
    (
      account: account,
      state: ref.watch(cloudWorkspaceStateProvider(account.userId)),
    ),
];

bool _isMatchingAvailableCloudWorkspace(
  CloudWorkspaceSummary workspace,
  String query,
  CloudAccountSession account,
  List<WorkspaceEntity> localWorkspaces,
) =>
    _matchesWorkspaceName(workspace.name, query) &&
    _isAvailableCloudWorkspace(workspace, account.userId, localWorkspaces);

bool _hasMatchingAvailableCloudWorkspace({
  required AsyncValue<CloudWorkspaceViewState?> state,
  required CloudAccountSession account,
  required _WorkspaceListData data,
}) => switch (state) {
  AsyncData(value: final value?) when !value.authenticationRequired =>
    value.workspaces.any(
      (workspace) => _isMatchingAvailableCloudWorkspace(
        workspace,
        data.searchQuery,
        account,
        data.workspaces,
      ),
    ),
  AsyncData() || AsyncLoading() || AsyncError() => false,
};

bool _hasNoCloudAccounts(AsyncValue<List<CloudAccountSession>> accounts) =>
    switch (accounts) {
      AsyncData(:final value) => value.isEmpty,
      AsyncLoading() || AsyncError() => false,
    };

Set<String> _matchingCloudAccountIds(
  List<_CloudAccountWorkspaceState> accountStates,
  _WorkspaceListData data,
) => {
  for (final accountState in accountStates)
    if (_hasMatchingAvailableCloudWorkspace(
      state: accountState.state,
      account: accountState.account,
      data: data,
    ))
      accountState.account.userId,
};

bool _areCloudAccountStatesLoaded(
  List<_CloudAccountWorkspaceState> accountStates,
) => accountStates.every(
  (accountState) => _hasLoadedCloudWorkspaceData(accountState.state),
);

bool _shouldShowNoSearchResults(
  _WorkspaceListData data,
  Set<String> matchingAccountIds,
  bool allCloudStatesLoaded,
) =>
    data.isSearchActive &&
    allCloudStatesLoaded &&
    data.local.isEmpty &&
    data.connected.isEmpty &&
    matchingAccountIds.isEmpty;

bool _shouldShowCloudAccount(
  _CloudAccountWorkspaceState accountState,
  _WorkspaceListData data,
  Set<String> matchingAccountIds,
) =>
    !data.isSearchActive ||
    matchingAccountIds.contains(accountState.account.userId) ||
    !_hasLoadedCloudWorkspaceData(accountState.state);

class const _WorkspaceListData({
  required final String activeWorkspaceId,
  required final AsyncValue<List<CloudAccountSession>> accounts,
  required final WorkspaceEntity? editingWorkspace,
  required final bool isSearchActive,
  required final List<WorkspaceEntity> local,
  required final List<WorkspaceEntity> connected,
  required final String searchQuery,
  required final List<WorkspaceEntity> workspaces,
});

class const _WorkspaceListSections({
  required final _WorkspaceListData data,
  required final _WorkspaceListActions actions,
  required final ValueChanged<String> onSearchChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _WorkspaceSearchInput(onChanged: onSearchChanged),
        _LocalWorkspaceSection(data: data, actions: actions),
        _ConnectedWorkspaceSection(data: data, actions: actions),
        _AvailableCloudWorkspaceSection(data: data, actions: actions),
      ],
    );
  }
}

class const _WorkspaceSearchInput({
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Semantics(
      key: const ValueKey<String>('workspace_search'),
      child: AuraInput(
        placeholder: const TextLocale(
          LocaleKeys.workspace_management_search_placeholder,
        ),
        prefixIcon: const AuraIcon(Icons.search),
        size: .small,
        onChanged: onChanged,
      ),
      identifier: 'workspace_search',
    ),
  );
}

class const _WorkspaceListActions({
  required final BuildContext context,
  required final WidgetRef ref,
  required final String activeWorkspaceId,
});

extension on _WorkspaceListActions {
  Future<void> switchWorkspace(WorkspaceEntity workspace) async {
    if (workspace.id == activeWorkspaceId) return;

    if (await _confirmWorkspaceSwitch(workspace) != true || !context.mounted) {
      return;
    }

    try {
      await _selectWorkspace(workspace.id);
      if (!context.mounted) return;

      _navigateToWorkspace(workspace.id);
    } on Object catch (error, stackTrace) {
      if (context.mounted) {
        _showError(
          context,
          error,
          stackTrace,
          LocaleKeys.workspace_management_switch_error,
        );
      }
    }
  }

  Future<bool?> _confirmWorkspaceSwitch(WorkspaceEntity workspace) {
    return AuraDialogs.confirm(
      context: context,
      title: const TextLocale(LocaleKeys.workspace_management_switch_title),
      message: Text(
        LocaleKeys.workspace_management_switch_confirm.tr(
          namedArgs: {'name': workspace.name},
        ),
      ),
      actions: _switchConfirmationActions,
    );
  }

  Future<void> _selectWorkspace(String workspaceId) {
    return ref
        .read(selectWorkspaceUsecaseProvider)
        .call(workspaceId: workspaceId);
  }

  void _navigateToWorkspace(String workspaceId) {
    ref
        .read(routerProvider)
        .go(WorkspaceManagementRoute(workspaceId: workspaceId).location);
  }

  void cancelEdit() {
    ref.read(workspaceManagementModeProvider.notifier).clearEditing();
  }

  void editWorkspace(WorkspaceEntity workspace) {
    ref.read(workspaceManagementModeProvider.notifier).editWorkspace(workspace);
  }

  void createWorkspace() {
    context.go(WorkspaceCreateRoute(workspaceId: activeWorkspaceId).location);
  }

  void openDetails({required String? accountId, required String? workspaceId}) {
    _openDetails(context, accountId: accountId, cloudWorkspaceId: workspaceId);
  }

  String? accountEmail(
    AsyncValue<List<CloudAccountSession>> accounts,
    String? accountId,
  ) => switch (accounts) {
    AsyncData(:final value) =>
      value.firstWhereOrNull((account) => account.userId == accountId)?.email,
    AsyncLoading() || AsyncError() => null,
  };
}

extension on _WorkspaceListActions {
  Future<void> edit(String id, String name) async {
    final _ = await WorkspaceManagementMutations.edit.run(ref, (_) {
      return ref.read(editWorkspaceUseCaseProvider).call(id: id, name: name);
    });
    if (!context.mounted) return;
    _handleEditResult();
  }

  Future<void> duplicate(WorkspaceEntity workspace) async {
    final _ = await WorkspaceManagementMutations.duplicate.run(ref, (_) {
      return ref.read(duplicateWorkspaceUseCaseProvider).call(workspace.id);
    });
    if (!context.mounted) return;

    _handleDuplicateResult();
  }

  void _handleDuplicateResult() {
    switch (ref.read(WorkspaceManagementMutations.duplicate)) {
      case MutationSuccess():
        ref.invalidate(allWorkspacesProvider);
      case MutationError(:final error):
        _showError(context, error);
      case MutationIdle() || MutationPending():
        break;
    }
  }

  Future<void> confirmDelete(WorkspaceEntity workspace) async {
    final confirmed = await _confirmDeleteDialog(workspace);
    if (confirmed != true || !context.mounted) return;

    await _deleteAndHandle(workspace);
  }

  Future<void> switchAfterActiveWorkspaceRemoval() async {
    ref.invalidate(allWorkspacesProvider);
    final remaining = await ref.read(allWorkspacesProvider.future);
    if (!context.mounted) return;
    _navigateAfterRemoval(remaining);
  }

  void _handleEditResult() {
    switch (ref.read(WorkspaceManagementMutations.edit)) {
      case MutationSuccess():
        ref.read(workspaceManagementModeProvider.notifier).clearEditing();
      case MutationError(:final error):
        _showError(context, error);
      case MutationIdle() || MutationPending():
        break;
    }
  }

  Future<void> _deleteAndHandle(WorkspaceEntity workspace) async {
    await _delete(workspace);
    if (!context.mounted) return;
    if (ref.read(WorkspaceManagementMutations.delete) case MutationError(
      :final error,
    )) {
      _showError(context, error);

      return;
    }
    if (workspace.id == activeWorkspaceId) {
      await switchAfterActiveWorkspaceRemoval();
    }
  }

  Future<bool?> _confirmDeleteDialog(WorkspaceEntity workspace) {
    return _confirmDestructive(
      title: const TextLocale(LocaleKeys.workspace_management_delete_title),
      message: Text(
        LocaleKeys.workspace_management_delete_confirm.tr(
          namedArgs: {'name': workspace.name},
        ),
      ),
      actions: _deleteConfirmationActions,
    );
  }

  Future<void> _delete(WorkspaceEntity workspace) {
    return WorkspaceManagementMutations.delete.run(ref, (_) {
      return ref
          .read(deleteWorkspaceUseCaseProvider)
          .call(id: workspace.id, activeWorkspaceId: activeWorkspaceId);
    });
  }

  Future<String?> _confirmedRemovalAccountId(WorkspaceEntity workspace) async {
    final confirmed = await _confirmRemoveDialog(workspace);
    if (confirmed != true) return null;

    return workspace.cloudAccountId;
  }

  Future<bool?> _confirmRemoveDialog(WorkspaceEntity workspace) {
    return _confirmDestructive(
      title: const TextLocale(LocaleKeys.workspace_management_cloud_detach),
      message: Text(
        LocaleKeys.cloud_workspaces_remove_confirm.tr(
          namedArgs: {'name': workspace.name},
        ),
      ),
      actions: _removeConfirmationActions,
    );
  }

  Future<void> _detachAndSwitch(
    WorkspaceEntity workspace,
    String accountId,
  ) async {
    await _detach(workspace, accountId);
    if (workspace.id == activeWorkspaceId && context.mounted) {
      await switchAfterActiveWorkspaceRemoval();
    }
  }
}

extension on _WorkspaceListActions {
  Future<void> confirmRemove(WorkspaceEntity workspace) async {
    final accountId = await _confirmedRemovalAccountId(workspace);
    if (accountId == null || !context.mounted) return;

    try {
      await _detachAndSwitch(workspace, accountId);
    } on Object catch (error, stackTrace) {
      if (context.mounted) _showError(context, error, stackTrace);
    }
  }

  Future<void> connect(
    CloudWorkspaceSummary workspace,
    String accountId,
  ) async {
    try {
      await _attach(workspace, accountId);
    } on Object catch (error, stackTrace) {
      if (context.mounted) _showError(context, error, stackTrace);
    }
  }

  Future<void> _detach(WorkspaceEntity workspace, String accountId) async {
    final useCases = await ref.read(
      cloudWorkspaceUseCasesProvider(accountId).future,
    );
    await useCases?.detachMirror(workspace);
    ref
      ..invalidate(allWorkspacesProvider)
      ..invalidate(cloudWorkspaceStateProvider(accountId));
  }

  Future<bool?> _confirmDestructive({
    required Widget title,
    required Widget message,
    required AuraConfirmDialogActions actions,
  }) => AuraDialogs.confirm(
    context: context,
    title: title,
    message: message,
    actions: actions,
    isDestructive: true,
  );

  void _navigateAfterRemoval(List<WorkspaceEntity> remaining) {
    if (remaining.isEmpty) {
      const IntroRoute().go(context);

      return;
    }

    final first = remaining.firstOrNull;
    if (first == null) return;

    NewChatRoute(workspaceId: first.id).go(context);
  }

  Future<void> _attach(
    CloudWorkspaceSummary workspace,
    String accountId,
  ) async {
    final useCases = await ref.read(
      cloudWorkspaceUseCasesProvider(accountId).future,
    );
    final _ = await useCases?.attach(workspace);
    ref
      ..invalidate(allWorkspacesProvider)
      ..invalidate(cloudWorkspaceStateProvider(accountId));
  }
}

class const _LocalWorkspaceSection({
  required final _WorkspaceListData data,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const _SectionTitle(LocaleKeys.cloud_workspaces_local_section),
        _LocalWorkspaceItems(data: data, actions: actions),
        _CreateWorkspaceButton(onPressed: actions.createWorkspace),
      ],
    );
  }
}

class _LocalWorkspaceItems extends StatelessWidget {
  new({
    required _WorkspaceListData data,
    required _WorkspaceListActions actions,
  }) : _children = [
         if (data.local.isEmpty &&
             data.isSearchActive &&
             data.connected.isEmpty &&
             _hasNoCloudAccounts(data.accounts))
           const TextLocale(LocaleKeys.workspace_management_no_search_results),
         if (data.local.isEmpty && !data.isSearchActive)
           const TextLocale(LocaleKeys.workspace_management_no_workspaces),
         for (final workspace in data.local)
           _LocalWorkspaceItem(
             workspace: workspace,
             activeWorkspaceId: data.activeWorkspaceId,
             editingWorkspace: data.editingWorkspace,
             actions: actions,
           ),
       ];

  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: .stretch, children: _children);
}

class const _LocalWorkspaceItem({
  required final WorkspaceEntity workspace,
  required final String activeWorkspaceId,
  required final WorkspaceEntity? editingWorkspace,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (editingWorkspace?.id == workspace.id) {
      return _EditingWorkspaceItem(workspace: workspace, actions: actions);
    }

    return _LocalWorkspaceTile(
      workspace: workspace,
      isActive: workspace.id == activeWorkspaceId,
      actions: actions,
    );
  }
}

class const _EditingWorkspaceItem({
  required final WorkspaceEntity workspace,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _EditWorkspaceTile(
      workspace: workspace,
      onSave: (name) => actions.edit(workspace.id, name),
      onCancel: actions.cancelEdit,
    );
  }
}

class const _CreateWorkspaceButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Semantics(
        key: const ValueKey<String>('workspace_create'),
        child: AuraButton(
          onPressed: onPressed,
          child: const TextLocale(
            LocaleKeys.workspace_management_create_button,
          ),
        ),
        identifier: 'workspace_create',
      ),
    );
  }
}

class const _ConnectedWorkspaceSection({
  required final _WorkspaceListData data,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const _SectionTitle(LocaleKeys.cloud_workspaces_connected_section),
        _ConnectedWorkspaceItems(data: data, actions: actions),
      ],
    );
  }
}

class _ConnectedWorkspaceItems extends StatelessWidget {
  new({
    required _WorkspaceListData data,
    required _WorkspaceListActions actions,
  }) : _children = [
         for (final workspace in data.connected)
           _ConnectedWorkspaceItem(
             workspace: workspace,
             activeWorkspaceId: data.activeWorkspaceId,
             accountEmail: actions.accountEmail(
               data.accounts,
               workspace.cloudAccountId,
             ),
             actions: actions,
           ),
       ];

  final List<Widget> _children;

  @override
  Widget build(BuildContext context) => Column(children: _children);
}

class const _ConnectedWorkspaceItem({
  required final WorkspaceEntity workspace,
  required final String activeWorkspaceId,
  required final String? accountEmail,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ConnectedWorkspaceTile(
      workspace: workspace,
      accountEmail: accountEmail,
      isActive: workspace.id == activeWorkspaceId,
      actions: actions,
    );
  }
}

class const _AvailableCloudWorkspaceSection({
  required final _WorkspaceListData data,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SizedBox(height: 16),
        const _SectionTitle('workspace_management.cloud_available_section'),
        _AvailableCloudAccounts(data: data, actions: actions),
      ],
    );
  }
}

class const _AvailableCloudAccounts({
  required final _WorkspaceListData data,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (data.accounts) {
      AsyncData(:final value) when value.isEmpty => const TextLocale(
        'workspace_management.cloud_add_hint',
      ),
      AsyncData(:final value) => _AvailableCloudAccountItems(
        accounts: value,
        data: data,
        actions: actions,
      ),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError() => const TextLocale(LocaleKeys.cloud_accounts_load_error),
    };
  }
}

class const _AvailableCloudAccountItems({
  required final List<CloudAccountSession> accounts,
  required final _WorkspaceListData data,
  required final _WorkspaceListActions actions,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountStates = _watchCloudAccountStates(ref, accounts);
    final matchingAccountIds = _matchingCloudAccountIds(accountStates, data);
    if (_shouldShowNoSearchResults(
      data,
      matchingAccountIds,
      _areCloudAccountStatesLoaded(accountStates),
    )) {
      return const TextLocale(
        LocaleKeys.workspace_management_no_search_results,
      );
    }

    return _AvailableCloudAccountGroups(
      accounts: accounts,
      accountStates: accountStates,
      matchingAccountIds: matchingAccountIds,
      data: data,
      actions: actions,
    );
  }
}

class const _AvailableCloudAccountGroups({
  required final List<CloudAccountSession> accounts,
  required final List<_CloudAccountWorkspaceState> accountStates,
  required final Set<String> matchingAccountIds,
  required final _WorkspaceListData data,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      for (final accountState in accountStates)
        if (_shouldShowCloudAccount(accountState, data, matchingAccountIds))
          _AvailableCloudAccountGroup(
            accountState: accountState,
            accounts: accounts,
            data: data,
            actions: actions,
          ),
    ],
  );
}

class const _AvailableCloudAccountGroup({
  required final _CloudAccountWorkspaceState accountState,
  required final List<CloudAccountSession> accounts,
  required final _WorkspaceListData data,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AvailableCloudAccountGroupLayout(
    account: accountState.account,
    accounts: accounts,
    localWorkspaces: data.workspaces,
    hasPersistedMatches: data.local.isNotEmpty || data.connected.isNotEmpty,
    searchQuery: data.searchQuery,
    workspaceId: data.activeWorkspaceId,
    state: accountState.state,
    actions: actions,
  );
}

class _AvailableCloudAccountGroupLayout extends StatelessWidget {
  new({
    required CloudAccountSession account,
    required List<CloudAccountSession> accounts,
    required List<WorkspaceEntity> localWorkspaces,
    required bool hasPersistedMatches,
    required String searchQuery,
    required String workspaceId,
    required AsyncValue<CloudWorkspaceViewState?> state,
    required _WorkspaceListActions actions,
  }) : _child = Padding(
         padding: const EdgeInsets.only(bottom: 16),
         child: Column(
           crossAxisAlignment: .stretch,
           children: [
             AuraText(child: Text(account.email), style: .heading6),
             const SizedBox(height: 8),
             _AvailableCloudAccountState(
               account,
               accounts,
               localWorkspaces,
               searchQuery,
               workspaceId,
               state,
               actions,
               hasPersistedMatches: hasPersistedMatches,
             ),
           ],
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AvailableCloudAccountState extends StatelessWidget {
  new(
    CloudAccountSession account,
    List<CloudAccountSession> accounts,
    List<WorkspaceEntity> localWorkspaces,
    String searchQuery,
    String workspaceId,
    AsyncValue<CloudWorkspaceViewState?> state,
    _WorkspaceListActions actions, {
    required bool hasPersistedMatches,
  }) : _child = switch (state) {
         AsyncData(value: final value?) => _AvailableCloudDataState(
           account: account,
           accounts: accounts,
           localWorkspaces: localWorkspaces,
           hasPersistedMatches: hasPersistedMatches,
           searchQuery: searchQuery,
           workspaceId: workspaceId,
           value: value,
           actions: actions,
         ),
         AsyncData(value: null) => const TextLocale(
           LocaleKeys.cloud_accounts_no_workspaces,
         ),
         AsyncLoading() => const Center(child: AuraSpinner()),
         AsyncError() => const TextLocale(
           LocaleKeys.workspace_management_cloud_load_error,
         ),
       };

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AvailableCloudDataState({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final List<WorkspaceEntity> localWorkspaces,
  required final bool hasPersistedMatches,
  required final String searchQuery,
  required final String workspaceId,
  required final CloudWorkspaceViewState value,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (value.authenticationRequired) {
      return _CloudAccountDisconnected(
        workspaceId: workspaceId,
        accountId: account.userId,
      );
    }

    return _AvailableCloudWorkspaceList(
      account: account,
      accounts: accounts,
      localWorkspaces: localWorkspaces,
      hasPersistedMatches: hasPersistedMatches,
      searchQuery: searchQuery,
      workspaces: value.workspaces,
      actions: actions,
    );
  }
}

class const _CloudAccountDisconnected({
  required final String workspaceId,
  required final String accountId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CloudAccountDisconnectedTile(
    workspaceId: workspaceId,
    accountId: accountId,
  );
}

class const _CloudAccountDisconnectedTile({
  required final String workspaceId,
  required final String accountId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: const _CloudAccountDisconnectedText(),
      variant: .ghost,
      trailing: _CloudAccountSignInButton(
        workspaceId: workspaceId,
        accountId: accountId,
      ),
    );
  }
}

class const _CloudAccountDisconnectedText() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AuraColumn(
      children: [
        AuraText(
          child: TextLocale(LocaleKeys.cloud_accounts_status_needs_sign_in),
          style: .bodySmall,
        ),
        TextLocale(LocaleKeys.cloud_accounts_session_expired),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _CloudAccountSignInButton({
  required final String workspaceId,
  required final String accountId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectorId = 'workspace_cloud_account_sign_in_$accountId';

    return Semantics(
      key: ValueKey<String>(selectorId),
      child: AuraButton(
        onPressed: () => context.go(
          CloudAccountLoginRoute(workspaceId: workspaceId).location,
        ),
        child: const TextLocale(LocaleKeys.cloud_accounts_sign_in_again),
        variant: .outlined,
      ),
      identifier: selectorId,
    );
  }
}

class const _AvailableCloudWorkspaceList({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final List<WorkspaceEntity> localWorkspaces,
  required final bool hasPersistedMatches,
  required final String searchQuery,
  required final List<CloudWorkspaceSummary> workspaces,
  required final _WorkspaceListActions actions,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matching = _matchingCloudWorkspaces(workspaces, searchQuery);
    final available = _availableCloudWorkspaces(
      matching,
      account,
      localWorkspaces,
    );
    if (available.isEmpty) {
      return _AvailableCloudWorkspaceEmptyState(
        hasMatchingWorkspaces: matching.isNotEmpty,
        hasPersistedMatches: hasPersistedMatches,
        searchQuery: searchQuery,
      );
    }

    return _AvailableCloudWorkspaceItems(
      account: account,
      accounts: accounts,
      localWorkspaces: localWorkspaces,
      workspaces: available,
      actions: actions,
    );
  }
}

class const _AvailableCloudWorkspaceEmptyState({
  required final bool hasMatchingWorkspaces,
  required final bool hasPersistedMatches,
  required final String searchQuery,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (searchQuery.isNotEmpty &&
        !hasPersistedMatches &&
        !hasMatchingWorkspaces) {
      return const TextLocale(
        LocaleKeys.workspace_management_no_search_results,
      );
    }

    return const TextLocale(LocaleKeys.cloud_accounts_no_workspaces);
  }
}

class const _AvailableCloudWorkspaceItems({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final List<WorkspaceEntity> localWorkspaces,
  required final List<CloudWorkspaceSummary> workspaces,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final workspace in workspaces)
          _AvailableCloudWorkspaceItem(
            account: account,
            accounts: accounts,
            localWorkspaces: localWorkspaces,
            workspace: workspace,
            actions: actions,
          ),
      ],
    );
  }
}

class const _AvailableCloudWorkspaceItem({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final List<WorkspaceEntity> localWorkspaces,
  required final CloudWorkspaceSummary workspace,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AvailableWorkspaceTile(
      workspace: workspace,
      connectedAccountEmail: _connectedElsewhereEmail((
        workspace: workspace,
        accountId: account.userId,
        accounts: accounts,
        localWorkspaces: localWorkspaces,
      )),
      accountId: account.userId,
      actions: actions,
    );
  }
}

String? _connectedElsewhereEmail(
  ({
    CloudWorkspaceSummary workspace,
    String accountId,
    List<CloudAccountSession> accounts,
    List<WorkspaceEntity> localWorkspaces,
  })
  input,
) {
  final mirror = input.localWorkspaces.firstWhereOrNull(
    (local) => _isConnectedElsewhere(local, input.workspace, input.accountId),
  );

  if (mirror == null) return null;

  return input.accounts
      .firstWhereOrNull((account) => account.userId == mirror.cloudAccountId)
      ?.email;
}

bool _isConnectedElsewhere(
  WorkspaceEntity local,
  CloudWorkspaceSummary workspace,
  String accountId,
) {
  return local.cloudWorkspaceId == workspace.id.toString() &&
      local.cloudAccountId != accountId;
}

class const _LocalWorkspaceTile({
  required final WorkspaceEntity workspace,
  required final bool isActive,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectorId = 'workspace_select_${workspace.id}';

    return StableUiSelector(
      identifier: selectorId,
      child: AuraTile(
        child: _WorkspaceName(name: workspace.name, isActive: isActive),
        onTap: () => actions.switchWorkspace(workspace),
        variant: .ghost,
        trailing: _LocalWorkspaceMenu(workspace: workspace, actions: actions),
      ),
    );
  }
}

class const _LocalWorkspaceMenu({
  required final WorkspaceEntity workspace,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectorId = 'workspace_menu_${workspace.id}';

    return Semantics(
      key: ValueKey<String>(selectorId),
      child: AuraPopupMenuButton(
        items: [_editItem(), _duplicateItem(), _deleteItem()],
        tooltip: LocaleKeys.common_show_more.tr(),
      ),
      identifier: selectorId,
    );
  }

  AuraPopupMenuItem _editItem() {
    return AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.common_edit),
      onTap: () => actions.editWorkspace(workspace),
    );
  }

  AuraPopupMenuItem _deleteItem() {
    return AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.common_delete),
      onTap: () => actions.confirmDelete(workspace),
      variant: .error,
    );
  }

  AuraPopupMenuItem _duplicateItem() {
    return AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.workspace_management_duplicate),
      onTap: () => actions.duplicate(workspace),
    );
  }
}

class const _ConnectedWorkspaceTile({
  required final WorkspaceEntity workspace,
  required final String? accountEmail,
  required final bool isActive,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectorId = 'workspace_select_${workspace.id}';

    return StableUiSelector(
      identifier: selectorId,
      child: AuraTile(
        child: _ConnectedWorkspaceDetails(
          workspace: workspace,
          accountEmail: accountEmail,
          isActive: isActive,
        ),
        onTap: () => actions.switchWorkspace(workspace),
        variant: .ghost,
        trailing: _ConnectedWorkspaceMenu(
          workspace: workspace,
          actions: actions,
        ),
      ),
    );
  }
}

class const _ConnectedWorkspaceDetails({
  required final WorkspaceEntity workspace,
  required final String? accountEmail,
  required final bool isActive,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _WorkspaceName(name: workspace.name, isActive: isActive),
        TextLocale(
          'workspace_management.cloud_connected_account',
          args: [accountEmail ?? workspace.cloudAccountId ?? ''],
        ),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _ConnectedWorkspaceMenu({
  required final WorkspaceEntity workspace,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectorId = 'workspace_menu_${workspace.id}';

    return Semantics(
      key: ValueKey<String>(selectorId),
      child: AuraPopupMenuButton(
        items: [_detailsItem(), _removeItem()],
        tooltip: LocaleKeys.common_show_more.tr(),
      ),
      identifier: selectorId,
    );
  }

  AuraPopupMenuItem _detailsItem() {
    return AuraPopupMenuItem(
      title: const TextLocale('common.details'),
      onTap: () => actions.openDetails(
        accountId: workspace.cloudAccountId,
        workspaceId: workspace.cloudWorkspaceId,
      ),
    );
  }

  AuraPopupMenuItem _removeItem() {
    return AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.workspace_management_cloud_detach),
      onTap: () => actions.confirmRemove(workspace),
      variant: .error,
    );
  }
}

class const _AvailableWorkspaceTile({
  required final CloudWorkspaceSummary workspace,
  required final String? connectedAccountEmail,
  required final String accountId,
  required final _WorkspaceListActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: _AvailableWorkspaceDetails(
        workspace: workspace,
        connectedAccountEmail: connectedAccountEmail,
      ),
      variant: .ghost,
      trailing: _AvailableWorkspaceMenu(
        workspace: workspace,
        accountId: accountId,
        actions: actions,
        canConnect: connectedAccountEmail == null,
      ),
    );
  }
}

class _AvailableWorkspaceDetails extends StatelessWidget {
  new({
    required CloudWorkspaceSummary workspace,
    required String? connectedAccountEmail,
  }) : _child = AuraColumn(
         children: [
           Text(workspace.name),
           if (connectedAccountEmail case final email?)
             Text(
               LocaleKeys.workspace_management_cloud_connected_elsewhere.tr(
                 namedArgs: {'email': email},
               ),
             ),
         ],
         spacing: .xs,
         crossAxisAlignment: .start,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AvailableWorkspaceMenu({
  required final CloudWorkspaceSummary workspace,
  required final String accountId,
  required final _WorkspaceListActions actions,
  required final bool canConnect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectorId = 'workspace_available_menu_${accountId}_${workspace.id}';

    return Semantics(
      key: ValueKey<String>(selectorId),
      child: AuraPopupMenuButton(
        items: [_detailsItem(), _connectItem()],
        tooltip: LocaleKeys.common_show_more.tr(),
      ),
      identifier: selectorId,
    );
  }

  AuraPopupMenuItem _detailsItem() {
    return AuraPopupMenuItem(
      title: const TextLocale('common.details'),
      onTap: () => actions.openDetails(
        accountId: accountId,
        workspaceId: workspace.id.toString(),
      ),
    );
  }

  AuraPopupMenuItem _connectItem() {
    return AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.workspace_management_cloud_attach),
      onTap: canConnect ? () => actions.connect(workspace, accountId) : null,
    );
  }
}

class const _WorkspaceName({
  required final String name,
  required final bool isActive,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        Text(name),
        if (isActive)
          const AuraText(
            child: TextLocale(LocaleKeys.workspace_management_active_label),
            style: .bodySmall,
          ),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _SectionTitle(final String keyName) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AuraText(child: TextLocale(keyName), style: .heading6),
    );
  }
}

class const _EditWorkspaceTile({
  required final WorkspaceEntity workspace,
  required final ValueChanged<String> onSave,
  required final VoidCallback onCancel,
}) extends StatefulWidget {
  @override
  State<_EditWorkspaceTile> createState() => _EditWorkspaceTileState();
}

class _EditWorkspaceTileState extends State<_EditWorkspaceTile> {
  final _controller = TextEditingController();
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.workspace.name;
    _controller.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onNameChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    child: _WorkspaceEditRow(
      controller: _controller,
      onSave: widget.onSave,
      onCancel: () => unawaited(_cancel(context)),
    ),
    canPop: !_isDirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_confirmBack(context));
    },
  );

  void _onNameChanged() {
    if (!mounted) return;

    final isDirty = _controller.text != widget.workspace.name;
    if (_isDirty == isDirty) return;

    setState(() => _isDirty = isDirty);
  }

  Future<void> _cancel(BuildContext context) async {
    if (!_isDirty) {
      widget.onCancel();

      return;
    }

    final shouldDiscard = await _confirmDiscard(context);
    if (shouldDiscard != true || !context.mounted) return;

    widget.onCancel();
  }

  Future<void> _confirmBack(BuildContext context) async {
    final shouldDiscard = await _confirmDiscard(context);
    if (shouldDiscard != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    setState(() => _isDirty = false);
    widget.onCancel();
    navigator.pop();
  }

  Future<bool?> _confirmDiscard(BuildContext context) => AuraDialogs.confirm(
    context: context,
    title: const TextLocale(
      LocaleKeys.workspace_management_unsaved_changes_title,
    ),
    message: const TextLocale(
      LocaleKeys.workspace_management_unsaved_changes_message,
    ),
    actions: const AuraConfirmDialogActions(
      confirmLabel: TextLocale(LocaleKeys.workspace_management_discard_changes),
      cancelLabel: TextLocale(LocaleKeys.workspace_management_keep_editing),
    ),
    isDestructive: true,
  );
}

class _WorkspaceEditRow extends StatelessWidget {
  new({
    required TextEditingController controller,
    required ValueChanged<String> onSave,
    required VoidCallback onCancel,
  }) : _children = [
         Expanded(
           child: _WorkspaceNameEditor(controller: controller, onSave: onSave),
         ),
         _WorkspaceEditActions(
           controller: controller,
           onSave: onSave,
           onCancel: onCancel,
         ),
       ];

  final List<Widget> _children;

  @override
  Widget build(BuildContext context) => Row(children: _children);
}

class const _WorkspaceNameEditor({
  required final TextEditingController controller,
  required final ValueChanged<String> onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      key: const ValueKey<String>('workspace_name_editor'),
      controller: controller,
      placeholder: Text(LocaleKeys.workspace_management_name_placeholder.tr()),
      textInputAction: .done,
      autofocus: true,
      onSubmitted: (value) => onSave(value.trim()),
    );
  }
}

class const _WorkspaceEditActions({
  required final TextEditingController controller,
  required final ValueChanged<String> onSave,
  required final VoidCallback onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        _WorkspaceSaveButton(controller: controller, onSave: onSave),
        _WorkspaceCancelButton(onCancel: onCancel),
      ],
    );
  }
}

class const _WorkspaceSaveButton({
  required final TextEditingController controller,
  required final ValueChanged<String> onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('workspace_save'),
    child: AuraIconButton(
      icon: Icons.check,
      onPressed: () => onSave(controller.text.trim()),
      tooltip: LocaleKeys.common_save.tr(),
    ),
    identifier: 'workspace_save',
  );
}

class const _WorkspaceCancelButton({required final VoidCallback onCancel})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('workspace_cancel'),
    child: AuraIconButton(
      icon: Icons.close,
      onPressed: onCancel,
      tooltip: LocaleKeys.common_cancel.tr(),
    ),
    identifier: 'workspace_cancel',
  );
}

void _openDetails(
  BuildContext context, {
  required String? accountId,
  required String? cloudWorkspaceId,
}) {
  final parsedId = _parseCloudWorkspaceId(cloudWorkspaceId);
  final workspaceId = _routeWorkspaceId(context);
  if (accountId == null || parsedId == null || workspaceId == null) return;

  context.go(
    CloudWorkspaceDetailRoute(
      workspaceId: workspaceId,
      cloudAccountId: accountId,
      cloudWorkspaceId: parsedId,
    ).location,
  );
}

int? _parseCloudWorkspaceId(String? cloudWorkspaceId) {
  return int.tryParse(cloudWorkspaceId ?? '');
}

String? _routeWorkspaceId(BuildContext context) {
  return GoRouterState.of(context).pathParameters['workspaceId'];
}

void _showError(
  BuildContext context,
  Object error, [
  StackTrace? stackTrace,
  String? fallbackKey,
]) {
  final message = _errorMessage(error, fallbackKey);
  _logUnexpectedError(error, stackTrace);
  final _ = AuraSnackBars.show(
    context: context,
    content: Text(message),
    variant: .error,
  );
}

String _errorMessage(Object error, [String? fallbackKey]) {
  return switch (error) {
    WorkspaceException(:final localizationKey, :final message) =>
      localizationKey?.tr() ?? message,
    AppCloudWorkspaceException(:final localizationKey) => localizationKey.tr(),
    _ => (fallbackKey ?? LocaleKeys.workspace_management_unexpected_error).tr(),
  };
}

void _logUnexpectedError(Object error, StackTrace? stackTrace) {
  if (error is! WorkspaceException && error is! AppCloudWorkspaceException) {
    _logger.warning('Workspace management failed', error, stackTrace);
  }
}
