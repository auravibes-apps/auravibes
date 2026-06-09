import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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

final class _DatabaseFixture {
  _DatabaseFixture(this.createConnection);

  final QueryExecutor Function() createConnection;
  AppDatabase? _database;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  void reset() {
    _database = AppDatabase(connection: createConnection());
  }

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
      fixture.reset();
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      workspaceId = ws.id;
    });

    tearDown(() async {
      await fixture.close();
    });

    test('insertWorkspaceModelSelections inserts records', () async {
      final _ = await fixture.database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            ServiceConnectionsCompanion.insert(
              name: 'Conn',
              serviceId: 'openai',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('key'),
              workspaceId: workspaceId,
            ),
          );
      await fixture.database.workspaceModelSelectionsDao
          .insertWorkspaceModelSelections(
            [
              WorkspaceModelSelectionsCompanion.insert(
                modelId: 'openai',
                modelConnectionId: conn.id,
              ),
            ],
          );
      final results = await fixture.database.workspaceModelSelectionsDao
          .getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          );
      expect(results.length, equals(1));
    });

    test('watchAllWorkspaceModelSelectionsByWorkspace emits inserts', () async {
      final _ = await fixture.database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            ServiceConnectionsCompanion.insert(
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
          .insertWorkspaceModelSelections(
            [
              WorkspaceModelSelectionsCompanion.insert(
                modelId: 'openai',
                modelConnectionId: conn.id,
              ),
            ],
          );

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
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            ServiceConnectionsCompanion.insert(
              name: 'Conn',
              serviceId: 'openai',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('key'),
              workspaceId: workspaceId,
            ),
          );
      await fixture.database.workspaceModelSelectionsDao
          .insertWorkspaceModelSelections(
            [
              WorkspaceModelSelectionsCompanion.insert(
                modelId: 'openai',
                modelConnectionId: conn.id,
              ),
            ],
          );
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
      'getWorkspaceModelSelectionById returns null for nonexistent',
      () async {
        final found = await fixture.database.workspaceModelSelectionsDao
            .getWorkspaceModelSelectionById('missing');
        expect(found, isNull);
      },
    );
  });
}
