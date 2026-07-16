import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

class CloudAccountUseCases {
  const CloudAccountUseCases({
    required this._store,
    required this._workspaceRepository,
    this.invalidateAccount,
  });

  final ServerpodAuthStore _store;
  final WorkspaceRepository _workspaceRepository;
  final void Function(String serverUrl, String userId)? invalidateAccount;

  Future<CloudAccountSession> login({
    required String email,
    required String password,
  }) async {
    final client = _newClient();
    final auth = await client.emailIdp.login(email: email, password: password);

    return _saveSignedInAccount(client, auth);
  }

  Future<UuidValue> startRegistration({required String email}) {
    return _newClient().emailIdp.startRegistration(email: email);
  }

  Future<String> verifyRegistrationCode({
    required UuidValue accountRequestId,
    required String code,
  }) {
    return _newClient().emailIdp.verifyRegistrationCode(
      accountRequestId: accountRequestId,
      verificationCode: code,
    );
  }

  Future<CloudAccountSession> finishRegistration({
    required String registrationToken,
    required String password,
  }) async {
    final client = _newClient();
    final auth = await client.emailIdp.finishRegistration(
      registrationToken: registrationToken,
      password: password,
    );

    return _saveSignedInAccount(client, auth);
  }

  Future<UuidValue> startPasswordReset({required String email}) {
    return _newClient().emailIdp.startPasswordReset(email: email);
  }

  Future<String> verifyPasswordResetCode({
    required UuidValue passwordResetRequestId,
    required String code,
  }) {
    return _newClient().emailIdp.verifyPasswordResetCode(
      passwordResetRequestId: passwordResetRequestId,
      verificationCode: code,
    );
  }

  Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) {
    return _newClient().emailIdp.finishPasswordReset(
      finishPasswordResetToken: finishPasswordResetToken,
      newPassword: newPassword,
    );
  }

  Future<void> remove({
    required String serverUrl,
    required String userId,
  }) async {
    final origin = canonicalServerOrigin(serverUrl);
    final _ = await _workspaceRepository.deleteCloudWorkspaceMirrorsForAccount(
      userId,
      serverUrl: origin,
    );
    await _store.removeAccount(serverUrl: origin, userId: userId);
    invalidateAccount?.call(origin, userId);
  }

  Client _newClient() {
    const serverUrl = AppEnvConfig.auravibesServerUrl;
    if (serverUrl.isEmpty) {
      throw const CloudAccountException('Cloud server is not configured');
    }

    return Client(serverUrl);
  }

  Future<CloudAccountSession> _saveSignedInAccount(
    Client client,
    AuthSuccess auth,
  ) async {
    final userId = auth.authUserId.uuid;
    final sessionManager = ClientAuthSessionManager(
      storage: _store.authSuccessStorage(
        serverUrl: AppEnvConfig.auravibesServerUrl,
        userId: userId,
      ),
    );
    client.authSessionManager = sessionManager;
    final _ = await sessionManager.initialize();
    await client.auth.updateSignedInUser(auth);
    final account = await client.account.currentUser();
    final session = CloudAccountSession(
      serverUrl: canonicalServerOrigin(AppEnvConfig.auravibesServerUrl),
      userId: account.userId,
      email: account.email,
    );
    await _store.saveAccount(session);

    return session;
  }
}

class CloudAccountException implements Exception {
  const CloudAccountException(this.message);

  final String message;

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
