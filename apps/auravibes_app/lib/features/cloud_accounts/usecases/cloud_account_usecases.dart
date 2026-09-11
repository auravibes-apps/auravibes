import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

class const CloudAccountUseCases({
  required final ServerpodAuthStore _store,
  required final WorkspaceRepository _workspaceRepository,
  required final void Function(String serverUrl, String userId)
  invalidateAccount,
});

extension CloudAccountUseCasesAuthentication on CloudAccountUseCases {
  Future<CloudAccountSession> login({
    required String email,
    required String password,
  }) async {
    final client = _newCloudClient();
    final auth = await client.emailIdp.login(email: email, password: password);

    return await _saveSignedInAccount(client, auth);
  }

  Future<CloudAccountSession> finishRegistration({
    required String registrationToken,
    required String password,
  }) async {
    final client = _newCloudClient();
    final auth = await client.emailIdp.finishRegistration(
      registrationToken: registrationToken,
      password: password,
    );

    return await _saveSignedInAccount(client, auth);
  }

  Future<void> remove({
    required String serverUrl,
    required String userId,
  }) async {
    final origin = CloudAccountIdentity.canonicalServerOrigin(serverUrl);
    final _ = await _workspaceRepository.deleteCloudWorkspaceMirrorsForAccount(
      userId,
      serverUrl: origin,
    );
    await _store.removeAccount(serverUrl: origin, userId: userId);
    invalidateAccount(origin, userId);
  }

  Future<CloudAccountSession> _saveSignedInAccount(
    Client client,
    AuthSuccess auth,
  ) async {
    final userId = auth.authUserId.uuid;
    final sessionManager = _clientAuthSessionManager(_store, userId);
    client.authSessionManager = sessionManager;
    final _ = await sessionManager.initialize();
    await client.auth.updateSignedInUser(auth);

    return await _saveCurrentAccount(_store, client);
  }
}

extension CloudAccountUseCasesPasswordRecovery on CloudAccountUseCases {
  Future<UuidValue> startRegistration({required String email}) {
    return _newCloudClient().emailIdp.startRegistration(email: email);
  }

  Future<String> verifyRegistrationCode({
    required UuidValue accountRequestId,
    required String code,
  }) {
    return _newCloudClient().emailIdp.verifyRegistrationCode(
      accountRequestId: accountRequestId,
      verificationCode: code,
    );
  }

  Future<UuidValue> startPasswordReset({required String email}) {
    return _newCloudClient().emailIdp.startPasswordReset(email: email);
  }

  Future<String> verifyPasswordResetCode({
    required UuidValue passwordResetRequestId,
    required String code,
  }) {
    return _newCloudClient().emailIdp.verifyPasswordResetCode(
      passwordResetRequestId: passwordResetRequestId,
      verificationCode: code,
    );
  }

  Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) {
    return _newCloudClient().emailIdp.finishPasswordReset(
      finishPasswordResetToken: finishPasswordResetToken,
      newPassword: newPassword,
    );
  }
}

Client _newCloudClient() {
  const serverUrl = AppEnvConfig.auravibesServerUrl;
  if (serverUrl.isEmpty) {
    throw const CloudAccountException('Cloud server is not configured');
  }

  return Client(serverUrl);
}

ClientAuthSessionManager _clientAuthSessionManager(
  ServerpodAuthStore store,
  String userId,
) => ClientAuthSessionManager(
  storage: store.authSuccessStorage(
    serverUrl: AppEnvConfig.auravibesServerUrl,
    userId: userId,
  ),
);

Future<CloudAccountSession> _saveCurrentAccount(
  ServerpodAuthStore store,
  Client client,
) async {
  final account = await client.account.currentUser();
  final session = _cloudAccountSession(
    userId: account.userId,
    email: account.email,
  );
  await store.saveAccount(session);

  return session;
}

CloudAccountSession _cloudAccountSession({
  required String userId,
  required String email,
}) => CloudAccountSession(
  serverUrl: CloudAccountIdentity.canonicalServerOrigin(
    AppEnvConfig.auravibesServerUrl,
  ),
  userId: userId,
  email: email,
);

class const CloudAccountException(final String message) implements Exception {
  @override
  String toString() => message;
}

final cloudAccountUseCasesProvider = Provider<CloudAccountUseCases>((ref) {
  return CloudAccountUseCases(
    store: ref.watch(serverpodAuthStoreProvider),
    workspaceRepository: ref.watch(workspaceRepositoryProvider),
    invalidateAccount: (serverUrl, userId) {
      final key = (serverUrl: serverUrl, accountId: userId);
      ref
        ..invalidate(serverpodClientForAccountProvider(key))
        ..invalidate(serverpodClientForWorkspaceProvider(key));
    },
  );
});
