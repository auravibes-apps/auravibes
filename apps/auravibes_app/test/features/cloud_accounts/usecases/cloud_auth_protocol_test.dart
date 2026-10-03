import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_failure.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/services/cloud_auth_protocol.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

class _Repository extends Mock implements WorkspaceRepository;

class _Protocol extends Mock implements CloudAuthProtocol;

void main() {
  const user = '11111111-1111-4111-8111-111111111111';
  const origin = 'https://intended.example';
  const email = 'person@example.com';
  const target = CloudAuthTarget(
    serverUrl: origin,
    accountId: user,
    email: email,
  );
  CloudAuthResult result({
    String server = origin,
    String id = user,
    String address = email,
    String subject = user,
  }) => (
    session: CloudAccountSession(serverUrl: server, userId: id, email: address),
    auth: AuthSuccess(
      authStrategy: 'jwt',
      token: 'secret-token',
      authUserId: .fromString(subject),
      scopeNames: {},
    ),
  );
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('login persists and invalidates only the intended identity', () async {
    final protocol = _Protocol();
    final store = ServerpodAuthStore();
    final calls = <String>[];
    when(() => protocol.login(email, 'password'))
        .thenAnswer((_) async => result());
    final usecases = CloudAccountUseCases(
      store: store,
      workspaceRepository: _Repository(),
      deleteRemoteAccount: ({required serverUrl, required userId}) =>
          Future<void>.value(),
      invalidateAccount: (server, id) => calls.add('$server|$id'),
      createAuthProtocol: (server) {
        calls.add(server);

        return protocol;
      },
    );
    final account = await usecases.login(
      email: email,
      password: 'password',
      target: const CloudAuthTarget(
        serverUrl: '$origin/api',
        accountId: user,
        email: email,
      ),
    );
    expect(account.userId, user);
    expect(calls, [origin, '$origin|$user']);
    expect((await store.listAccounts()).single.serverUrl, origin);
    expect(
      (await store.authSuccessStorage(serverUrl: origin, userId: user).get())
          ?.token,
      'secret-token',
    );
    expect(
      await store
          .authSuccessStorage(serverUrl: 'https://other.example', userId: user)
          .get(),
      isNull,
    );
    verify(protocol.close).called(1);
  });
  for (final wrong in [
    result(server: 'https://other.example'),
    result(id: '22222222-2222-4222-8222-222222222222'),
    result(address: 'other@example.com'),
    result(subject: '22222222-2222-4222-8222-222222222222'),
  ]) {
    test(
      'wrong identity cannot persist: ${wrong.session.serverUrl} '
      '${wrong.session.userId} ${wrong.session.email} ${wrong.auth.authUserId}',
      () async {
        final protocol = _Protocol();
        final store = ServerpodAuthStore();
        when(() => protocol.login(email, 'password'))
            .thenAnswer((_) async => wrong);
        final usecases = CloudAccountUseCases(
          store: store,
          workspaceRepository: _Repository(),
          deleteRemoteAccount: ({required serverUrl, required userId}) =>
              Future<void>.value(),
          invalidateAccount: (_, _) => fail('Unexpected invalidation'),
          createAuthProtocol: (_) => protocol,
        );
        await expectLater(
          usecases.login(email: email, password: 'password', target: target),
          throwsA(isA<CloudAuthFailure>()),
        );
        expect(await store.listAccounts(), isEmpty);
        expect(
          await store.authSuccessStorage(serverUrl: origin, userId: user).get(),
          isNull,
        );
      },
    );
  }
  test('registration and reset use the intended origin', () async {
    final protocol = _Protocol();
    final request = UuidValue.fromString(user);
    final origins = <String>[];
    when(() => protocol.startRegistration(email))
        .thenAnswer((_) async => request);
    when(() => protocol.verifyRegistrationCode(request, '123456'))
        .thenAnswer((_) async => 'registration');
    when(() => protocol.finishRegistration('registration', 'password'))
        .thenAnswer((_) async => result());
    when(() => protocol.startPasswordReset(email))
        .thenAnswer((_) async => request);
    when(() => protocol.verifyPasswordResetCode(request, '654321'))
        .thenAnswer((_) async => 'reset');
    when(() => protocol.finishPasswordReset('reset', 'new-password'))
        .thenAnswer((_) => Future<void>.value());
    final usecases = CloudAccountUseCases(
      store: .new(),
      workspaceRepository: _Repository(),
      deleteRemoteAccount: ({required serverUrl, required userId}) =>
          Future<void>.value(),
      invalidateAccount: (server, _) => expect(server, origin),
      createAuthProtocol: (origin) {
        origins.add(origin);

        return protocol;
      },
      emailDelivery: .developmentLog,
    );
    expect(
      await usecases.startRegistration(email: email, target: target),
      request,
    );
    expect(
      await usecases.verifyRegistrationCode(
        accountRequestId: request,
        code: '123456',
        target: target,
      ),
      'registration',
    );
    expect(
      (await usecases.finishRegistration(
        registrationToken: 'registration',
        password: 'password',
        target: target,
      )).userId,
      user,
    );
    expect(
      await usecases.startPasswordReset(email: email, target: target),
      request,
    );
    expect(
      await usecases.verifyPasswordResetCode(
        passwordResetRequestId: request,
        code: '654321',
        target: target,
      ),
      'reset',
    );
    await usecases.finishPasswordReset(
      finishPasswordResetToken: 'reset',
      newPassword: 'new-password',
      target: target,
    );
    expect(origins, List.filled(6, origin));
    verify(protocol.close).called(6);
  });
  test('absent delivery fails before protocol sends requests', () {
    final usecases = CloudAccountUseCases(
      store: .new(),
      workspaceRepository: _Repository(),
      deleteRemoteAccount: ({required serverUrl, required userId}) =>
          Future<void>.value(),
      invalidateAccount: (server, _) => expect(server, origin),
      createAuthProtocol: (_) => throw StateError('Must not send'),
    );
    expect(
      () => usecases.startRegistration(email: email, target: target),
      throwsA(isA<CloudAuthFailure>()),
    );
    expect(
      () => usecases.startPasswordReset(email: email, target: target),
      throwsA(isA<CloudAuthFailure>()),
    );
  });
}
