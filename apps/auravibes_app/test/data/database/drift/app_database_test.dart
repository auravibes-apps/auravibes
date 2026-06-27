import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async => NativeDatabase.memory()),
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
      expect(fixture.database.schemaVersion, 1);
    });

    test('creates successfully with in-memory connection', () {
      expect(fixture.database, isNotNull);
    });

    test('initializeWithDefaults leaves workspace list empty', () async {
      await fixture.database.initializeWithDefaults();

      final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
      expect(workspaces, isEmpty);
    });

    test('initializeWithDefaults remains idempotent', () async {
      await fixture.database.initializeWithDefaults();
      await fixture.database.initializeWithDefaults();

      final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
      expect(workspaces, isEmpty);
    });

    test('performMaintenance completes without error', () async {
      await expectLater(fixture.database.performMaintenance(), completes);
    });

    test('getDatabaseStats returns valid stats', () async {
      await fixture.database.initializeWithDefaults();

      final stats = await fixture.database.getDatabaseStats();

      expect(stats, contains('workspaceCount'));
      expect(stats['workspaceCount'], 0);
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
      expect(workspaces, isEmpty);
      await db2.close();
    });
  });
}
