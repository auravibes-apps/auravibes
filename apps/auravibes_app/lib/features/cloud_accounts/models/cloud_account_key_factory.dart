import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';

typedef CloudAccountKey = ({String serverUrl, String accountId});

abstract final class CloudAccountKeyFactory {
  static CloudAccountKey fromIdentity(String serverUrl, String accountId) => (
    serverUrl: CloudAccountIdentity.canonicalServerOrigin(serverUrl),
    accountId: accountId,
  );
}
