import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';

extension CloudAccountSessionIdentity on CloudAccountSession {
  CloudAccountKey get key => cloudAccountKey(serverUrl, userId);
}

extension WorkspaceCloudAccountIdentity on WorkspaceEntity {
  CloudAccountKey? get cloudAccount {
    final origin = url;
    final account = cloudAccountId;
    if (origin == null || account == null) return null;
    try {
      return cloudAccountKey(origin, account);
    } on FormatException {
      // Invalid mirrors remain visible for management and removal.
      return null;
    }
  }
}
