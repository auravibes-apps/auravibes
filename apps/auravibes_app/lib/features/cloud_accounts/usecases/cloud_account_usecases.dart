import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_failure.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_email_delivery.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_email_delivery_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/cloud_auth_protocol.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const CloudAccountUseCases({
  required final ServerpodAuthStore _store,
  required final WorkspaceRepository _workspaceRepository,
  required final Future<void> Function({
    required String serverUrl,
    required String userId,
  })
  deleteRemoteAccount,
  required final void Function(String serverUrl, String userId)
  invalidateAccount,
  final CloudAuthProtocol Function(String) createAuthProtocol =
      ServerpodCloudAuthProtocol.new,
  final CloudEmailDelivery emailDelivery = CloudEmailDelivery.unavailable,
});

extension CloudAccountUseCasesAuthentication on CloudAccountUseCases {
  Future<CloudAccountSession> login({
    required String email,
    required String password,
    CloudAuthTarget target = const CloudAuthTarget(),
  }) => _authenticate(target, (protocol) => protocol.login(email, password));

  Future<CloudAccountSession> finishRegistration({
    required String registrationToken,
    required String password,
    CloudAuthTarget target = const CloudAuthTarget(),
  }) => _authenticate(
    target,
    (protocol) => protocol.finishRegistration(registrationToken, password),
  );

  Future<CloudAccountSession> _authenticate(
    CloudAuthTarget target,
    Future<CloudAuthResult> Function(CloudAuthProtocol) action,
  ) async {
    final origin = _targetOrigin(target);
    final result = await _request(target, action);
    final session = _validateAuthenticationResult(target, origin, result);
    await _storeAuthenticationResult(origin, result, session);
    invalidateAccount(origin, session.userId);

    return session;
  }

  CloudAccountSession _validateAuthenticationResult(
    CloudAuthTarget target,
    String origin,
    CloudAuthResult result,
  ) {
    final session = result.session;
    if (!target.matchesAuthenticatedIdentity(
      origin: origin,
      authenticatedUserId: result.auth.authUserId.uuid,
      session: session,
    )) {
      throw const CloudAuthFailure(LocaleKeys.cloud_accounts_wrong_identity);
    }

    return session;
  }

  Future<void> _storeAuthenticationResult(
    String origin,
    CloudAuthResult result,
    CloudAccountSession session,
  ) async {
    await _store
        .authSuccessStorage(serverUrl: origin, userId: session.userId)
        .set(result.auth);
    await _store.saveAccount(session);
  }

  Future<T> _request<T>(
    CloudAuthTarget target,
    Future<T> Function(CloudAuthProtocol) action,
  ) async {
    final protocol = createAuthProtocol(_targetOrigin(target));
    try {
      return await action(protocol);
    } finally {
      protocol.close();
    }
  }

  String _targetOrigin(CloudAuthTarget target) {
    if (!target.isValid ||
        (target.accountId != null && target.serverUrl == null)) {
      throw const CloudAuthFailure(LocaleKeys.cloud_accounts_invalid_target);
    }
    String? origin;
    try {
      origin = target.origin;
    } on FormatException {
      // Translate invalid configuration without exposing endpoint or secrets.
    }
    if (origin == null) {
      throw const CloudAuthFailure(LocaleKeys.cloud_accounts_not_configured);
    }

    return origin;
  }
}

extension CloudAccountUseCasesAccountManagement on CloudAccountUseCases {
  Future<void> remove({
    required String serverUrl,
    required String userId,
  }) async {
    final origin = CloudAccountIdentity.canonicalServerOrigin(serverUrl);
    final _ = await _workspaceRepository.deleteCloudWorkspaceMirrorsForAccount(
      userId,
      serverUrl: origin,
    );
    await _removeLocalAccount(origin, userId);
  }

  Future<void> deleteAccount({
    required String serverUrl,
    required String userId,
  }) async {
    final origin = CloudAccountIdentity.canonicalServerOrigin(serverUrl);
    await deleteRemoteAccount(serverUrl: origin, userId: userId);
    final mirrorsRemoved = await _tryDeleteWorkspaceMirrors(origin, userId);
    final accountRemoved = await _tryRemoveLocalAccount(origin, userId);
    if (!mirrorsRemoved || !accountRemoved) {
      throw const CloudAccountDeletionException(
        LocaleKeys.cloud_accounts_delete_local_cleanup_failed,
      );
    }
  }

  Future<bool> _tryDeleteWorkspaceMirrors(String origin, String userId) async {
    try {
      final _ = await _workspaceRepository
          .deleteCloudWorkspaceMirrorsForAccount(userId, serverUrl: origin);

      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> _tryRemoveLocalAccount(String origin, String userId) async {
    try {
      await _removeLocalAccount(origin, userId);

      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _removeLocalAccount(String origin, String userId) async {
    try {
      await _store.removeAccount(serverUrl: origin, userId: userId);
    } finally {
      invalidateAccount(origin, userId);
    }
  }
}

extension CloudAccountUseCasesPasswordRecovery on CloudAccountUseCases {
  Future<UuidValue> startRegistration({
    required String email,
    CloudAuthTarget target = const CloudAuthTarget(),
  }) {
    _requireDelivery();

    return _request(target, (protocol) => protocol.startRegistration(email));
  }

  Future<String> verifyRegistrationCode({
    required UuidValue accountRequestId,
    required String code,
    CloudAuthTarget target = const CloudAuthTarget(),
  }) => _request(
    target,
    (protocol) => protocol.verifyRegistrationCode(accountRequestId, code),
  );

  Future<UuidValue> startPasswordReset({
    required String email,
    CloudAuthTarget target = const CloudAuthTarget(),
  }) {
    _requireDelivery();

    return _request(target, (protocol) => protocol.startPasswordReset(email));
  }

  Future<String> verifyPasswordResetCode({
    required UuidValue passwordResetRequestId,
    required String code,
    CloudAuthTarget target = const CloudAuthTarget(),
  }) => _request(
    target,
    (protocol) =>
        protocol.verifyPasswordResetCode(passwordResetRequestId, code),
  );

  Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
    CloudAuthTarget target = const CloudAuthTarget(),
  }) => _request(
    target,
    (protocol) =>
        protocol.finishPasswordReset(finishPasswordResetToken, newPassword),
  );

  void _requireDelivery() {
    if (emailDelivery == .unavailable) {
      throw const CloudAuthFailure(
        LocaleKeys.cloud_accounts_delivery_unavailable,
      );
    }
  }
}

class const CloudAccountDeletionException(final String localizationKey)
    implements Exception;

final cloudAccountUseCasesProvider = Provider<CloudAccountUseCases>((ref) {
  return CloudAccountUseCases(
    store: ref.watch(serverpodAuthStoreProvider),
    workspaceRepository: ref.watch(workspaceRepositoryProvider),
    deleteRemoteAccount: ({required serverUrl, required userId}) async {
      final client = await ref.read(
        serverpodClientForAccountProvider((
          accountId: userId,
          serverUrl: serverUrl,
        )).future,
      );
      if (client == null) {
        throw const CloudAccountDeletionException(
          LocaleKeys.cloud_accounts_not_configured,
        );
      }
      await client.account.deleteCurrentUser();
    },
    invalidateAccount: (serverUrl, userId) {
      ref.invalidate(
        cloudAccountHealthProvider(
          CloudAccountKeyFactory.fromIdentity(serverUrl, userId),
        ),
      );
      final key = CloudAccountKeyFactory.fromIdentity(serverUrl, userId);
      ref
        ..invalidate(cloudAccountsProvider)
        ..invalidate(cloudWorkspaceStateProvider(key))
        ..invalidate(cloudWorkspaceUseCasesProvider(key))
        ..invalidate(serverpodClientForAccountProvider(key))
        ..invalidate(serverpodClientForWorkspaceProvider(key));
    },
    emailDelivery: ref.watch(cloudEmailDeliveryProvider),
  );
});
