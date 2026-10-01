import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';

export 'cloud_account_session_identity.dart';

typedef CloudAccountKey = ({String serverUrl, String accountId});

CloudAccountKey cloudAccountKey(String serverUrl, String accountId) => (
  serverUrl: CloudAccountIdentity.canonicalServerOrigin(serverUrl),
  accountId: accountId,
);
