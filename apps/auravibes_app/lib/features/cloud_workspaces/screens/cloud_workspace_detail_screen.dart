// ignore_for_file: type=lint

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/check_cloud_account_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_health_status.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('cloud_workspace_detail_screen');

class const CloudWorkspaceDetailScreen({
  required final String workspaceId,
  required final String cloudAccountId,
  required final int cloudWorkspaceId,
  final String? serverUrl,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(
      cloudWorkspaceRouteAccountProvider((
        accountId: cloudAccountId,
        workspaceId: cloudWorkspaceId,
        serverUrl: serverUrl,
      )),
    );
    return switch (account) {
      AsyncData(:final value) => _ResolvedDetail(
        workspaceId: workspaceId,
        account: value,
        cloudWorkspaceId: cloudWorkspaceId,
      ),
      AsyncLoading() => const AuraScreen(child: Center(child: AuraSpinner())),
      AsyncError() => AuraScreen(
        child: Column(
          children: [
            const TextLocale(LocaleKeys.cloud_accounts_origin_unresolved),
            AuraButton(
              onPressed: () => WorkspaceManagementRoute(
                workspaceId: workspaceId,
                view: 'connect',
              ).go(context),
              child: const TextLocale(
                LocaleKeys.workspace_management_connect_cloud,
              ),
            ),
          ],
        ),
      ),
    };
  }
}

class const _ResolvedDetail({
  required final String workspaceId,
  required final CloudAccountKey account,
  required final int cloudWorkspaceId,
}) extends ConsumerWidget {
  CloudWorkspaceDetailKey get _key => (
    serverUrl: account.serverUrl,
    accountId: account.accountId,
    workspaceId: cloudWorkspaceId,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cloudWorkspaceDetailProvider(_key));
    final mirrors =
        (ref.watch(allWorkspacesProvider).value ?? const <WorkspaceEntity>[])
            .where(
              (item) =>
                  item.cloudWorkspaceId == cloudWorkspaceId.toString() &&
                  item.cloudAccount?.serverUrl == account.serverUrl,
            );
    final mirror = mirrors
        .where((item) => item.cloudAccount == account)
        .firstOrNull;

    return AuraScreen(
      appBar: AuraAppBarWithDrawer(
        title: state.value == null
            ? const TextLocale(LocaleKeys.cloud_workspaces_detail_title)
            : Text(state.value!.detail.workspace.name),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      child: switch (state) {
        AsyncData(:final value?) => _DetailBody(
          state: value,
          account: account,
          workspaceId: workspaceId,
          mirror: mirror,
          connectedElsewhere: mirror == null ? mirrors.firstOrNull : null,
          onChanged: () {
            ref.invalidate(cloudWorkspaceDetailProvider(_key));
            ref.invalidate(cloudWorkspaceStateProvider(account));
            ref.invalidate(allWorkspacesProvider);
          },
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() || AsyncData() => Column(
          children: [
            CloudAccountHealthStatus(
              account: account,
              workspaceId: workspaceId,
              returnPath: CloudWorkspaceDetailRoute(
                workspaceId: workspaceId,
                cloudAccountId: account.accountId,
                cloudWorkspaceId: cloudWorkspaceId,
                serverUrl: account.serverUrl,
              ).location,
            ),
            TextLocale(switch (state) {
              AsyncError(:final error) => _cloudErrorKey(error),
              _ => LocaleKeys.cloud_errors_unavailable,
            }),
            AuraButton(
              onPressed: () =>
                  ref.invalidate(cloudWorkspaceDetailProvider(_key)),
              child: const TextLocale(
                LocaleKeys.workspace_management_cloud_retry,
              ),
            ),
          ],
        ),
      },
    );
  }
}

class const _DetailBody({
  required final String workspaceId,
  required final CloudWorkspaceDetailState state,
  required final CloudAccountKey account,
  required final WorkspaceEntity? mirror,
  required final WorkspaceEntity? connectedElsewhere,
  required final VoidCallback onChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = state.detail;
    final workspace = detail.workspace;
    final capabilities = detail.capabilities;
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
    return ListView(
      padding: const EdgeInsets.all(16)
          .copyWith(bottom: BottomPadding.of(context)),
      children: [
        AuraText(child: Text(workspace.name), style: AuraTextStyle.heading4),
        Text(_roleLabel(workspace.role).tr()),
        Text(
          ref
                  .watch(cloudAccountsProvider)
                  .value
                  ?.where((item) => item.key == account)
                  .firstOrNull
                  ?.email ??
              account.accountId,
        ),
        CloudAccountHealthStatus(
          account: account,
          workspaceId: workspaceId,
          returnPath: CloudWorkspaceDetailRoute(
            workspaceId: workspaceId,
            cloudAccountId: account.accountId,
            cloudWorkspaceId: workspace.id,
            serverUrl: account.serverUrl,
          ).location,
        ),
        TextLocale(
          mirror == null && connectedElsewhere == null
              ? LocaleKeys.cloud_workspaces_not_connected
              : LocaleKeys.cloud_workspaces_connected,
        ),
        if (connectedElsewhere case final existing?)
          Text(
            LocaleKeys.workspace_management_cloud_connected_elsewhere.tr(
              namedArgs: {
                'email':
                    ref
                        .watch(cloudAccountsProvider)
                        .value
                        ?.where((item) => item.key == existing.cloudAccount)
                        .firstOrNull
                        ?.email ??
                    existing.cloudAccountId ??
                    '',
              },
            ),
          ),
        const TextLocale(LocaleKeys.cloud_workspaces_cloud_context),
        const AuraText(
          style: .heading6,
          child: TextLocale(LocaleKeys.cloud_workspaces_device_connection),
        ),
        if (detail.ownerEmail != null) Text(detail.ownerEmail!),
        const SizedBox(height: 16),
        if (connectedElsewhere case final existing?)
          AuraButton(
            onPressed: () => ref
                .read(workspaceSwitcherProvider.notifier)
                .switchToWorkspace(existing.id),
            child: const TextLocale(
              LocaleKeys.workspace_management_open_workspaces,
            ),
            disabled: switchState.status == .loading,
          )
        else
          AuraButton(
            onPressed: () => _toggleConnection(context, ref, workspace),
            child: TextLocale(
              mirror == null
                  ? LocaleKeys.workspace_management_cloud_attach
                  : LocaleKeys.workspace_management_cloud_detach,
            ),
          ),
        if (capabilities.canRename) ...[
          const SizedBox(height: 24),
          AuraButton(
            onPressed: () => _rename(context, ref, workspace),
            child: const TextLocale(LocaleKeys.cloud_workspaces_rename),
            variant: AuraButtonVariant.outlined,
          ),
        ],
        if (capabilities.canViewMembers) ...[
          const SizedBox(height: 24),
          const AuraText(
            style: AuraTextStyle.heading6,
            child: TextLocale(LocaleKeys.workspace_management_cloud_members),
          ),
          for (final member in state.members)
            _MemberTile(
              account: account,
              workspace: workspace,
              member: member,
              capabilities: capabilities,
              onChanged: onChanged,
            ),
        ],
        if (capabilities.canInviteMembers) ...[
          const SizedBox(height: 24),
          AuraButton(
            onPressed: () => _invite(context, ref, workspace, capabilities),
            child: const TextLocale(
              LocaleKeys.workspace_management_cloud_invite,
            ),
          ),
          for (final invite in state.invites)
            _OutgoingInviteTile(
              account: account,
              workspaceId: workspace.id,
              invite: invite,
              onChanged: onChanged,
            ),
        ],
        const SizedBox(height: 32),
        if (capabilities.canLeave || capabilities.canDelete)
          const AuraText(
            style: .heading6,
            child: TextLocale(LocaleKeys.cloud_workspaces_consequences),
          ),
        if (capabilities.canLeave)
          AuraButton(
            onPressed: () => _leave(context, ref, workspace),
            child: const TextLocale(LocaleKeys.cloud_workspaces_leave),
            variant: AuraButtonVariant.outlined,
          ),
        if (capabilities.canDelete)
          AuraButton(
            onPressed: () => _delete(context, ref, workspace),
            child: const TextLocale(LocaleKeys.cloud_workspaces_delete),
            variant: AuraButtonVariant.outlined,
          ),
      ],
    );
  }

  Future<CloudWorkspaceUseCases> _useCases(WidgetRef ref) async {
    final useCases = await ref.read(
      cloudWorkspaceUseCasesProvider(account).future,
    );
    if (useCases == null)
      throw const AppCloudWorkspaceException(
        LocaleKeys.cloud_errors_unavailable,
      );
    return useCases;
  }

  Future<void> _toggleConnection(
    BuildContext context,
    WidgetRef ref,
    CloudWorkspaceSummary workspace,
  ) async {
    if (mirror != null &&
        !await _confirm(
          context,
          LocaleKeys.cloud_workspaces_remove_confirm,
          namedArgs: {'name': workspace.name},
        )) {
      return;
    }
    await _runCloudAction(context, ref, account, () async {
      final useCases = await _useCases(ref);
      if (mirror == null) {
        await useCases.attach(workspace);
      } else {
        await useCases.detach(workspace);
      }
      onChanged();
    });
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    CloudWorkspaceSummary workspace,
  ) async {
    final name = await _prompt(
      context,
      title: LocaleKeys.cloud_workspaces_rename.tr(),
      initialValue: workspace.name,
    );
    if (name == null) return;
    await _runCloudAction(context, ref, account, () async {
      await (await _useCases(ref)).rename(
        workspaceId: workspace.id,
        name: name,
        expectedWorkspaceRevision: workspace.revision,
      );
      onChanged();
    });
  }

  Future<void> _invite(
    BuildContext context,
    WidgetRef ref,
    CloudWorkspaceSummary workspace,
    CloudWorkspaceCapabilities capabilities,
  ) async {
    final request = await _invitePrompt(
      context,
      title: LocaleKeys.workspace_management_cloud_invite.tr(),
      allowAdmin: capabilities.canInviteAdmins,
    );
    if (request == null || request.email.trim().isEmpty) return;
    await _runCloudAction(context, ref, account, () async {
      await (await _useCases(ref)).invite(
        workspaceId: workspace.id,
        email: request.email,
        role: request.role,
        expectedWorkspaceRevision: workspace.revision,
      );
      onChanged();
    });
  }

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    CloudWorkspaceSummary workspace,
  ) async {
    if (!await _confirm(context, LocaleKeys.cloud_workspaces_leave_confirm)) {
      return;
    }
    await _runCloudAction(context, ref, account, () async {
      await (await _useCases(ref)).leave(
        workspaceId: workspace.id,
        expectedWorkspaceRevision: workspace.revision,
      );
      if (context.mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CloudWorkspaceSummary workspace,
  ) async {
    final confirmation = await _prompt(
      context,
      title: LocaleKeys.cloud_workspaces_delete_confirm.tr(
        namedArgs: {'name': workspace.name},
      ),
    );
    if (confirmation != workspace.name) return;
    await _runCloudAction(context, ref, account, () async {
      await (await _useCases(ref)).delete(workspace);
      if (context.mounted) Navigator.of(context).pop();
    });
  }
}

Future<void> _runCloudAction(
  BuildContext context,
  WidgetRef ref,
  CloudAccountKey account,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on Object catch (error, stackTrace) {
    _logger.warning('Cloud workspace action failed', error, stackTrace);
    if (error is CloudWorkspaceException &&
        CheckCloudAccountUsecase.requiresSignIn(error)) {
      ref.invalidate(cloudAccountHealthProvider(account));
    }
    if (!context.mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: TextLocale(_cloudErrorKey(error)),
      variant: AuraSnackBarVariant.error,
    );
  }
}

class const _MemberTile({
  required final CloudAccountKey account,
  required final CloudWorkspaceSummary workspace,
  required final CloudWorkspaceMemberSummary member,
  required final CloudWorkspaceCapabilities capabilities,
  required final VoidCallback onChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraTile(
    child: AuraColumn(
      children: [
        Text(member.email.orPlaceholder(member.userId.orPlaceholder())),
        TextLocale(_roleLabel(member.role)),
      ],
      spacing: .xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (capabilities.canTransferOwnership && member.role != 'owner')
          AuraIconButton(
            icon: Icons.workspace_premium_outlined,
            tooltip: LocaleKeys.cloud_workspaces_transfer_ownership.tr(),
            onPressed: () => _transfer(context, ref),
          ),
        if (_canManage)
          AuraIconButton(
            icon: member.role == 'admin'
                ? Icons.person_outline
                : Icons.admin_panel_settings_outlined,
            tooltip: LocaleKeys.cloud_workspaces_change_role.tr(),
            onPressed: () => _changeRole(context, ref),
          ),
        if (_canManage)
          AuraIconButton(
            icon: Icons.person_remove_outlined,
            tooltip: LocaleKeys.common_remove.tr(),
            onPressed: () => _remove(context, ref),
          ),
      ],
    ),
  );

  bool get _canManage => member.role == 'admin'
      ? capabilities.canManageAdmins
      : member.role == 'member' && capabilities.canManageMembers;

  Future<CloudWorkspaceUseCases> _useCases(WidgetRef ref) async {
    final useCases = await ref.read(
      cloudWorkspaceUseCasesProvider(account).future,
    );
    if (useCases == null)
      throw const AppCloudWorkspaceException(
        LocaleKeys.cloud_errors_unavailable,
      );
    return useCases;
  }

  Future<void> _changeRole(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(context, LocaleKeys.cloud_workspaces_change_role)) {
      return;
    }
    await _runCloudAction(context, ref, account, () async {
      await (await _useCases(ref)).updateMemberRole(
        workspaceId: workspace.id,
        userId: member.userId,
        role: member.role == 'admin' ? 'member' : 'admin',
        expectedMemberRevision: member.revision,
      );
      onChanged();
    });
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(context, LocaleKeys.cloud_workspaces_remove_member)) {
      return;
    }
    await _runCloudAction(context, ref, account, () async {
      await (await _useCases(ref)).removeMember(
        workspaceId: workspace.id,
        userId: member.userId,
        expectedMemberRevision: member.revision,
      );
      onChanged();
    });
  }

  Future<void> _transfer(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(
      context,
      LocaleKeys.cloud_workspaces_transfer_confirm,
    )) {
      return;
    }
    await _runCloudAction(context, ref, account, () async {
      await (await _useCases(ref)).transferOwnership(
        workspaceId: workspace.id,
        newOwnerUserId: member.userId,
        expectedWorkspaceRevision: workspace.revision,
      );
      onChanged();
    });
  }
}

class const _OutgoingInviteTile({
  required final CloudAccountKey account,
  required final int workspaceId,
  required final CloudWorkspaceInviteSummary invite,
  required final VoidCallback onChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraTile(
    child: Text(invite.email),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraIconButton(
          icon: Icons.refresh,
          tooltip: LocaleKeys.cloud_workspaces_renew_invite.tr(),
          onPressed: () => _renew(context, ref),
        ),
        AuraIconButton(
          icon: Icons.close,
          tooltip: LocaleKeys.cloud_workspaces_revoke_invite.tr(),
          onPressed: () => _revoke(context, ref),
        ),
      ],
    ),
  );

  Future<CloudWorkspaceUseCases> _useCases(WidgetRef ref) async {
    final useCases = await ref.read(
      cloudWorkspaceUseCasesProvider(account).future,
    );
    if (useCases == null)
      throw const AppCloudWorkspaceException(
        LocaleKeys.cloud_errors_unavailable,
      );
    return useCases;
  }

  Future<void> _renew(BuildContext context, WidgetRef ref) async {
    await _runCloudAction(context, ref, account, () async {
      await (await _useCases(ref)).renewInvite(
        workspaceId: workspaceId,
        inviteId: invite.id,
        expectedInviteRevision: invite.revision,
      );
      onChanged();
    });
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    await _runCloudAction(context, ref, account, () async {
      await (await _useCases(ref)).revokeInvite(
        workspaceId: workspaceId,
        inviteId: invite.id,
        expectedInviteRevision: invite.revision,
      );
      onChanged();
    });
  }
}

String _roleLabel(String role) => switch (role) {
  'owner' => LocaleKeys.workspace_management_cloud_role_owner,
  'admin' => LocaleKeys.workspace_management_cloud_role_admin,
  _ => LocaleKeys.workspace_management_cloud_role_member,
};

Future<String?> _prompt(
  BuildContext context, {
  required String title,
  String? initialValue,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<String>(
    context: context,
    builder: (context) =>
        _WorkspaceNamePrompt(title: title, initialValue: initialValue),
  );
}

class const _WorkspaceNamePrompt({
  required final String title,
  required final String? initialValue,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialValue);
    void submit() => Navigator.of(context).pop(controller.text);
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: .done,
        onSubmitted: (_) => submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const TextLocale(LocaleKeys.common_cancel),
        ),
        TextButton(
          onPressed: submit,
          child: const TextLocale(LocaleKeys.common_confirm),
        ),
      ],
    );
  }
}

Future<bool> _confirm(
  BuildContext context,
  String key, {
  Map<String, String>? namedArgs,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(key.tr(namedArgs: namedArgs)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const TextLocale(LocaleKeys.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const TextLocale(LocaleKeys.common_confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

typedef _InviteRequest = ({String email, String role});

Future<_InviteRequest?> _invitePrompt(
  BuildContext context, {
  required String title,
  required bool allowAdmin,
}) async {
  final controller = TextEditingController();
  var role = 'member';
  FocusManager.instance.primaryFocus?.unfocus();
  final result = await showDialog<_InviteRequest>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void submit() =>
            Navigator.of(context).pop((email: controller.text, role: role));

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: .done,
                onSubmitted: (_) => submit(),
              ),
              if (allowAdmin)
                AuraChoicePicker<String>(
                  options: const [
                    AuraChoiceOption(
                      value: 'member',
                      label: TextLocale(
                        LocaleKeys.workspace_management_cloud_role_member,
                      ),
                    ),
                    AuraChoiceOption(
                      value: 'admin',
                      label: TextLocale(
                        LocaleKeys.workspace_management_cloud_role_admin,
                      ),
                    ),
                  ],
                  value: [role],
                  onChanged: (values) {
                    if (values.isEmpty) return;
                    setState(() => role = values.first);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const TextLocale(LocaleKeys.common_cancel),
            ),
            TextButton(
              onPressed: submit,
              child: const TextLocale(LocaleKeys.common_add),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
  return result;
}

String _cloudErrorKey(Object error) {
  if (error case AppCloudWorkspaceException(:final localizationKey))
    return localizationKey;
  try {
    CloudAppErrors.translateException(error, CloudOperationContext.workspace);
  } on CloudAppException catch (translated) {
    return translated.localizationKey;
  }
}
