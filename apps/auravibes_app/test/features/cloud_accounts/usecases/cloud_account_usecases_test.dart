import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthStore extends Mock implements ServerpodAuthStore {}

class _MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

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
      invalidateAccount: (serverUrl, userId) {
        invalidatedIdentity = accountIdentity(serverUrl, userId);
      },
    );

    await usecases.remove(
      serverUrl: 'https://server.example/api',
      userId: 'account',
    );

    expect(
      invalidatedIdentity,
      accountIdentity('https://server.example', 'account'),
    );
    verify(
      () => store.removeAccount(
        serverUrl: 'https://server.example',
        userId: 'account',
      ),
    ).called(1);
  });
}
