import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements WorkspaceRepository;
class _Client extends Mock implements Client;

void main() {
  for (final sameOrigin in [true, false]) {
    test(
      'attach preserves account ownership, sameOrigin=$sameOrigin',
      () async {
        final repository = _Repository();
        final client = _Client();
        final original = _mirror('A', 'https://one.example/api');
        final targetOrigin = sameOrigin
            ? 'https://one.example'
            : 'https://two.example';
        final created = _mirror('B', targetOrigin);
        when(repository.getAllWorkspaces).thenAnswer((_) async => [original]);
        when(
          () => repository.upsertCloudWorkspaceMirror(
            cloudWorkspaceId: '11',
            cloudAccountId: 'B',
            name: 'Cloud',
            serverUrl: targetOrigin,
          ),
        ).thenAnswer((_) async => created);
        final usecase = CloudWorkspaceUseCases(
          cloudRepository: .new(client),
          workspaceRepository: repository,
          cloudAccountId: 'B',
          serverUrl: targetOrigin,
        );
        final result = await usecase.attach(_summary());
        expect(result.id, sameOrigin ? original.id : created.id);
        expect(result.cloudAccountId, sameOrigin ? 'A' : 'B');
        if (sameOrigin) {
          final _ = verifyNever(
            () => repository.upsertCloudWorkspaceMirror(
              cloudWorkspaceId: '11',
              cloudAccountId: 'B',
              name: 'Cloud',
              serverUrl: targetOrigin,
            ),
          );
        } else {
          verify(
            () => repository.upsertCloudWorkspaceMirror(
              cloudWorkspaceId: '11',
              cloudAccountId: 'B',
              name: 'Cloud',
              serverUrl: targetOrigin,
            ),
          ).called(1);
        }
        final _ = verifyNever(() => client.cloudWorkspace);
      },
    );
  }
  test('preexisting mirrors are not removed or rebound', () async {
    final repository = _Repository();
    final client = _Client();
    final mirrors = [
      _mirror('A', 'https://one.example'),
      _mirror('B', 'https://one.example'),
    ];
    when(repository.getAllWorkspaces).thenAnswer((_) async => mirrors);
    final usecase = CloudWorkspaceUseCases(
      cloudRepository: .new(client),
      workspaceRepository: repository,
      cloudAccountId: 'B',
      serverUrl: 'https://one.example',
    );
    expect((await usecase.attach(_summary())).id, 'mirror-B');
    expect(mirrors.map((mirror) => mirror.cloudAccountId), ['A', 'B']);
    verify(repository.getAllWorkspaces).called(1);
    verifyNoMoreInteractions(repository);
  });
}

WorkspaceEntity _mirror(String account, String origin) => WorkspaceEntity(
  id: 'mirror-$account',
  name: 'Cloud',
  type: .remote,
  createdAt: .new(2026),
  updatedAt: .new(2026),
  url: origin,
  cloudWorkspaceId: '11',
  cloudAccountId: account,
);
CloudWorkspaceSummary _summary() => CloudWorkspaceSummary(
  id: 11,
  name: 'Cloud',
  role: 'admin',
  revision: 8,
  sequence: 1,
  createdAt: .new(2026),
  updatedAt: .new(2026),
);
