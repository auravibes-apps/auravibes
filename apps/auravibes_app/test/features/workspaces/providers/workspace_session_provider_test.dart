import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('remote workspace with malformed metadata fails closed', () async {
    final container = ProviderContainer(
      overrides: [
        allWorkspacesProvider.overrideWith(
          (ref) => Stream.value([_workspace(cloudWorkspaceId: 'bad')]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      workspaceSessionForRouteProvider('local'),
      (_, next) => expect(next, isNotNull),
    );
    addTearDown(subscription.close);

    await expectLater(
      container.read(workspaceSessionForRouteProvider('local').future),
      throwsStateError,
    );
  });

  test('session reacts to mirror identity changes and deletion', () async {
    final workspaces = StreamController<List<WorkspaceEntity>>();
    final container = ProviderContainer(
      overrides: [
        allWorkspacesProvider.overrideWith((ref) => workspaces.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await expectLater(workspaces.close(), completes);
    });
    final subscription = container.listen(
      workspaceSessionForRouteProvider('local'),
      (_, next) => expect(next, isNotNull),
    );
    addTearDown(subscription.close);

    workspaces.add([_workspace(cloudWorkspaceId: '1')]);
    final first = await container.read(
      workspaceSessionForRouteProvider('local').future,
    );
    expect(first.cloud?.cloudWorkspaceId, 1);

    workspaces.add([_workspace(cloudWorkspaceId: '2')]);
    await Future<void>.delayed(Duration.zero);
    final second = await container.read(
      workspaceSessionForRouteProvider('local').future,
    );
    expect(second.cloud?.cloudWorkspaceId, 2);

    workspaces.add([]);
    await Future<void>.delayed(Duration.zero);
    await expectLater(
      container.read(workspaceSessionForRouteProvider('local').future),
      throwsStateError,
    );
  });

  test('sessions preserve server, account, and workspace identity', () async {
    final container = ProviderContainer(
      overrides: [
        allWorkspacesProvider.overrideWith(
          (ref) => Stream.value([
            _workspace(
              cloudWorkspaceId: '11',
              id: 'mirror-a',
              serverUrl: 'https://one.example/api',
              accountId: 'shared-account',
            ),
            _workspace(
              cloudWorkspaceId: '22',
              id: 'mirror-b',
              serverUrl: 'https://two.example/',
              accountId: 'shared-account',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final firstProvider = workspaceSessionForRouteProvider('mirror-a');
    final secondProvider = workspaceSessionForRouteProvider('mirror-b');
    final firstSubscription = container.listen(firstProvider, (_, _) => 0);
    final secondSubscription = container.listen(secondProvider, (_, _) => 0);
    addTearDown(firstSubscription.close);
    addTearDown(secondSubscription.close);

    final first = await container.read(firstProvider.future);
    final second = await container.read(secondProvider.future);

    expect(first.cloud?.serverUrl, 'https://one.example');
    expect(first.cloud?.accountId, 'shared-account');
    expect(first.cloud?.cloudWorkspaceId, 11);
    expect(second.cloud?.serverUrl, 'https://two.example');
    expect(second.cloud?.accountId, 'shared-account');
    expect(second.cloud?.cloudWorkspaceId, 22);
  });
}

WorkspaceEntity _workspace({
  required String cloudWorkspaceId,
  String id = 'local',
  String serverUrl = 'https://server.example/api',
  String accountId = 'account',
}) {
  return WorkspaceEntity(
    id: id,
    name: 'Cloud',
    type: WorkspaceType.remote,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    url: serverUrl,
    cloudWorkspaceId: cloudWorkspaceId,
    cloudAccountId: accountId,
  );
}
