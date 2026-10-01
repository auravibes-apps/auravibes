import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

typedef CloudAuthResult = ({CloudAccountSession session, AuthSuccess auth});

abstract interface class CloudAuthProtocol {
  Future<CloudAuthResult> login(String email, String password);
  Future<CloudAuthResult> finishRegistration(String token, String password);
  Future<UuidValue> startRegistration(String email);
  Future<String> verifyRegistrationCode(UuidValue request, String code);
  Future<UuidValue> startPasswordReset(String email);
  Future<String> verifyPasswordResetCode(UuidValue request, String code);
  Future<void> finishPasswordReset(String token, String password);
  void close();
}

class ServerpodCloudAuthProtocol implements CloudAuthProtocol {
  new(this.origin) : _client = Client('$origin/');
  final String origin;
  final Client _client;

  @override
  Future<CloudAuthResult> login(String email, String password) async =>
      await _identify(
        await _client.emailIdp.login(email: email, password: password),
      );
  @override
  Future<CloudAuthResult> finishRegistration(
    String token,
    String password,
  ) async => await _identify(
    await _client.emailIdp.finishRegistration(
      registrationToken: token,
      password: password,
    ),
  );
  @override
  Future<UuidValue> startRegistration(String email) =>
      _client.emailIdp.startRegistration(email: email);
  @override
  Future<String> verifyRegistrationCode(UuidValue request, String code) =>
      _client.emailIdp.verifyRegistrationCode(
        accountRequestId: request,
        verificationCode: code,
      );
  @override
  Future<UuidValue> startPasswordReset(String email) =>
      _client.emailIdp.startPasswordReset(email: email);
  @override
  Future<String> verifyPasswordResetCode(UuidValue request, String code) =>
      _client.emailIdp.verifyPasswordResetCode(
        passwordResetRequestId: request,
        verificationCode: code,
      );
  @override
  Future<void> finishPasswordReset(String token, String password) =>
      _client.emailIdp.finishPasswordReset(
        finishPasswordResetToken: token,
        newPassword: password,
      );
  @override
  void close() => _client.close();

  Future<CloudAuthResult> _identify(AuthSuccess auth) async {
    _client.authSessionManager = .new(storage: _EphemeralAuth());
    await _client.auth.updateSignedInUser(auth);
    final account = await _client.account.currentUser();

    return (
      auth: auth,
      session: CloudAccountSession(
        serverUrl: origin,
        userId: account.userId,
        email: account.email,
      ),
    );
  }
}

class _EphemeralAuth implements ClientAuthSuccessStorage {
  AuthSuccess? _value;
  @override
  Future<AuthSuccess?> get() async => _value;
  @override
  Future<void> set(AuthSuccess? value) async {
    _value = value;
  }
}
