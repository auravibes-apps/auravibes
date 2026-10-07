import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../database_test_utils.dart';

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

final class _DatabaseFixture(final QueryExecutor Function() createConnection) {
  AppDatabase? _database;

  AppDatabase get database =>
      _database ??= AppDatabase(connection: createConnection());

  Future<void> reset() => clearAppDatabase(database);

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('WorkspaceModelSelectionsDao', () {
    final fixture = _DatabaseFixture(createTestConnection);
    var workspaceId = '';

    setUp(() async {
      await fixture.reset();
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      workspaceId = ws.id;
    });

    tearDownAll(() async {
      await fixture.close();
    });

    test('insertWorkspaceModelSelections inserts records', () async {
      final _ = await fixture.database.apiModelProvidersDao.upsertProvider(
        .insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            .insert(
              name: 'Conn',
              serviceId: 'openai',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('key'),
              workspaceId: workspaceId,
            ),
          );
      await fixture.database.workspaceModelSelectionsDao
          .insertWorkspaceModelSelections([
            WorkspaceModelSelectionsCompanion.insert(
              modelId: 'openai',
              modelConnectionId: conn.id,
            ),
          ]);
      final results = await fixture.database.workspaceModelSelectionsDao
          .getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          );
      expect(results.length, equals(1));
    });

    test('watchAllWorkspaceModelSelectionsByWorkspace emits inserts', () async {
      final _ = await fixture.database.apiModelProvidersDao.upsertProvider(
        .insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            .insert(
              name: 'Conn',
              serviceId: 'openai',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('key'),
              workspaceId: workspaceId,
            ),
          );

      final stream = fixture.database.workspaceModelSelectionsDao
          .watchAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          );
      final iterator = StreamIterator(stream);
      addTearDown(iterator.cancel);

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isEmpty);

      await fixture.database.workspaceModelSelectionsDao
          .insertWorkspaceModelSelections([
            WorkspaceModelSelectionsCompanion.insert(
              modelId: 'openai',
              modelConnectionId: conn.id,
            ),
          ]);

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, hasLength(1));
    });

    test(
      'getAllWorkspaceModelSelectionsByWorkspace returns empty for no match',
      () async {
        final results = await fixture.database.workspaceModelSelectionsDao
            .getAllWorkspaceModelSelectionsByWorkspace(
              workspaceIds: [workspaceId],
            );
        expect(results, isEmpty);
      },
    );

    test('getWorkspaceModelSelectionById returns selection', () async {
      final _ = await fixture.database.apiModelProvidersDao.upsertProvider(
        .insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            .insert(
              name: 'Conn',
              serviceId: 'openai',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('key'),
              workspaceId: workspaceId,
            ),
          );
      await fixture.database.workspaceModelSelectionsDao
          .insertWorkspaceModelSelections([
            WorkspaceModelSelectionsCompanion.insert(
              modelId: 'openai',
              modelConnectionId: conn.id,
            ),
          ]);
      final all = await fixture.database.workspaceModelSelectionsDao
          .getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          );
      final found = await fixture.database.workspaceModelSelectionsDao
          .getWorkspaceModelSelectionById(
            (all.firstOrNull ?? fail('Expected all.firstOrNull to be non-null'))
                .model
                .id,
          );
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).model.modelId,
        equals('openai'),
      );
    });

    test(
      'persists each tool sampling policy and clears to legacy null',
      () async {
        final _ = await fixture.database.apiModelProvidersDao.upsertProvider(
          .insert(id: 'openai', name: 'OpenAI'),
        );
        final conn = await fixture.database.modelConnectionsDao
            .insertModelConnection(
              .insert(
                name: 'Conn',
                serviceId: 'openai',
                kind: ServiceConnectionKindTable.modelProvider,
                authenticationType: ServiceAuthenticationTypeTable.apiKey,
                encryptedAuthValue: const Value('key'),
                workspaceId: workspaceId,
              ),
            );
        await fixture.database.workspaceModelSelectionsDao
            .insertWorkspaceModelSelections([
              WorkspaceModelSelectionsCompanion.insert(
                modelId: 'gpt-4o',
                modelConnectionId: conn.id,
              ),
            ]);
        final selection =
            (await fixture.database.workspaceModelSelectionsDao
                    .getAllWorkspaceModelSelectionsByWorkspace(
                      workspaceIds: [workspaceId],
                    ))
                .single
                .model;

        for (final policy in ToolSamplingPolicy.values) {
          final updatedRows = await fixture.database.workspaceModelSelectionsDao
              .updateToolSamplingPolicy(selection.id, policy.name);
          expect(updatedRows, 1);
          final updated = await fixture.database.workspaceModelSelectionsDao
              .getWorkspaceModelSelectionById(selection.id);
          expect(updated?.model.toolSamplingPolicy, policy.name);
        }

        final clearedRows = await fixture.database.workspaceModelSelectionsDao
            .updateToolSamplingPolicy(selection.id, null);
        expect(clearedRows, 1);
        final cleared = await fixture.database.workspaceModelSelectionsDao
            .getWorkspaceModelSelectionById(selection.id);
        expect(cleared?.model.toolSamplingPolicy, isNull);
      },
    );

    test(
      'getWorkspaceModelSelectionById returns null for nonexistent',
      () async {
        final found = await fixture.database.workspaceModelSelectionsDao
            .getWorkspaceModelSelectionById('missing');
        expect(found, isNull);
      },
    );
  });
}
