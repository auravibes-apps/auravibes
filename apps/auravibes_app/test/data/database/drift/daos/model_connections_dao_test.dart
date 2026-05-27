// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/data/database/drift/app_database.dart';
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
  group('ModelConnectionsDao', () {
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

    test('insertModelConnection creates and returns connection', () async {
      final conn = await database.modelConnectionsDao.insertModelConnection(
        ModelConnectionsCompanion.insert(
          name: 'My Connection',
          modelId: 'gpt-4',
          keyValue: 'secret-key',
          workspaceId: workspaceId,
        ),
      );
      expect(conn.name, equals('My Connection'));
      expect(conn.workspaceId, equals(workspaceId));
    });

    test('getModelConnectionById returns connection', () async {
      final created = await database.modelConnectionsDao.insertModelConnection(
        ModelConnectionsCompanion.insert(
          name: 'Conn',
          modelId: 'gpt-4',
          keyValue: 'key',
          workspaceId: workspaceId,
        ),
      );
      final found = await database.modelConnectionsDao.getModelConnectionById(
        created.id,
      );
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).name,
        equals('Conn'),
      );
    });

    test('getModelConnectionById returns null for nonexistent', () async {
      final found = await database.modelConnectionsDao.getModelConnectionById(
        'missing',
      );
      expect(found, isNull);
    });

    test(
      'getAllModelConnectionsByWorkspace filters by workspace IDs',
      () async {
        final ws2 = await database.workspaceDao.insertWorkspace(
          WorkspacesCompanion.insert(name: 'WS2', type: WorkspaceType.local),
        );
        final _ = await database.modelConnectionsDao.insertModelConnection(
          ModelConnectionsCompanion.insert(
            name: 'C1',
            modelId: 'gpt-4',
            keyValue: 'k1',
            workspaceId: workspaceId,
          ),
        );
        final _ = await database.modelConnectionsDao.insertModelConnection(
          ModelConnectionsCompanion.insert(
            name: 'C2',
            modelId: 'gpt-4',
            keyValue: 'k2',
            workspaceId: ws2.id,
          ),
        );
        final conns = await database.modelConnectionsDao
            .getAllModelConnectionsByWorkspace(
              workspaceIds: [workspaceId],
            );
        expect(conns.length, equals(1));
        expect(conns.firstOrNull?.name, equals('C1'));
      },
    );

    test(
      'getAllModelConnectionsByWorkspace returns multiple for multiple IDs',
      () async {
        final ws2 = await database.workspaceDao.insertWorkspace(
          WorkspacesCompanion.insert(name: 'WS2', type: WorkspaceType.local),
        );
        final _ = await database.modelConnectionsDao.insertModelConnection(
          ModelConnectionsCompanion.insert(
            name: 'C1',
            modelId: 'gpt-4',
            keyValue: 'k1',
            workspaceId: workspaceId,
          ),
        );
        final _ = await database.modelConnectionsDao.insertModelConnection(
          ModelConnectionsCompanion.insert(
            name: 'C2',
            modelId: 'gpt-4',
            keyValue: 'k2',
            workspaceId: ws2.id,
          ),
        );
        final conns = await database.modelConnectionsDao
            .getAllModelConnectionsByWorkspace(
              workspaceIds: [workspaceId, ws2.id],
            );
        expect(conns.length, equals(2));
      },
    );

    test('deleteModelConnection removes connection', () async {
      final created = await database.modelConnectionsDao.insertModelConnection(
        ModelConnectionsCompanion.insert(
          name: 'C',
          modelId: 'gpt-4',
          keyValue: 'k',
          workspaceId: workspaceId,
        ),
      );
      await database.modelConnectionsDao.deleteModelConnection(created.id);
      expect(
        await database.modelConnectionsDao.getModelConnectionById(created.id),
        isNull,
      );
    });
  });
}
