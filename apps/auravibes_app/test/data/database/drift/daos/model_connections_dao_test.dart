// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

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
  group('ModelConnectionsDao', () {
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

    test('insertModelConnection creates and returns connection', () async {
      final conn = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            ServiceConnectionsCompanion.insert(
              name: 'My Connection',
              serviceId: 'gpt-4',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('secret-key'),
              workspaceId: workspaceId,
            ),
          );
      expect(conn.name, equals('My Connection'));
      expect(conn.workspaceId, equals(workspaceId));
    });

    test('getModelConnectionById returns connection', () async {
      final created = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            ServiceConnectionsCompanion.insert(
              name: 'Conn',
              serviceId: 'gpt-4',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('key'),
              workspaceId: workspaceId,
            ),
          );
      final found = await fixture.database.modelConnectionsDao
          .getModelConnectionById(
            created.id,
          );
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).name,
        equals('Conn'),
      );
    });

    test('getModelConnectionById returns null for nonexistent', () async {
      final found = await fixture.database.modelConnectionsDao
          .getModelConnectionById(
            'missing',
          );
      expect(found, isNull);
    });

    test(
      'getModelConnectionById ignores non-model service connections',
      () async {
        final created = await fixture.database
            .into(fixture.database.serviceConnections)
            .insertReturning(
              ServiceConnectionsCompanion.insert(
                name: 'Custom API',
                serviceId: 'custom-api',
                kind: ServiceConnectionKindTable.customHttp,
                authenticationType: ServiceAuthenticationTypeTable.bearerToken,
                encryptedAuthValue: const Value('token'),
                workspaceId: workspaceId,
              ),
            );

        final found = await fixture.database.modelConnectionsDao
            .getModelConnectionById(
              created.id,
            );
        expect(found, isNull);
      },
    );

    test(
      'getAllModelConnectionsByWorkspace filters by workspace IDs',
      () async {
        final ws2 = await fixture.database.workspaceDao.insertWorkspace(
          WorkspacesCompanion.insert(name: 'WS2', type: WorkspaceType.local),
        );
        final _ = await fixture.database.modelConnectionsDao
            .insertModelConnection(
              ServiceConnectionsCompanion.insert(
                name: 'C1',
                serviceId: 'gpt-4',
                kind: ServiceConnectionKindTable.modelProvider,
                authenticationType: ServiceAuthenticationTypeTable.apiKey,
                encryptedAuthValue: const Value('k1'),
                workspaceId: workspaceId,
              ),
            );
        final _ = await fixture.database.modelConnectionsDao
            .insertModelConnection(
              ServiceConnectionsCompanion.insert(
                name: 'C2',
                serviceId: 'gpt-4',
                kind: ServiceConnectionKindTable.modelProvider,
                authenticationType: ServiceAuthenticationTypeTable.apiKey,
                encryptedAuthValue: const Value('k2'),
                workspaceId: ws2.id,
              ),
            );
        final conns = await fixture.database.modelConnectionsDao
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
        final ws2 = await fixture.database.workspaceDao.insertWorkspace(
          WorkspacesCompanion.insert(name: 'WS2', type: WorkspaceType.local),
        );
        final _ = await fixture.database.modelConnectionsDao
            .insertModelConnection(
              ServiceConnectionsCompanion.insert(
                name: 'C1',
                serviceId: 'gpt-4',
                kind: ServiceConnectionKindTable.modelProvider,
                authenticationType: ServiceAuthenticationTypeTable.apiKey,
                encryptedAuthValue: const Value('k1'),
                workspaceId: workspaceId,
              ),
            );
        final _ = await fixture.database.modelConnectionsDao
            .insertModelConnection(
              ServiceConnectionsCompanion.insert(
                name: 'C2',
                serviceId: 'gpt-4',
                kind: ServiceConnectionKindTable.modelProvider,
                authenticationType: ServiceAuthenticationTypeTable.apiKey,
                encryptedAuthValue: const Value('k2'),
                workspaceId: ws2.id,
              ),
            );
        final conns = await fixture.database.modelConnectionsDao
            .getAllModelConnectionsByWorkspace(
              workspaceIds: [workspaceId, ws2.id],
            );
        expect(conns.length, equals(2));
      },
    );

    test('deleteModelConnection removes connection', () async {
      final created = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            ServiceConnectionsCompanion.insert(
              name: 'C',
              serviceId: 'gpt-4',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('k'),
              workspaceId: workspaceId,
            ),
          );
      await fixture.database.modelConnectionsDao.deleteModelConnection(
        created.id,
      );
      expect(
        await fixture.database.modelConnectionsDao.getModelConnectionById(
          created.id,
        ),
        isNull,
      );
    });

    test(
      'deleteModelConnection ignores non-model service connections',
      () async {
        final created = await fixture.database
            .into(fixture.database.serviceConnections)
            .insertReturning(
              ServiceConnectionsCompanion.insert(
                name: 'Custom API',
                serviceId: 'custom-api',
                kind: ServiceConnectionKindTable.customHttp,
                authenticationType: ServiceAuthenticationTypeTable.bearerToken,
                encryptedAuthValue: const Value('token'),
                workspaceId: workspaceId,
              ),
            );

        await fixture.database.modelConnectionsDao.deleteModelConnection(
          created.id,
        );

        final remaining = await (fixture.database.select(
          fixture.database.serviceConnections,
        )..where((t) => t.id.equals(created.id))).getSingleOrNull();
        expect(remaining, isNotNull);
      },
    );
  });
}
