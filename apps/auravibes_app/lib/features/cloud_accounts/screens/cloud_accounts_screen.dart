// ignore_for_file: type=lint

import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/experimental/mutation.dart';

import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/check_cloud_account_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_health_status.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/text_locale.dart';

class const CloudAccountsScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(cloudAccountsProvider);

    return AppScreen(
      child: ListView(
        padding: const EdgeInsets.all(16)
            .copyWith(bottom: BottomPadding.of(context)),
        children: [
          const _AccountsScopeNotice(),
          const SizedBox(height: 12),
          if (AppEnvConfig.auravibesServerUrl.isEmpty &&
              accountsAsync.value?.isEmpty == true) ...[
            const _AccountsUnconfiguredNotice(),
            const SizedBox(height: 12),
          ],
          switch (accountsAsync) {
            AsyncData(:final value) => _AccountList(
              accounts: value,
              workspaceId: workspaceId,
            ),
            AsyncLoading() => const Center(child: AuraSpinner()),
            AsyncError() => const AuraText(
              child: TextLocale(LocaleKeys.cloud_accounts_load_error),
            ),
          },
        ],
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.cloud_accounts_title),
      ),
    );
  }
}

class const _AccountsScopeNotice() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraCard(
    style: .border,
    padding: .medium,
    child: AuraRow(
      children: [
        ExcludeSemantics(child: Icon(Icons.info_outline, size: 20)),
        Expanded(
          child: AuraText(
            child: TextLocale(LocaleKeys.navigation_accounts_scope),
            style: .bodySmall,
          ),
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: CrossAxisAlignment.start,
    ),
  );
}

class const _AccountsUnconfiguredNotice() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraCard(
    style: .border,
    tint: .warning,
    padding: .medium,
    child: AuraRow(
      children: [
        ExcludeSemantics(child: Icon(Icons.warning_amber_rounded, size: 20)),
        Expanded(
          child: AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_not_configured),
            style: .bodySmall,
          ),
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: CrossAxisAlignment.start,
    ),
  );
}

typedef _AccountConfirmCallback = Future<void> Function(
  CloudAccountSession account, {
  required bool deleteCloudAccount,
});

class const _AccountList({
  required final List<CloudAccountSession> accounts,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accounts.isEmpty) {
      return _EmptyAccountState(workspaceId: workspaceId);
    }

    return AuraColumn(
      children: [
        for (final account in accounts)
          _AccountTile(
            account: account,
            workspaceId: workspaceId,
            onConfirmAction: (account, {required deleteCloudAccount}) =>
                _confirmAccountAction(
                  context,
                  ref,
                  account,
                  deleteCloudAccount: deleteCloudAccount,
                ),
          ),
        AuraButton(
          onPressed: () => context.go(
            CloudAccountAddRoute(workspaceId: workspaceId).location,
          ),
          child: const TextLocale(LocaleKeys.cloud_accounts_add_another),
          variant: .outlined,
        ),
      ],
      spacing: .md,
      crossAxisAlignment: CrossAxisAlignment.stretch,
    );
  }

  Future<void> _confirmAccountAction(
    BuildContext context,
    WidgetRef ref,
    CloudAccountSession account, {
    required bool deleteCloudAccount,
  }) async {
    final titleKey = deleteCloudAccount
        ? LocaleKeys.cloud_accounts_delete_title
        : LocaleKeys.cloud_accounts_remove_title;
    final messageKey = deleteCloudAccount
        ? LocaleKeys.cloud_accounts_delete_message
        : LocaleKeys.cloud_accounts_remove_message;
    final actionKey = deleteCloudAccount
        ? LocaleKeys.cloud_accounts_delete
        : LocaleKeys.cloud_accounts_remove;
    final confirmed = await AuraDialogs.confirm(
      context: context,
      title: TextLocale(titleKey),
      message: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(messageKey.tr(namedArgs: {'email': account.email})),
          if (deleteCloudAccount) ...[
            const SizedBox(height: 8),
            const TextLocale(LocaleKeys.cloud_accounts_delete_data_notice),
            const SizedBox(height: 8),
            const TextLocale(
              LocaleKeys.cloud_accounts_delete_retained_actor_ids_notice,
            ),
          ],
          if (!deleteCloudAccount) ...[
            const SizedBox(height: 8),
            const TextLocale(
              LocaleKeys.cloud_accounts_remove_local_mirrors_warning,
            ),
          ],
        ],
      ),
      actions: AuraConfirmDialogActions(
        confirmLabel: TextLocale(actionKey),
        cancelLabel: const TextLocale(LocaleKeys.common_cancel),
      ),
    );
    if (confirmed != true) return;

    final activeWorkspace = await ref
        .read(workspaceRepositoryProvider)
        .getWorkspaceById(workspaceId);

    try {
      await WorkspaceManagementMutations.cloudAccount.run(ref, (_) async {
        final useCases = ref.read(cloudAccountUseCasesProvider);
        if (deleteCloudAccount) {
          await useCases.deleteAccount(
            serverUrl: account.serverUrl,
            userId: account.userId,
          );
        } else {
          await useCases.remove(
            serverUrl: account.serverUrl,
            userId: account.userId,
          );
        }
        ref
          ..invalidate(cloudAccountsProvider)
          ..invalidate(allWorkspacesProvider);
      });
    } on Object catch (error) {
      if (error is CloudWorkspaceException &&
          CheckCloudAccountUsecase.requiresSignIn(error)) {
        ref.invalidate(cloudAccountHealthProvider(account.key));
      }
      if (!context.mounted) return;
      ref
        ..invalidate(cloudAccountsProvider)
        ..invalidate(allWorkspacesProvider);
      final errorKey = switch (error) {
        CloudAccountDeletionException(:final localizationKey) =>
          localizationKey,
        CloudWorkspaceException(code: .ownershipTransferRequired) =>
          LocaleKeys.cloud_accounts_delete_owned_workspaces_error,
        CloudWorkspaceException(code: .workspaceErasurePending) =>
          LocaleKeys.cloud_accounts_workspace_erasure_pending_error,
        CloudWorkspaceException(code: .authenticationRequired) =>
          LocaleKeys.cloud_accounts_session_expired,
        CloudWorkspaceException(code: .emailAccountRequired) =>
          LocaleKeys.cloud_accounts_session_expired,
        _ =>
          deleteCloudAccount
              ? LocaleKeys.cloud_accounts_delete_failed
              : LocaleKeys.cloud_accounts_remove_failed,
      };
      final _ = AuraSnackBars.show(
        context: context,
        content: TextLocale(errorKey),
        variant: .error,
      );
      return;
    }
    if (deleteCloudAccount && context.mounted) {
      await AuraDialogs.alert(
        context: context,
        title: const TextLocale(LocaleKeys.cloud_accounts_delete_result_title),
        message: const TextLocale(
          LocaleKeys.cloud_accounts_delete_result_notice,
        ),
        dismissLabel: const TextLocale(
          LocaleKeys.cloud_accounts_delete_result_dismiss,
        ),
      );
    }
    if (!context.mounted ||
        activeWorkspace?.cloudAccount != account.key ||
        ref.read(WorkspaceManagementMutations.cloudAccount) is MutationError) {
      return;
    }

    final workspaces = await ref.read(allWorkspacesProvider.future);
    if (workspaces.isEmpty || !context.mounted) return;

    NewChatRoute(workspaceId: workspaces.first.id).go(context);
  }
}

class const _EmptyAccountState({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    style: .border,
    padding: .large,
    child: AuraColumn(
      children: [
        const ExcludeSemantics(child: Icon(Icons.cloud_outlined, size: 48)),
        const AuraText(
          child: TextLocale(LocaleKeys.cloud_accounts_empty),
          style: .body,
          textAlign: TextAlign.center,
        ),
        AuraButton(
          onPressed: () => context.go(
            CloudAccountAddRoute(workspaceId: workspaceId).location,
          ),
          child: const TextLocale(LocaleKeys.cloud_accounts_add),
          variant: .primary,
        ),
      ],
      spacing: .md,
      crossAxisAlignment: CrossAxisAlignment.center,
    ),
  );
}

class const _AccountTile({
  required final CloudAccountSession account,
  required final String workspaceId,
  required final _AccountConfirmCallback onConfirmAction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    variant: .surface,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AuraColumn(
        children: [
          AuraRow(
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.account_circle_outlined, size: 28),
              ),
              Expanded(
                child: AuraText(child: Text(account.email), style: .heading6),
              ),
            ],
            spacing: .sm,
          ),
          CloudAccountHealthStatus(
            account: account.key,
            workspaceId: workspaceId,
            returnPath: CloudAccountsRoute(workspaceId: workspaceId).location,
            email: account.email,
          ),
          const Divider(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AuraButton(
                onPressed: () =>
                    onConfirmAction(account, deleteCloudAccount: false),
                child: const TextLocale(LocaleKeys.cloud_accounts_remove),
                variant: .outlined,
                size: .small,
              ),
              AuraButton(
                onPressed: () =>
                    onConfirmAction(account, deleteCloudAccount: true),
                child: const TextLocale(LocaleKeys.cloud_accounts_delete),
                variant: .ghost,
                tint: .error,
                size: .small,
              ),
            ],
          ),
        ],
        spacing: .sm,
        crossAxisAlignment: CrossAxisAlignment.stretch,
      ),
    ),
  );
}
