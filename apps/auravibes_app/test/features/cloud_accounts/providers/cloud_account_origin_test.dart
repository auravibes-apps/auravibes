import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/resolve_cloud_account_usecase.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const one = CloudAccountSession(
    serverUrl: 'https://one.example/api',
    userId: 'same',
    email: 'one@example.test',
  );
  const two = CloudAccountSession(
    serverUrl: 'https://two.example/',
    userId: 'same',
    email: 'two@example.test',
  );
  test('legacy account URLs resolve a unique stored origin', () {
    expect(
      ResolveCloudAccountUsecase.call((
        accountId: 'same',
        accounts: [one],
        mirrors: const [],
        workspaceId: -1,
        serverUrl: null,
      )).serverUrl,
      'https://one.example',
    );
  });
  test('legacy URLs reject shared account IDs instead of picking a server', () {
    expect(
      () => ResolveCloudAccountUsecase.call((
        accountId: 'same',
        accounts: [one, two],
        mirrors: const [],
        workspaceId: -1,
        serverUrl: null,
      )),
      throwsA(isA<AppCloudWorkspaceException>()),
    );
  });
  test('explicit origin resolves ambiguity and rejects unknown origins', () {
    expect(
      ResolveCloudAccountUsecase.call((
        accountId: 'same',
        accounts: [one, two],
        mirrors: const [],
        workspaceId: -1,
        serverUrl: 'https://two.example/path',
      )).serverUrl,
      'https://two.example',
    );
    expect(
      () => ResolveCloudAccountUsecase.call((
        accountId: 'same',
        accounts: [one, two],
        mirrors: const [],
        workspaceId: -1,
        serverUrl: 'https://other.example',
      )),
      throwsA(isA<AppCloudWorkspaceException>()),
    );
  });
  test(
    'legacy mirror retains origin when the account store is unavailable',
    () {
      final mirror = WorkspaceEntity(
        id: 'mirror',
        name: 'Cloud',
        type: .remote,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        url: 'https://one.example/api',
        cloudWorkspaceId: '11',
        cloudAccountId: 'same',
      );
      expect(
        ResolveCloudAccountUsecase.call((
          accountId: 'same',
          accounts: const [],
          mirrors: [mirror],
          workspaceId: 11,
          serverUrl: null,
        )).serverUrl,
        'https://one.example',
      );
    },
  );
}
