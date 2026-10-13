import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';

abstract final class ResolveCloudAccountUsecase {
  static CloudAccountKey call(_CloudAccountResolution request) {
    final candidates = <CloudAccountKey>{
      ..._sessionAccountKeys(request),
      ..._workspaceMirrorAccountKeys(request),
    };
    final serverUrl = request.serverUrl;
    if (serverUrl != null) {
      final explicit = CloudAccountKeyFactory.fromIdentity(
        serverUrl,
        request.accountId,
      );
      if (candidates.contains(explicit)) return explicit;
    } else if (candidates.length == 1) {
      return candidates.single;
    }
    throw const AppCloudWorkspaceException(
      LocaleKeys.cloud_accounts_origin_unresolved,
    );
  }
}

typedef _CloudAccountResolution = ({
  String accountId,
  List<CloudAccountSession> accounts,
  List<WorkspaceEntity> mirrors,
  int workspaceId,
  String? serverUrl,
});

Iterable<CloudAccountKey> _sessionAccountKeys(
  _CloudAccountResolution request,
) => request.accounts
    .where((account) => account.userId == request.accountId)
    .map((account) => account.key);

Iterable<CloudAccountKey> _workspaceMirrorAccountKeys(
  _CloudAccountResolution request,
) => request.mirrors
    .where((mirror) => _matchesCloudAccountResolution(mirror, request))
    .map((mirror) => mirror.cloudAccount)
    .nonNulls;

bool _matchesCloudAccountResolution(
  WorkspaceEntity mirror,
  _CloudAccountResolution request,
) =>
    mirror.cloudAccountId == request.accountId &&
    mirror.cloudWorkspaceId ==
        (request.workspaceId < 0 ? null : '${request.workspaceId}') &&
    mirror.cloudAccount != null;
