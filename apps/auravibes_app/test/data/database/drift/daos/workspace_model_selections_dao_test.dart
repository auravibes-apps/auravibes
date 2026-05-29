// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

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

void main() {
  group('WorkspaceModelSelectionsDao', () {
    late AppDatabase database;
    late String workspaceId;

    setUp(() async {
      database = AppDatabase(connection: createTestConnection());
      final ws = await database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      workspaceId = ws.id;
    });

    tearDown(() async {
      await database.close();
    });

    test('insertWorkspaceModelSelections inserts records', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await database.modelConnectionsDao.insertModelConnection(
        ServiceConnectionsCompanion.insert(
          name: 'Conn',
          serviceId: 'openai',
          kind: ServiceConnectionKindTable.modelProvider,
          authenticationType: ServiceAuthenticationTypeTable.apiKey,
          encryptedAuthValue: const Value('key'),
          workspaceId: workspaceId,
        ),
      );
      await database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
        [
          WorkspaceModelSelectionsCompanion.insert(
            modelId: 'openai',
            modelConnectionId: conn.id,
          ),
        ],
      );
      final results = await database.workspaceModelSelectionsDao
          .getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          );
      expect(results.length, equals(1));
    });

    test('watchAllWorkspaceModelSelectionsByWorkspace emits inserts', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await database.modelConnectionsDao.insertModelConnection(
        ServiceConnectionsCompanion.insert(
          name: 'Conn',
          serviceId: 'openai',
          kind: ServiceConnectionKindTable.modelProvider,
          authenticationType: ServiceAuthenticationTypeTable.apiKey,
          encryptedAuthValue: const Value('key'),
          workspaceId: workspaceId,
        ),
      );

      final stream = database.workspaceModelSelectionsDao
          .watchAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          );
      final iterator = StreamIterator(stream);
      addTearDown(iterator.cancel);

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isEmpty);

      await database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
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
        final results = await database.workspaceModelSelectionsDao
            .getAllWorkspaceModelSelectionsByWorkspace(
              workspaceIds: [workspaceId],
            );
        expect(results, isEmpty);
      },
    );

    test('getWorkspaceModelSelectionById returns selection', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final conn = await database.modelConnectionsDao.insertModelConnection(
        ServiceConnectionsCompanion.insert(
          name: 'Conn',
          serviceId: 'openai',
          kind: ServiceConnectionKindTable.modelProvider,
          authenticationType: ServiceAuthenticationTypeTable.apiKey,
          encryptedAuthValue: const Value('key'),
          workspaceId: workspaceId,
        ),
      );
      await database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
        [
          WorkspaceModelSelectionsCompanion.insert(
            modelId: 'openai',
            modelConnectionId: conn.id,
          ),
        ],
      );
      final all = await database.workspaceModelSelectionsDao
          .getAllWorkspaceModelSelectionsByWorkspace(
            workspaceIds: [workspaceId],
          );
      final found = await database.workspaceModelSelectionsDao
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
        final found = await database.workspaceModelSelectionsDao
            .getWorkspaceModelSelectionById('missing');
        expect(found, isNull);
      },
    );
  });
}
