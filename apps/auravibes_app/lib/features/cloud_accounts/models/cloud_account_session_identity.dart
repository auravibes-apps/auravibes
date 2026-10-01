import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';

extension CloudAccountSessionIdentity on CloudAccountSession {
  CloudAccountKey get key => keyForUser(userId);

  CloudAccountKey keyForUser(String userId) =>
      cloudAccountKey(serverUrl, userId);
}

extension WorkspaceCloudAccountIdentity on WorkspaceEntity {
  CloudAccountKey? get cloudAccount {
    final account = cloudAccountId;
    if (account == null) return null;

    return cloudAccountFor(account);
  }

  CloudAccountKey? cloudAccountFor(String accountId) {
    final origin = url;
    if (origin == null) return null;
    try {
      return cloudAccountKey(origin, accountId);
    } on FormatException {
      // Invalid mirrors remain visible for management and removal.
      return null;
    }
  }
}
