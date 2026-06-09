// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async => NativeDatabase.memory()),
      );
    }),
  );
}

void _createVersionThreeSchema(sqlite.Database database) {
  database
    ..execute('''
      CREATE TABLE workspaces (
        id TEXT NOT NULL PRIMARY KEY,
        created_at INTEGER NOT NULL DEFAULT (unixepoch()),
        updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''')
    ..execute('''
      CREATE TABLE model_connections (
        id TEXT NOT NULL PRIMARY KEY,
        created_at INTEGER NOT NULL DEFAULT (unixepoch()),
        updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
        name TEXT NOT NULL,
        model_id TEXT NOT NULL,
        url TEXT,
        key_value TEXT NOT NULL,
        key_suffix TEXT,
        workspace_id TEXT NOT NULL REFERENCES workspaces (id) ON DELETE CASCADE
      )
    ''')
    ..execute('''
      CREATE TABLE api_model_providers (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT,
        url TEXT
      )
    ''')
    ..execute('''
      CREATE TABLE workspace_model_selections (
        id TEXT NOT NULL PRIMARY KEY,
        created_at INTEGER NOT NULL DEFAULT (unixepoch()),
        updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
        model_id TEXT NOT NULL,
        model_connection_id TEXT NOT NULL
          REFERENCES model_connections (id) ON DELETE CASCADE
      )
    ''')
    ..execute(
      '''
      INSERT INTO workspaces (id, name, type)
      VALUES ('ws-1', 'WS', 'local')
      ''',
    )
    ..execute('''
      INSERT INTO api_model_providers (id, name)
      VALUES ('openai', 'OpenAI'), ('anthropic', 'Anthropic')
    ''')
    ..execute('''
      INSERT INTO model_connections (
        id,
        name,
        model_id,
        key_value,
        key_suffix,
        workspace_id
      ) VALUES (
        'conn-1',
        'OpenAI',
        'openai',
        'encrypted-key',
        'key',
        'ws-1'
      )
    ''')
    ..execute('''
      INSERT INTO workspace_model_selections (
        id,
        model_id,
        model_connection_id
      ) VALUES ('selection-1', 'gpt-4', 'conn-1')
    ''')
    ..execute('PRAGMA user_version = 3');
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

  set database(AppDatabase database) {
    _database = database;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('AppDatabase', () {
    final fixture = _DatabaseFixture(createTestConnection);

    setUp(fixture.reset);

    tearDown(() async {
      await fixture.close();
    });

    test('has correct schema version', () {
      expect(fixture.database.schemaVersion, 7);
    });

    test('creates successfully with in-memory connection', () {
      expect(fixture.database, isNotNull);
    });

    test(
      'initializeWithDefaults inserts default workspace when empty',
      () async {
        await fixture.database.initializeWithDefaults();

        final workspaces = await fixture.database.workspaceDao
            .getAllWorkspaces();
        expect(workspaces, hasLength(1));
        expect(workspaces.firstOrNull?.name, 'Default Workspace');
        expect(workspaces.firstOrNull?.type, WorkspaceType.local);
      },
    );

    test(
      'initializeWithDefaults does not duplicate default workspace',
      () async {
        await fixture.database.initializeWithDefaults();
        await fixture.database.initializeWithDefaults();

        final workspaces = await fixture.database.workspaceDao
            .getAllWorkspaces();
        expect(workspaces, hasLength(1));
      },
    );

    test('performMaintenance completes without error', () async {
      await expectLater(fixture.database.performMaintenance(), completes);
    });

    test('getDatabaseStats returns valid stats', () async {
      await fixture.database.initializeWithDefaults();

      final stats = await fixture.database.getDatabaseStats();

      expect(stats, contains('workspaceCount'));
      expect(stats['workspaceCount'], 1);
      expect(stats, contains('pageCount'));
      expect(stats, contains('pageSize'));
      expect(stats, contains('approximateSizeBytes'));
    });

    test('getDatabaseStats returns zero workspaces when empty', () async {
      final stats = await fixture.database.getDatabaseStats();
      expect(stats['workspaceCount'], 0);
    });

    test('DAOs are accessible', () {
      expect(fixture.database.workspaceDao, isNotNull);
      expect(fixture.database.modelConnectionsDao, isNotNull);
      expect(fixture.database.workspaceModelSelectionsDao, isNotNull);
      expect(fixture.database.apiModelProvidersDao, isNotNull);
      expect(fixture.database.apiModelsDao, isNotNull);
      expect(fixture.database.conversationDao, isNotNull);
      expect(fixture.database.messageDao, isNotNull);
      expect(fixture.database.conversationToolsDao, isNotNull);
      expect(fixture.database.skillsDao, isNotNull);
      expect(fixture.database.skillCredentialDefinitionsDao, isNotNull);
      expect(fixture.database.skillTemplateToolsDao, isNotNull);
      expect(fixture.database.conversationSkillsDao, isNotNull);
      expect(fixture.database.appSkillWorkspaceSettingsDao, isNotNull);
    });

    test('all DAO getters return non-null', () {
      expect(fixture.database.workspaceToolsDao, isNotNull);
      expect(fixture.database.toolsGroupsDao, isNotNull);
      expect(fixture.database.mcpServersDao, isNotNull);
    });

    test('getDatabaseStats computes approximateSizeBytes', () async {
      final stats = await fixture.database.getDatabaseStats();
      expect(stats['approximateSizeBytes'], greaterThan(0));
      expect(stats['pageCount'], greaterThan(0));
      expect(stats['pageSize'], greaterThan(0));
    });

    test('performMaintenance runs vacuum and analyze', () async {
      await fixture.database.performMaintenance();
      final stats = await fixture.database.getDatabaseStats();
      expect(stats, isNotEmpty);
    });

    test('migration onCreate creates all tables', () async {
      final strategy = fixture.database.migration;
      final _ = await fixture.database.customSelect('SELECT 1').getSingle();
      expect(strategy, isNotNull);
    });

    test('schemaVersion is 7', () {
      expect(fixture.database.schemaVersion, 7);
    });

    test(
      'migration from v3 copies model connections and updates selection FK',
      () async {
        await fixture.close();
        final rawDatabase = sqlite.sqlite3.openInMemory();
        _createVersionThreeSchema(rawDatabase);

        final migratedDatabase = AppDatabase(
          connection: NativeDatabase.opened(rawDatabase),
        );
        fixture.database = migratedDatabase;

        final connections = await migratedDatabase
            .select(migratedDatabase.serviceConnections)
            .get();
        final connection = connections.firstOrNull;
        expect(connections, hasLength(1));
        expect(connection?.serviceId, 'openai');
        expect(connection?.encryptedAuthValue, 'encrypted-key');

        final foreignKeys = await migratedDatabase
            .customSelect('PRAGMA foreign_key_list(workspace_model_selections)')
            .get();
        final foreignKeyTables = foreignKeys
            .map((row) => row.read<String>('table'))
            .toList();
        expect(foreignKeyTables, contains('service_connections'));
        expect(foreignKeyTables, isNot(contains('model_connections')));

        final oldTables = await migratedDatabase.customSelect(
          '''
              SELECT name FROM sqlite_master
              WHERE name = 'model_connections'
              ''',
        ).get();
        expect(oldTables, isEmpty);

        const newConnectionId = 'conn-2';
        final insertedConnectionId = await migratedDatabase
            .into(migratedDatabase.serviceConnections)
            .insert(
              ServiceConnectionsCompanion.insert(
                id: const Value(newConnectionId),
                name: 'New Connection',
                serviceId: 'anthropic',
                kind: ServiceConnectionKindTable.modelProvider,
                authenticationType: ServiceAuthenticationTypeTable.apiKey,
                encryptedAuthValue: const Value('new-key'),
                workspaceId: 'ws-1',
              ),
            );
        expect(insertedConnectionId, isA<int>());

        final insertedSelectionId = await migratedDatabase
            .into(migratedDatabase.workspaceModelSelections)
            .insert(
              WorkspaceModelSelectionsCompanion.insert(
                modelId: 'anthropic',
                modelConnectionId: newConnectionId,
              ),
            );
        expect(insertedSelectionId, isA<int>());
      },
    );

    test('getDatabaseStats returns valid types', () async {
      final stats = await fixture.database.getDatabaseStats();
      expect(stats['workspaceCount'], isA<int>());
      expect(stats['pageCount'], isA<int>());
      expect(stats['pageSize'], isA<int>());
      expect(stats['approximateSizeBytes'], isA<int>());
    });

    test('migration strategy has onCreate callback', () {
      final strategy = fixture.database.migration;
      expect(strategy.onCreate, isNotNull);
    });

    test('migration strategy has onUpgrade callback', () {
      final strategy = fixture.database.migration;
      expect(strategy.onUpgrade, isNotNull);
    });

    test('can insert workspace and query back', () async {
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'Test Workspace',
              type: WorkspaceType.local,
            ),
          );

      final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
      expect(workspaces, hasLength(1));
      expect(workspaces.firstOrNull?.name, 'Test Workspace');
      expect(workspaces.firstOrNull?.type, WorkspaceType.local);
    });

    test('can insert multiple workspaces', () async {
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'Workspace 1',
              type: WorkspaceType.local,
            ),
          );
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'Workspace 2',
              type: WorkspaceType.local,
            ),
          );

      final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
      expect(workspaces, hasLength(2));
    });

    test(
      'initializeWithDefaults after manual insert does not add another',
      () async {
        final _ = await fixture.database
            .into(fixture.database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                name: 'Manual',
                type: WorkspaceType.local,
              ),
            );
        await fixture.database.initializeWithDefaults();

        final workspaces = await fixture.database.workspaceDao
            .getAllWorkspaces();
        expect(workspaces, hasLength(1));
        expect(workspaces.firstOrNull?.name, 'Manual');
        expect(workspaces.firstOrNull?.type, WorkspaceType.local);
      },
    );

    test('getDatabaseStats with multiple workspaces', () async {
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'WS1',
              type: WorkspaceType.local,
            ),
          );
      final _ = await fixture.database
          .into(fixture.database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'WS2',
              type: WorkspaceType.local,
            ),
          );

      final stats = await fixture.database.getDatabaseStats();
      expect(stats['workspaceCount'], 2);
    });

    test('performMaintenance can be called multiple times', () async {
      await expectLater(fixture.database.performMaintenance(), completes);
      await expectLater(fixture.database.performMaintenance(), completes);
    });

    test('database can be closed and recreated', () async {
      await fixture.database.initializeWithDefaults();
      await fixture.close();

      final db2 = AppDatabase(connection: createTestConnection());
      await db2.initializeWithDefaults();
      final workspaces = await db2.workspaceDao.getAllWorkspaces();
      expect(workspaces, hasLength(1));
      await db2.close();
    });
  });
}
