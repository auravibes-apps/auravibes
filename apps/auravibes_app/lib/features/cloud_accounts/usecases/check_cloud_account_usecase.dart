import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CheckCloudAccountUsecase({
  required final Future<String?> Function(CloudAccountKey) _check,
}) {
  Future<CloudAccountHealth> call(CloudAccountKey key) async {
    try {
      final userId = await _check(key);

      return CloudAccountHealth(
        status: userId == key.accountId ? .verified : .needsSignIn,
        checkedAt: .now(),
      );
    } on CloudWorkspaceException catch (error) {
      return CloudAccountHealth(
        status: requiresSignIn(error) ? .needsSignIn : .unknown,
      );
    } on Object {
      return const CloudAccountHealth(status: .unknown);
    }
  }

  static bool requiresSignIn(CloudWorkspaceException error) =>
      error.code == CloudWorkspaceErrorCode.authenticationRequired ||
      error.code == CloudWorkspaceErrorCode.emailAccountRequired;
}
