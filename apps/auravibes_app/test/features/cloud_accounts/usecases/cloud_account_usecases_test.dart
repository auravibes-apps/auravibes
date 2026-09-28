import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthStore extends Mock implements ServerpodAuthStore;

class _MockWorkspaceRepository extends Mock implements WorkspaceRepository;

void main() {
  test('account removal disposes canonical account dependencies', () async {
    final store = _MockAuthStore();
    final repository = _MockWorkspaceRepository();
    String? invalidatedIdentity;
    when(
      () => repository.deleteCloudWorkspaceMirrorsForAccount(
        'account',
        serverUrl: 'https://server.example',
      ),
    ).thenAnswer((_) async => 1);
    when(
      () => store.removeAccount(
        serverUrl: 'https://server.example',
        userId: 'account',
      ),
    ).thenAnswer((_) => Future.value());
    final usecases = CloudAccountUseCases(
      store: store,
      workspaceRepository: repository,
      deleteRemoteAccount: ({required serverUrl, required userId}) =>
          Future<void>.value(),
      invalidateAccount: (serverUrl, userId) {
        invalidatedIdentity = CloudAccountIdentity.accountIdentity(
          serverUrl,
          userId,
        );
      },
    );

    await usecases.remove(
      serverUrl: 'https://server.example/api',
      userId: 'account',
    );

    expect(
      invalidatedIdentity,
      CloudAccountIdentity.accountIdentity('https://server.example', 'account'),
    );
    verify(
      () => store.removeAccount(
        serverUrl: 'https://server.example',
        userId: 'account',
      ),
    ).called(1);
  });

  test('local removal preserves login when mirror cleanup fails', () async {
    final store = _MockAuthStore();
    final repository = _MockWorkspaceRepository();
    when(
      () => repository.deleteCloudWorkspaceMirrorsForAccount(
        'account',
        serverUrl: 'https://server.example',
      ),
    ).thenThrow(StateError('Mirror cleanup failed'));
    final usecases = CloudAccountUseCases(
      store: store,
      workspaceRepository: repository,
      deleteRemoteAccount: ({required serverUrl, required userId}) =>
          Future<void>.value(),
      invalidateAccount: (serverUrl, userId) {},
    );

    await expectLater(
      usecases.remove(
        serverUrl: 'https://server.example/api',
        userId: 'account',
      ),
      throwsA(isA<StateError>()),
    );

    verifyNever(
      () => store.removeAccount(
        serverUrl: 'https://server.example',
        userId: 'account',
      ),
    );
  });

  test('account deletion clears login after mirror cleanup failure', () async {
    final store = _MockAuthStore();
    final repository = _MockWorkspaceRepository();
    var accountInvalidated = false;
    when(
      () => repository.deleteCloudWorkspaceMirrorsForAccount(
        'account',
        serverUrl: 'https://server.example',
      ),
    ).thenThrow(StateError('Mirror cleanup failed'));
    when(
      () => store.removeAccount(
        serverUrl: 'https://server.example',
        userId: 'account',
      ),
    ).thenAnswer((_) => Future.value());
    final usecases = CloudAccountUseCases(
      store: store,
      workspaceRepository: repository,
      deleteRemoteAccount: ({required serverUrl, required userId}) =>
          Future<void>.value(),
      invalidateAccount: (serverUrl, userId) {
        accountInvalidated = true;
      },
    );

    await expectLater(
      usecases.deleteAccount(
        serverUrl: 'https://server.example/api',
        userId: 'account',
      ),
      throwsA(
        isA<CloudAccountDeletionException>().having(
          (error) => error.localizationKey,
          'localizationKey',
          LocaleKeys.cloud_accounts_delete_local_cleanup_failed,
        ),
      ),
    );

    verify(
      () => store.removeAccount(
        serverUrl: 'https://server.example',
        userId: 'account',
      ),
    ).called(1);
    expect(accountInvalidated, isTrue);
  });
}
