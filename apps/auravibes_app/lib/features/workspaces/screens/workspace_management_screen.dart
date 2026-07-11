import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/workspaces/models/management_mode.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/usecases/usecases.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';

class WorkspaceManagementScreen extends ConsumerWidget {
  const WorkspaceManagementScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(allWorkspacesProvider);
    final accounts = ref.watch(cloudAccountsProvider);
    final editingWorkspace = ref.watch(
      workspaceManagementModeProvider.select((state) => state.editingWorkspace),
    );

    return AuraScreen(
      child: switch (workspaces) {
        AsyncData(:final value) => _WorkspaceList(
          activeWorkspaceId: workspaceId,
          accounts: accounts,
          editingWorkspace: editingWorkspace,
          workspaces: value,
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => const Center(
          child: TextLocale(LocaleKeys.workspace_management_load_error),
        ),
      },
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.workspace_management_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _WorkspaceList extends ConsumerWidget {
  const _WorkspaceList({
    required this.activeWorkspaceId,
    required this.accounts,
    required this.editingWorkspace,
    required this.workspaces,
  });

  final String activeWorkspaceId;
  final AsyncValue<List<CloudAccountSession>> accounts;
  final WorkspaceEntity? editingWorkspace;
  final List<WorkspaceEntity> workspaces;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = workspaces.where((item) => item.cloudWorkspaceId == null);
    final connected = workspaces.where((item) => item.cloudWorkspaceId != null);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(LocaleKeys.cloud_workspaces_local_section),
        if (local.isEmpty)
          const TextLocale(LocaleKeys.workspace_management_no_workspaces),
        for (final workspace in local)
          if (editingWorkspace?.id == workspace.id)
            _EditWorkspaceTile(
              workspace: workspace,
              onSave: (name) => _edit(context, ref, workspace.id, name),
              onCancel: () => ref
                  .read(workspaceManagementModeProvider.notifier)
                  .clearEditing(),
            )
          else
            _LocalWorkspaceTile(
              workspace: workspace,
              isActive: workspace.id == activeWorkspaceId,
              onTap: () => _switch(ref, workspace.id),
              onEdit: () => ref
                  .read(workspaceManagementModeProvider.notifier)
                  .setMode(
                    ManagementMode.edit,
                    editingWorkspace: workspace,
                  ),
              onDelete: () => _confirmDelete(context, ref, workspace),
            ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: AuraButton(
            onPressed: () => context.go(
              WorkspaceCreateRoute(workspaceId: activeWorkspaceId).location,
            ),
            child: const TextLocale(
              LocaleKeys.workspace_management_create_button,
            ),
          ),
        ),
        const _SectionTitle(LocaleKeys.cloud_workspaces_connected_section),
        for (final workspace in connected)
          _ConnectedWorkspaceTile(
            workspace: workspace,
            accountEmail: _accountEmail(accounts, workspace.cloudAccountId),
            isActive: workspace.id == activeWorkspaceId,
            onTap: () => _switch(ref, workspace.id),
            onDetails: () => _openDetails(
              context,
              accountId: workspace.cloudAccountId,
              cloudWorkspaceId: workspace.cloudWorkspaceId,
            ),
            onRemove: () => _confirmRemove(context, ref, workspace),
          ),
        const SizedBox(height: 16),
        const _SectionTitle('workspace_management.cloud_available_section'),
        switch (accounts) {
          AsyncData(:final value) when value.isEmpty => const TextLocale(
            'workspace_management.cloud_add_hint',
          ),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final account in value)
                _AvailableCloudAccountGroup(
                  account: account,
                  accounts: value,
                  localWorkspaces: workspaces,
                ),
            ],
          ),
          AsyncLoading() => const Center(child: AuraSpinner()),
          AsyncError() => const TextLocale(
            LocaleKeys.cloud_accounts_load_error,
          ),
        },
      ],
    );
  }

  String? _accountEmail(
    AsyncValue<List<CloudAccountSession>> accounts,
    String? accountId,
  ) {
    return switch (accounts) {
      AsyncData(:final value) =>
        value.firstWhereOrNull((account) => account.userId == accountId)?.email,
      _ => null,
    };
  }

  void _switch(WidgetRef ref, String workspaceId) {
    ref.read(workspaceSwitcherProvider.notifier).switchToWorkspace(workspaceId);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final _ = await editWorkspaceMutation.run(ref, (_) {
      return ref.read(editWorkspaceUseCaseProvider).call(id: id, name: name);
    });
    if (!context.mounted) return;
    switch (ref.read(editWorkspaceMutation)) {
      case MutationSuccess():
        ref.read(workspaceManagementModeProvider.notifier).clearEditing();
      case MutationError(:final error):
        _showError(context, error);
      case _:
        break;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WorkspaceEntity workspace,
  ) async {
    final confirmed = await showAuraConfirmDialog(
      context: context,
      title: const TextLocale(LocaleKeys.workspace_management_delete_title),
      message: Text(
        LocaleKeys.workspace_management_delete_confirm.tr(
          namedArgs: {'name': workspace.name},
        ),
      ),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.common_delete),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    await deleteWorkspaceMutation.run(ref, (_) {
      return ref
          .read(deleteWorkspaceUseCaseProvider)
          .call(
            id: workspace.id,
            activeWorkspaceId: activeWorkspaceId,
          );
    });
    if (!context.mounted) return;
    if (ref.read(deleteWorkspaceMutation) case MutationError(:final error)) {
      _showError(context, error);
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    WorkspaceEntity workspace,
  ) async {
    final confirmed = await showAuraConfirmDialog(
      context: context,
      title: const TextLocale(LocaleKeys.workspace_management_cloud_detach),
      message: Text(
        LocaleKeys.cloud_workspaces_remove_confirm.tr(
          namedArgs: {'name': workspace.name},
        ),
      ),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.common_remove),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
      isDestructive: true,
    );
    final accountId = workspace.cloudAccountId;
    if (confirmed != true || accountId == null) return;
    if (!context.mounted) return;

    if (workspace.id == activeWorkspaceId) {
      _showError(context, const WorkspaceDeleteActiveException());

      return;
    }

    try {
      final useCases = await ref.read(
        cloudWorkspaceUseCasesProvider(accountId).future,
      );
      await useCases?.detachMirror(workspace);
      ref
        ..invalidate(allWorkspacesProvider)
        ..invalidate(cloudWorkspaceStateProvider(accountId));
    } on Object catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _AvailableCloudAccountGroup extends ConsumerWidget {
  const _AvailableCloudAccountGroup({
    required this.account,
    required this.accounts,
    required this.localWorkspaces,
  });

  final CloudAccountSession account;
  final List<CloudAccountSession> accounts;
  final List<WorkspaceEntity> localWorkspaces;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cloudWorkspaceStateProvider(account.userId));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraText(child: Text(account.email), style: AuraTextStyle.heading6),
          const SizedBox(height: 8),
          switch (state) {
            AsyncData(value: null) => const TextLocale(
              LocaleKeys.cloud_accounts_no_workspaces,
            ),
            AsyncData(:final value?) => _AvailableCloudWorkspaceList(
              account: account,
              accounts: accounts,
              localWorkspaces: localWorkspaces,
              workspaces: value.workspaces,
            ),
            AsyncLoading() => const Center(child: AuraSpinner()),
            AsyncError() => const TextLocale(
              LocaleKeys.workspace_management_cloud_load_error,
            ),
          },
        ],
      ),
    );
  }
}

class _AvailableCloudWorkspaceList extends ConsumerWidget {
  const _AvailableCloudWorkspaceList({
    required this.account,
    required this.accounts,
    required this.localWorkspaces,
    required this.workspaces,
  });

  final CloudAccountSession account;
  final List<CloudAccountSession> accounts;
  final List<WorkspaceEntity> localWorkspaces;
  final List<CloudWorkspaceSummary> workspaces;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = workspaces.where((workspace) {
      return !localWorkspaces.any(
        (local) =>
            local.cloudWorkspaceId == workspace.id.toString() &&
            local.cloudAccountId == account.userId,
      );
    }).toList();
    if (available.isEmpty) {
      return const TextLocale(LocaleKeys.cloud_accounts_no_workspaces);
    }

    return Column(
      children: [
        for (final workspace in available)
          _AvailableWorkspaceTile(
            workspace: workspace,
            connectedAccountEmail: _connectedElsewhereEmail(workspace),
            onDetails: () => _openDetails(
              context,
              accountId: account.userId,
              cloudWorkspaceId: workspace.id.toString(),
            ),
            onConnect: () => _connect(context, ref, workspace),
          ),
      ],
    );
  }

  String? _connectedElsewhereEmail(CloudWorkspaceSummary workspace) {
    final mirror = localWorkspaces.firstWhereOrNull(
      (local) =>
          local.cloudWorkspaceId == workspace.id.toString() &&
          local.cloudAccountId != account.userId,
    );
    if (mirror == null) return null;

    return accounts
        .firstWhereOrNull((account) => account.userId == mirror.cloudAccountId)
        ?.email;
  }

  Future<void> _connect(
    BuildContext context,
    WidgetRef ref,
    CloudWorkspaceSummary workspace,
  ) async {
    try {
      final useCases = await ref.read(
        cloudWorkspaceUseCasesProvider(account.userId).future,
      );
      final _ = await useCases?.attach(workspace);
      ref
        ..invalidate(allWorkspacesProvider)
        ..invalidate(cloudWorkspaceStateProvider(account.userId));
    } on Object catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _LocalWorkspaceTile extends StatelessWidget {
  const _LocalWorkspaceTile({
    required this.workspace,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkspaceEntity workspace;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: _WorkspaceName(name: workspace.name, isActive: isActive),
      onTap: onTap,
      variant: AuraTileVariant.ghost,
      trailing: AuraPopupMenuButton(
        items: [
          AuraPopupMenuItem(
            title: const TextLocale(LocaleKeys.common_edit),
            onTap: onEdit,
          ),
          AuraPopupMenuItem(
            title: const TextLocale(LocaleKeys.common_delete),
            onTap: onDelete,
            variant: AuraTileVariant.error,
          ),
        ],
        tooltip: LocaleKeys.common_show_more.tr(),
      ),
    );
  }
}

class _ConnectedWorkspaceTile extends StatelessWidget {
  const _ConnectedWorkspaceTile({
    required this.workspace,
    required this.accountEmail,
    required this.isActive,
    required this.onTap,
    required this.onDetails,
    required this.onRemove,
  });

  final WorkspaceEntity workspace;
  final String? accountEmail;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDetails;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: AuraColumn(
        children: [
          _WorkspaceName(name: workspace.name, isActive: isActive),
          TextLocale(
            'workspace_management.cloud_connected_account',
            args: [accountEmail ?? workspace.cloudAccountId ?? ''],
          ),
        ],
        spacing: .xs,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      onTap: onTap,
      variant: AuraTileVariant.ghost,
      trailing: AuraPopupMenuButton(
        items: [
          AuraPopupMenuItem(
            title: const TextLocale('common.details'),
            onTap: onDetails,
          ),
          AuraPopupMenuItem(
            title: const TextLocale(
              LocaleKeys.workspace_management_cloud_detach,
            ),
            onTap: onRemove,
            variant: AuraTileVariant.error,
          ),
        ],
        tooltip: LocaleKeys.common_show_more.tr(),
      ),
    );
  }
}

class _AvailableWorkspaceTile extends StatelessWidget {
  const _AvailableWorkspaceTile({
    required this.workspace,
    required this.connectedAccountEmail,
    required this.onDetails,
    required this.onConnect,
  });

  final CloudWorkspaceSummary workspace;
  final String? connectedAccountEmail;
  final VoidCallback onDetails;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final email = connectedAccountEmail;

    return AuraTile(
      child: AuraColumn(
        children: [
          Text(workspace.name),
          if (email != null)
            Text(
              LocaleKeys.workspace_management_cloud_connected_elsewhere.tr(
                namedArgs: {'email': email},
              ),
            ),
        ],
        spacing: .xs,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      variant: AuraTileVariant.ghost,
      trailing: AuraPopupMenuButton(
        items: [
          AuraPopupMenuItem(
            title: const TextLocale('common.details'),
            onTap: onDetails,
          ),
          AuraPopupMenuItem(
            title: const TextLocale(
              LocaleKeys.workspace_management_cloud_attach,
            ),
            onTap: email == null ? onConnect : null,
          ),
        ],
        tooltip: LocaleKeys.common_show_more.tr(),
      ),
    );
  }
}

class _WorkspaceName extends StatelessWidget {
  const _WorkspaceName({required this.name, required this.isActive});

  final String name;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        Text(name),
        if (isActive)
          const AuraText(
            child: TextLocale(LocaleKeys.workspace_management_active_label),
            style: AuraTextStyle.bodySmall,
          ),
      ],
      spacing: .xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.keyName);

  final String keyName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AuraText(
        child: TextLocale(keyName),
        style: AuraTextStyle.heading6,
      ),
    );
  }
}

class _EditWorkspaceTile extends StatefulWidget {
  const _EditWorkspaceTile({
    required this.workspace,
    required this.onSave,
    required this.onCancel,
  });

  final WorkspaceEntity workspace;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  @override
  State<_EditWorkspaceTile> createState() => _EditWorkspaceTileState();
}

class _EditWorkspaceTileState extends State<_EditWorkspaceTile> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.workspace.name;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AuraInput(
            controller: _controller,
            placeholder: Text(
              LocaleKeys.workspace_management_name_placeholder.tr(),
            ),
            textInputAction: TextInputAction.done,
            autofocus: true,
            onSubmitted: (value) => widget.onSave(value.trim()),
          ),
        ),
        AuraIconButton(
          icon: Icons.check,
          onPressed: () => widget.onSave(_controller.text.trim()),
          tooltip: LocaleKeys.common_save.tr(),
        ),
        AuraIconButton(
          icon: Icons.close,
          onPressed: widget.onCancel,
          tooltip: LocaleKeys.common_cancel.tr(),
        ),
      ],
    );
  }
}

void _openDetails(
  BuildContext context, {
  required String? accountId,
  required String? cloudWorkspaceId,
}) {
  final parsedId = int.tryParse(cloudWorkspaceId ?? '');
  final workspaceId = GoRouterState.of(
    context,
  ).pathParameters['workspaceId'];
  if (accountId == null || parsedId == null || workspaceId == null) return;

  context.go(
    CloudWorkspaceDetailRoute(
      workspaceId: workspaceId,
      cloudAccountId: accountId,
      cloudWorkspaceId: parsedId,
    ).location,
  );
}

void _showError(BuildContext context, Object error) {
  final message = switch (error) {
    WorkspaceException(:final localizationKey, :final message) =>
      localizationKey?.tr() ?? message,
    AppCloudWorkspaceException(:final localizationKey) => localizationKey.tr(),
    _ => LocaleKeys.workspace_management_unexpected_error.tr(),
  };
  if (error is! WorkspaceException && error is! AppCloudWorkspaceException) {
    debugPrint('Workspace management failed: $error');
  }
  final _ = showAuraSnackBar(
    context: context,
    content: Text(message),
    variant: AuraSnackBarVariant.error,
  );
}
