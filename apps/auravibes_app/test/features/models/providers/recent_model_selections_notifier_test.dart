import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/providers/recent_model_selections_notifier.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

AppDatabase _newDatabase() =>
    AppDatabase(connection: DatabaseConnection(NativeDatabase.memory()));

void main() {
  test(
    'restores recent selections in order, without duplicates, capped at five',
    () async {
      final database = _newDatabase();
      addTearDown(database.close);
      for (final selectionId in [
        'sel-1',
        'sel-2',
        'sel-3',
        'sel-4',
        'sel-5',
        'sel-6',
      ]) {
        await database.recentModelSelectionsDao.recordSelection(
          'ws-1',
          selectionId,
        );
      }
      await database.recentModelSelectionsDao.recordSelection('ws-1', 'sel-3');

      final container = ProviderContainer(
        overrides: [
          cloudModelGatewayForWorkspaceProvider.overrideWith(
            (_, _) async => null,
          ),
          appDatabaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(recentModelSelectionsProvider('ws-1').future),
        ['sel-3', 'sel-6', 'sel-5', 'sel-4', 'sel-2'],
      );
    },
  );

  test('record persists the capped history in the database', () async {
    final database = _newDatabase();
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [
        cloudModelGatewayForWorkspaceProvider.overrideWith(
          (_, _) async => null,
        ),
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      recentModelSelectionsProvider('ws-1').notifier,
    );

    for (final selectionId in ['sel-1', 'sel-2', 'sel-3', 'sel-4', 'sel-5']) {
      await notifier.record(selectionId);
    }
    await notifier.record('sel-3');
    await notifier.record('sel-6');

    expect(await database.recentModelSelectionsDao.getSelectionIds('ws-1'), [
      'sel-6',
      'sel-3',
      'sel-5',
      'sel-4',
      'sel-2',
    ]);

    final restoredContainer = ProviderContainer(
      overrides: [
        cloudModelGatewayForWorkspaceProvider.overrideWith(
          (_, _) async => null,
        ),
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(restoredContainer.dispose);
    expect(
      await restoredContainer.read(
        recentModelSelectionsProvider('ws-1').future,
      ),
      ['sel-6', 'sel-3', 'sel-5', 'sel-4', 'sel-2'],
    );
  });

  test('uses cloud storage for cloud workspaces', () async {
    String? recorded;
    final cloud = CloudModelGateway.forTesting(
      stateGateway: .forTesting(
        workspace: const .new(
          localWorkspaceId: 'ws-1',
          serverUrl: 'https://example.com',
          accountId: 'account',
          cloudWorkspaceId: 1,
        ),
        readState: (_) => throw UnimplementedError(),
        subscribe: (_) => const Stream.empty(),
      ),
      listRecentSelections: (_) => Future.value(['cloud-1']),
      recordRecentSelection: (request) {
        recorded = request.selectionId;

        return Future.value();
      },
    );
    final container = ProviderContainer(
      overrides: [
        cloudModelGatewayForWorkspaceProvider.overrideWith(
          (_, _) async => cloud,
        ),
        appDatabaseProvider.overrideWith(
          (_) => throw StateError('local database touched'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final provider = recentModelSelectionsProvider('ws-1');
    expect(await container.read(provider.future), ['cloud-1']);

    await container.read(provider.notifier).record('cloud-2');

    expect(recorded, 'cloud-2');
  });
}
