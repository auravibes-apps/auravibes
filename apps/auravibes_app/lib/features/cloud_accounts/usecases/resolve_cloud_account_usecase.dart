import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';

abstract final class ResolveCloudAccountUsecase {
  static CloudAccountKey call({
    required String accountId,
    required List<CloudAccountSession> accounts,
    List<WorkspaceEntity> mirrors = const [],
    int? workspaceId,
    String? serverUrl,
  }) {
    final candidates = <CloudAccountKey>{
      for (final account in accounts)
        if (account.userId == accountId) account.key,
      for (final mirror in mirrors)
        if (mirror.cloudAccountId == accountId &&
            mirror.cloudWorkspaceId == workspaceId?.toString() &&
            mirror.cloudAccount != null)
          ?mirror.cloudAccount,
    };
    if (serverUrl != null) {
      final explicit = cloudAccountKey(serverUrl, accountId);
      if (candidates.contains(explicit)) return explicit;
    } else if (candidates.length == 1) {
      return candidates.single;
    }
    throw const AppCloudWorkspaceException(
      LocaleKeys.cloud_accounts_origin_unresolved,
    );
  }
}
