// ignore_for_file: type=lint

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CloudWorkspaceDetailScreen extends ConsumerWidget {
  const CloudWorkspaceDetailScreen({
    required this.workspaceId,
    required this.cloudAccountId,
    required this.cloudWorkspaceId,
    super.key,
  });

  final String workspaceId;
  final String cloudAccountId;
  final int cloudWorkspaceId;

  CloudWorkspaceDetailKey get _key => (
    accountId: cloudAccountId,
    workspaceId: cloudWorkspaceId,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cloudWorkspaceDetailProvider(_key));
    return AuraScreen(
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.cloud_workspaces_detail_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: switch (state) {
        AsyncData(:final value?) => _DetailBody(
          state: value,
          accountId: cloudAccountId,
          mirror:
              (ref.watch(allWorkspacesProvider).value ??
                      const <WorkspaceEntity>[])
                  .where(
                    (item) =>
                        item.cloudWorkspaceId == cloudWorkspaceId.toString() &&
                        item.cloudAccountId == cloudAccountId,
                  )
                  .firstOrNull,
          onChanged: () {
            ref.invalidate(cloudWorkspaceDetailProvider(_key));
            ref.invalidate(cloudWorkspaceStateProvider(cloudAccountId));
            ref.invalidate(allWorkspacesProvider);
          },
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() || AsyncData() => const Center(
          child: TextLocale(LocaleKeys.workspace_management_cloud_error),
        ),
      },
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.state,
    required this.accountId,
    required this.mirror,
    required this.onChanged,
  });

  final CloudWorkspaceDetailState state;
  final String accountId;
  final WorkspaceEntity? mirror;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = state.detail;
    final workspace = detail.workspace;
    final capabilities = detail.capabilities;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AuraText(child: Text(workspace.name), style: AuraTextStyle.heading4),
        Text(_roleLabel(workspace.role).tr()),
        if (detail.ownerEmail != null) Text(detail.ownerEmail!),
        const SizedBox(height: 16),
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
            variant: AuraButtonVariant.outlined,
            onPressed: () => _rename(context, ref, workspace),
            child: const TextLocale(LocaleKeys.cloud_workspaces_rename),
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
              accountId: accountId,
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
              accountId: accountId,
              workspaceId: workspace.id,
              invite: invite,
              onChanged: onChanged,
            ),
        ],
        const SizedBox(height: 32),
        if (capabilities.canLeave)
          AuraButton(
            variant: AuraButtonVariant.outlined,
            onPressed: () => _leave(context, ref, workspace),
            child: const TextLocale(LocaleKeys.cloud_workspaces_leave),
          ),
        if (capabilities.canDelete)
          AuraButton(
            variant: AuraButtonVariant.outlined,
            onPressed: () => _delete(context, ref, workspace),
            child: const TextLocale(LocaleKeys.cloud_workspaces_delete),
          ),
      ],
    );
  }

  Future<CloudWorkspaceUseCases?> _useCases(WidgetRef ref) =>
      ref.read(cloudWorkspaceUseCasesProvider(accountId).future);

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
    await _runCloudAction(context, () async {
      final useCases = await _useCases(ref);
      if (mirror == null) {
        await useCases?.attach(workspace);
      } else {
        await useCases?.detach(workspace);
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
    await _runCloudAction(context, () async {
      await (await _useCases(ref))?.rename(
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
    await _runCloudAction(context, () async {
      await (await _useCases(ref))?.invite(
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
    await _runCloudAction(context, () async {
      await (await _useCases(ref))?.leave(
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
    await _runCloudAction(context, () async {
      await (await _useCases(ref))?.delete(workspace);
      if (context.mounted) Navigator.of(context).pop();
    });
  }
}

Future<void> _runCloudAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on Object catch (error) {
    if (!context.mounted) return;
    debugPrint('Cloud workspace action failed: $error');
    final _ = showAuraSnackBar(
      context: context,
      content: const TextLocale(LocaleKeys.workspace_management_cloud_error),
      variant: AuraSnackBarVariant.error,
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.accountId,
    required this.workspace,
    required this.member,
    required this.capabilities,
    required this.onChanged,
  });
  final String accountId;
  final CloudWorkspaceSummary workspace;
  final CloudWorkspaceMemberSummary member;
  final CloudWorkspaceCapabilities capabilities;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraTile(
    child: AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: .xs,
      children: [Text(member.email ?? member.userId), Text(member.role)],
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

  Future<CloudWorkspaceUseCases?> _useCases(WidgetRef ref) =>
      ref.read(cloudWorkspaceUseCasesProvider(accountId).future);

  Future<void> _changeRole(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(context, LocaleKeys.cloud_workspaces_change_role)) {
      return;
    }
    await _runCloudAction(context, () async {
      await (await _useCases(ref))?.updateMemberRole(
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
    await _runCloudAction(context, () async {
      await (await _useCases(ref))?.removeMember(
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
    await _runCloudAction(context, () async {
      await (await _useCases(ref))?.transferOwnership(
        workspaceId: workspace.id,
        newOwnerUserId: member.userId,
        expectedWorkspaceRevision: workspace.revision,
      );
      onChanged();
    });
  }
}

class _OutgoingInviteTile extends ConsumerWidget {
  const _OutgoingInviteTile({
    required this.accountId,
    required this.workspaceId,
    required this.invite,
    required this.onChanged,
  });
  final String accountId;
  final int workspaceId;
  final CloudWorkspaceInviteSummary invite;
  final VoidCallback onChanged;

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

  Future<CloudWorkspaceUseCases?> _useCases(WidgetRef ref) =>
      ref.read(cloudWorkspaceUseCasesProvider(accountId).future);

  Future<void> _renew(BuildContext context, WidgetRef ref) async {
    await _runCloudAction(context, () async {
      await (await _useCases(ref))?.renewInvite(
        workspaceId: workspaceId,
        inviteId: invite.id,
        expectedInviteRevision: invite.revision,
      );
      onChanged();
    });
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    await _runCloudAction(context, () async {
      await (await _useCases(ref))?.revokeInvite(
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
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const TextLocale(LocaleKeys.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const TextLocale(LocaleKeys.common_confirm),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

Future<bool> _confirm(
  BuildContext context,
  String key, {
  Map<String, String>? namedArgs,
}) async {
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
  final result = await showDialog<_InviteRequest>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, autofocus: true),
            if (allowAdmin)
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'member',
                    child: TextLocale(
                      LocaleKeys.workspace_management_cloud_role_member,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: TextLocale(
                      LocaleKeys.workspace_management_cloud_role_admin,
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => role = value ?? 'member'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const TextLocale(LocaleKeys.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop((email: controller.text, role: role)),
            child: const TextLocale(LocaleKeys.common_add),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
}
