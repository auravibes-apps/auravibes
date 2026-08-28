import 'dart:async';

import 'package:auravibes_app/features/models/data/cloud_model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../test_mocks.dart';

void main() {
  test('cloud model stores do not read local model repositories', () async {
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: const CloudWorkspaceRef(
        localWorkspaceId: 'local',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
      readState: (_) => throw StateError('unused'),
      subscribe: (_) => const Stream.empty(),
    );
    final container = ProviderContainer(
      overrides: [
        cloudWorkspaceStateGatewayForWorkspaceProvider.overrideWith(
          (_, _) async => gateway,
        ),
        modelConnectionRepositoryProvider.overrideWith(
          (_) => throw StateError('local model repository touched'),
        ),
        workspaceModelSelectionRepositoryProvider.overrideWith(
          (_) => throw StateError('local selection repository touched'),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(modelConnectionStoreProvider('local').future),
      isA<CloudModelStore>(),
    );
    expect(
      await container.read(modelSelectionStoreProvider('local').future),
      isA<CloudModelStore>(),
    );
  });

  test('local model store resolves after async gateway lookup', () async {
    final gateway = Completer<CloudWorkspaceStateGateway?>();
    final repository = MockWorkspaceModelSelectionRepository();
    final container = ProviderContainer(
      overrides: [
        cloudWorkspaceStateGatewayForWorkspaceProvider.overrideWith(
          (_, _) => gateway.future,
        ),
        workspaceModelSelectionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final store = container.read(modelSelectionStoreProvider('local').future);
    gateway.complete(null);
    expect(await store, isNot(isA<CloudModelStore>()));
  });

  test(
    'keeps pending model store resolution alive without listeners',
    () async {
      final gateway = Completer<CloudWorkspaceStateGateway?>();
      final container = ProviderContainer(
        overrides: [
          cloudWorkspaceStateGatewayForWorkspaceProvider.overrideWith(
            (_, _) => gateway.future,
          ),
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            MockWorkspaceModelSelectionRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final store = container.read(modelSelectionStoreProvider('local').future);
      await container.pump();
      gateway.complete(null);

      expect(await store, isNot(isA<CloudModelStore>()));
    },
  );
}
