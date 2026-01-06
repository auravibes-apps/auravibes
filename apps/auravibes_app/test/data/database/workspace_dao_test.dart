import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a database connection for testing.
///
/// This method creates an in-memory database suitable for unit tests.
/// The database is isolated and doesn't persist data between test runs.
QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          // Use an in-memory database for testing
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

void main() {
  group('WorkspaceDao Tests', () {
    late AppDatabase database;

    setUp(() async {
      // Use in-memory database for testing
      database = AppDatabase(connection: createTestConnection());
    });

    tearDown(() async {
      await database.close();
    });

    test('should insert and retrieve workspace', () async {
      final workspaceDao = database.workspaceDao;

      final workspace = WorkspacesCompanion.insert(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      );

      // Insert the workspace
      final retrieved = await workspaceDao.insertWorkspace(workspace);

      expect(retrieved, isNotNull);
      expect(retrieved.name, equals('Test Workspace'));
      expect(retrieved.type, equals(WorkspaceType.local));
      expect(retrieved.url, isNull);
    });

    test('should get all workspaces', () async {
      final workspaceDao = database.workspaceDao;

      // Insert test workspaces
      await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Workspace 1',
          type: WorkspaceType.local,
        ),
      );

      await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Workspace 2',
          type: WorkspaceType.remote,
          url: const Value('https://example.com'),
        ),
      );

      // Get all workspaces
      final workspaces = await workspaceDao.getAllWorkspaces();

      expect(workspaces.length, equals(2));
      expect(workspaces[0].name, equals('Workspace 1'));
      expect(workspaces[1].name, equals('Workspace 2'));
    });

    test('should update workspace', () async {
      final workspaceDao = database.workspaceDao;

      // Insert a workspace
      final idCreated = await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Original Name',
          type: WorkspaceType.local,
        ),
      );

      // Update the workspace
      final updated = await workspaceDao.updateWorkspace(
        idCreated.id,
        WorkspacesCompanion(
          name: const Value('Updated Name'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      expect(updated, isTrue);

      // Verify the update
      final retrieved = await workspaceDao.getWorkspaceById(idCreated.id);
      expect(retrieved!.name, equals('Updated Name'));
    });

    test('should delete workspace', () async {
      final workspaceDao = database.workspaceDao;

      // Insert a workspace
      final createdId = await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );

      // Delete the workspace
      final deleted = await workspaceDao.deleteWorkspace(createdId.id);
      expect(deleted, isTrue);

      // Verify deletion
      final retrieved = await workspaceDao.getWorkspaceById(createdId.id);
      expect(retrieved, isNull);
    });

    test('should search workspaces by name', () async {
      final workspaceDao = database.workspaceDao;

      // Insert test workspaces
      await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Development Workspace',
          type: WorkspaceType.local,
        ),
      );

      await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Production Workspace',
          type: WorkspaceType.remote,
          url: const Value('https://prod.example.com'),
        ),
      );

      // Search for workspaces
      final results = await workspaceDao.searchWorkspacesByName('Development');

      expect(results.length, equals(1));
      expect(results[0].name, equals('Development Workspace'));
    });

    test('should get workspace count by type', () async {
      final workspaceDao = database.workspaceDao;

      // Insert test workspaces
      await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Local Workspace 1',
          type: WorkspaceType.local,
        ),
      );

      await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Local Workspace 2',
          type: WorkspaceType.local,
        ),
      );

      await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Remote Workspace 1',
          type: WorkspaceType.remote,
          url: const Value('https://example.com'),
        ),
      );

      // Get counts by type
      final localCount = await workspaceDao.getWorkspaceCountByType(
        WorkspaceType.local,
      );
      final remoteCount = await workspaceDao.getWorkspaceCountByType(
        WorkspaceType.remote,
      );

      expect(localCount, equals(2));
      expect(remoteCount, equals(1));
    });
  });
}
