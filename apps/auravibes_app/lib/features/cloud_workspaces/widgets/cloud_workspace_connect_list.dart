import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const CloudWorkspaceConnectList({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final List<WorkspaceEntity> localWorkspaces,
  required final List<CloudWorkspaceSummary> workspaces,
  required final ValueChanged<CloudWorkspaceSummary> onConnect,
  required final ValueChanged<WorkspaceEntity> onOpen,
  final ValueChanged<CloudWorkspaceSummary>? onDetails,
  final ValueChanged<String>? onCopyId,
  super.key,
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
            onConnect: onConnect,
            onOpen: onOpen,
            onDetails: onDetails,
            onCopyId: onCopyId,
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
  required final ValueChanged<CloudWorkspaceSummary> onConnect,
  required final ValueChanged<WorkspaceEntity> onOpen,
  final ValueChanged<CloudWorkspaceSummary>? onDetails,
  final ValueChanged<String>? onCopyId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AvailableWorkspaceTile(
      connectedMirror: localWorkspaces.firstWhereOrNull(
        (local) => _isConnectedElsewhere(local, workspace, account.key),
      ),
      workspace: workspace,
      connectedAccountEmail: _connectedElsewhereEmail((
        workspace: workspace,
        account: account.key,
        accounts: accounts,
        localWorkspaces: localWorkspaces,
      )),
      account: account.key,
      onConnect: onConnect,
      onOpen: onOpen,
      onDetails: onDetails,
      onCopyId: onCopyId,
    );
  }
}

String? _connectedElsewhereEmail(
  ({
    CloudWorkspaceSummary workspace,
    CloudAccountKey account,
    List<CloudAccountSession> accounts,
    List<WorkspaceEntity> localWorkspaces,
  })
  input,
) {
  final mirror = input.localWorkspaces.firstWhereOrNull(
    (local) => _isConnectedElsewhere(local, input.workspace, input.account),
  );

  if (mirror == null) return null;

  return input.accounts
          .firstWhereOrNull(
            (account) =>
                account.userId == mirror.cloudAccountId &&
                account.key.serverUrl == input.account.serverUrl,
          )
          ?.email ??
      mirror.cloudAccountId;
}

bool _isConnectedElsewhere(
  WorkspaceEntity local,
  CloudWorkspaceSummary workspace,
  CloudAccountKey account,
) {
  return local.cloudWorkspaceId == workspace.id.toString() &&
      local.cloudAccountId != account.accountId &&
      local.cloudAccount?.serverUrl == account.serverUrl;
}

class const _AvailableWorkspaceTile({
  required final WorkspaceEntity? connectedMirror,
  required final CloudWorkspaceSummary workspace,
  required final String? connectedAccountEmail,
  required final CloudAccountKey account,
  required final ValueChanged<CloudWorkspaceSummary> onConnect,
  required final ValueChanged<WorkspaceEntity> onOpen,
  final ValueChanged<CloudWorkspaceSummary>? onDetails,
  final ValueChanged<String>? onCopyId,
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
        connectedMirror: connectedMirror,
        workspace: workspace,
        account: account,
        onConnect: onConnect,
        onOpen: onOpen,
        onDetails: onDetails,
        onCopyId: onCopyId,
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
  required final WorkspaceEntity? connectedMirror,
  required final CloudWorkspaceSummary workspace,
  required final CloudAccountKey account,
  required final ValueChanged<CloudWorkspaceSummary> onConnect,
  required final ValueChanged<WorkspaceEntity> onOpen,
  final ValueChanged<CloudWorkspaceSummary>? onDetails,
  final ValueChanged<String>? onCopyId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectorId =
        'workspace_available_menu_${account.serverUrl}_'
        '${account.accountId}_${workspace.id}';

    return Semantics(
      key: ValueKey<String>(selectorId),
      child: AuraPopupMenuButton(
        items: [
          if (onDetails != null) _detailsItem(),
          if (onCopyId != null) _copyIdItem(),
          _connectItem(),
        ],
        tooltip: LocaleKeys.common_show_more.tr(),
      ),
      identifier: selectorId,
    );
  }

  AuraPopupMenuItem _detailsItem() {
    return AuraPopupMenuItem(
      title: const TextLocale('common.details'),
      onTap: () => onDetails?.call(workspace),
    );
  }

  AuraPopupMenuItem _connectItem() {
    return AuraPopupMenuItem(
      title: TextLocale(
        connectedMirror == null
            ? LocaleKeys.workspace_management_cloud_attach
            : LocaleKeys.workspace_management_open_workspaces,
      ),
      onTap: _connectOrOpen,
    );
  }

  void _connectOrOpen() {
    final mirror = connectedMirror;
    if (mirror == null) {
      onConnect(workspace);
    } else {
      onOpen(mirror);
    }
  }

  AuraPopupMenuItem _copyIdItem() {
    return AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.workspace_management_copy_id),
      onTap: () => onCopyId?.call(workspace.id.toString()),
    );
  }
}
