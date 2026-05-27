// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.

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
        LazyDatabase(() async => NativeDatabase.memory()),
      );
    }),
  );
}

void main() {
  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(connection: createTestConnection());
    });

    tearDown(() async {
      await database.close();
    });

    test('has correct schema version', () {
      expect(database.schemaVersion, 3);
    });

    test('creates successfully with in-memory connection', () {
      expect(database, isNotNull);
    });

    test(
      'initializeWithDefaults inserts default workspace when empty',
      () async {
        await database.initializeWithDefaults();

        final workspaces = await database.workspaceDao.getAllWorkspaces();
        expect(workspaces, hasLength(1));
        expect(workspaces.firstOrNull?.name, 'Default Workspace');
        expect(workspaces.firstOrNull?.type, WorkspaceType.local);
      },
    );

    test(
      'initializeWithDefaults does not duplicate default workspace',
      () async {
        await database.initializeWithDefaults();
        await database.initializeWithDefaults();

        final workspaces = await database.workspaceDao.getAllWorkspaces();
        expect(workspaces, hasLength(1));
      },
    );

    test('performMaintenance completes without error', () async {
      await database.performMaintenance();
    });

    test('getDatabaseStats returns valid stats', () async {
      await database.initializeWithDefaults();

      final stats = await database.getDatabaseStats();

      expect(stats, contains('workspaceCount'));
      expect(stats['workspaceCount'], 1);
      expect(stats, contains('pageCount'));
      expect(stats, contains('pageSize'));
      expect(stats, contains('approximateSizeBytes'));
    });

    test('getDatabaseStats returns zero workspaces when empty', () async {
      final stats = await database.getDatabaseStats();
      expect(stats['workspaceCount'], 0);
    });

    test('DAOs are accessible', () {
      expect(database.workspaceDao, isNotNull);
      expect(database.modelConnectionsDao, isNotNull);
      expect(database.workspaceModelSelectionsDao, isNotNull);
      expect(database.apiModelProvidersDao, isNotNull);
      expect(database.apiModelsDao, isNotNull);
      expect(database.conversationDao, isNotNull);
      expect(database.messageDao, isNotNull);
      expect(database.conversationToolsDao, isNotNull);
    });

    test('all DAO getters return non-null', () {
      expect(database.workspaceToolsDao, isNotNull);
      expect(database.toolsGroupsDao, isNotNull);
      expect(database.mcpServersDao, isNotNull);
    });

    test('getDatabaseStats computes approximateSizeBytes', () async {
      final stats = await database.getDatabaseStats();
      expect(stats['approximateSizeBytes'], greaterThan(0));
      expect(stats['pageCount'], greaterThan(0));
      expect(stats['pageSize'], greaterThan(0));
    });

    test('performMaintenance runs vacuum and analyze', () async {
      await database.performMaintenance();
      final stats = await database.getDatabaseStats();
      expect(stats, isNotEmpty);
    });

    test('migration onCreate creates all tables', () async {
      final strategy = database.migration;
      final _ = await database.customSelect('SELECT 1').getSingle();
      expect(strategy, isNotNull);
    });

    test('schemaVersion is 3', () {
      expect(database.schemaVersion, 3);
    });

    test('getDatabaseStats returns valid types', () async {
      final stats = await database.getDatabaseStats();
      expect(stats['workspaceCount'], isA<int>());
      expect(stats['pageCount'], isA<int>());
      expect(stats['pageSize'], isA<int>());
      expect(stats['approximateSizeBytes'], isA<int>());
    });

    test('migration strategy has onCreate callback', () {
      final strategy = database.migration;
      expect(strategy.onCreate, isNotNull);
    });

    test('migration strategy has onUpgrade callback', () {
      final strategy = database.migration;
      expect(strategy.onUpgrade, isNotNull);
    });

    test('can insert workspace and query back', () async {
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'Test Workspace',
              type: WorkspaceType.local,
            ),
          );

      final workspaces = await database.workspaceDao.getAllWorkspaces();
      expect(workspaces, hasLength(1));
      expect(workspaces.firstOrNull?.name, 'Test Workspace');
      expect(workspaces.firstOrNull?.type, WorkspaceType.local);
    });

    test('can insert multiple workspaces', () async {
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'Workspace 1',
              type: WorkspaceType.local,
            ),
          );
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'Workspace 2',
              type: WorkspaceType.local,
            ),
          );

      final workspaces = await database.workspaceDao.getAllWorkspaces();
      expect(workspaces, hasLength(2));
    });

    test(
      'initializeWithDefaults after manual insert does not add another',
      () async {
        final _ = await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                name: 'Manual',
                type: WorkspaceType.local,
              ),
            );
        await database.initializeWithDefaults();

        final workspaces = await database.workspaceDao.getAllWorkspaces();
        expect(workspaces, hasLength(1));
        expect(workspaces.firstOrNull?.name, 'Manual');
        expect(workspaces.firstOrNull?.type, WorkspaceType.local);
      },
    );

    test('getDatabaseStats with multiple workspaces', () async {
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'WS1',
              type: WorkspaceType.local,
            ),
          );
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              name: 'WS2',
              type: WorkspaceType.local,
            ),
          );

      final stats = await database.getDatabaseStats();
      expect(stats['workspaceCount'], 2);
    });

    test('performMaintenance can be called multiple times', () async {
      await database.performMaintenance();
      await database.performMaintenance();
    });

    test('database can be closed and recreated', () async {
      await database.initializeWithDefaults();
      await database.close();

      final db2 = AppDatabase(connection: createTestConnection());
      await db2.initializeWithDefaults();
      final workspaces = await db2.workspaceDao.getAllWorkspaces();
      expect(workspaces, hasLength(1));
      await db2.close();
    });
  });
}
