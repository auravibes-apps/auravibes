// ignore_for_file: type=lint

import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/experimental/mutation.dart';

class const CloudAccountsScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(cloudAccountsProvider);

    return AuraScreen(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (AppEnvConfig.auravibesServerUrl.isEmpty)
            const AuraText(
              child: TextLocale(LocaleKeys.cloud_accounts_not_configured),
            )
          else
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

class const _AccountList({
  required final List<CloudAccountSession> accounts,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraColumn(
      children: [
        if (accounts.isEmpty)
          const AuraText(child: TextLocale(LocaleKeys.cloud_accounts_empty)),
        AuraButton(
          onPressed: () => context.go(
            CloudAccountAddRoute(workspaceId: workspaceId).location,
          ),
          child: TextLocale(
            accounts.isEmpty
                ? LocaleKeys.cloud_accounts_add
                : LocaleKeys.cloud_accounts_add_another,
          ),
        ),
        for (final account in accounts)
          AuraTile(
            child: AuraColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: .xs,
              children: [
                Text(account.email),
                const AuraText(
                  child: TextLocale(LocaleKeys.cloud_accounts_status_signed_in),
                  style: AuraTextStyle.bodySmall,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AuraButton(
                      onPressed: () => _confirmAccountAction(
                        context,
                        ref,
                        account,
                        deleteCloudAccount: false,
                      ),
                      child: const TextLocale(LocaleKeys.cloud_accounts_remove),
                      variant: AuraButtonVariant.outlined,
                    ),
                    AuraButton(
                      onPressed: () => _confirmAccountAction(
                        context,
                        ref,
                        account,
                        deleteCloudAccount: true,
                      ),
                      child: const TextLocale(LocaleKeys.cloud_accounts_delete),
                      variant: AuraButtonVariant.outlined,
                      tint: .error,
                    ),
                  ],
                ),
              ],
            ),
            variant: AuraTileVariant.ghost,
          ),
      ],
      spacing: .sm,
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
          const SizedBox(height: 8),
          const TextLocale(
            LocaleKeys.cloud_accounts_remove_local_mirrors_warning,
          ),
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
      if (!context.mounted) return;
      ref
        ..invalidate(cloudAccountsProvider)
        ..invalidate(allWorkspacesProvider);
      final errorKey = switch (error) {
        CloudAccountDeletionException(:final localizationKey) =>
          localizationKey,
        CloudWorkspaceException(code: .ownershipTransferRequired) =>
          LocaleKeys.cloud_accounts_delete_owned_workspaces_error,
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
    if (!context.mounted ||
        activeWorkspace?.cloudAccountId != account.userId ||
        ref.read(WorkspaceManagementMutations.cloudAccount) is MutationError) {
      return;
    }

    final workspaces = await ref.read(allWorkspacesProvider.future);
    if (workspaces.isEmpty || !context.mounted) return;

    NewChatRoute(workspaceId: workspaces.first.id).go(context);
  }
}
