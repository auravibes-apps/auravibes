// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

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
      final _ = await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Workspace 1',
          type: WorkspaceType.local,
        ),
      );

      final _ = await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Workspace 2',
          type: WorkspaceType.remote,
          url: const Value('https://example.com'),
        ),
      );

      // Get all workspaces
      final workspaces = await workspaceDao.getAllWorkspaces();

      expect(workspaces.length, equals(2));
      expect(workspaces.firstOrNull?.name, equals('Workspace 1'));
      expect(workspaces.firstOrNull?.type, equals(WorkspaceType.local));
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
      final updated = await workspaceDao.patchWorkspace(
        idCreated.id,
        WorkspacesCompanion(
          updatedAt: Value(DateTime.now()),
          name: const Value('Updated Name'),
        ),
      );

      expect(updated, isTrue);

      // Verify the update
      final retrieved = await workspaceDao.getWorkspaceById(idCreated.id);
      expect(
        (retrieved ?? fail('Expected retrieved to be non-null')).name,
        equals('Updated Name'),
      );
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
      final _ = await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Development Workspace',
          type: WorkspaceType.local,
        ),
      );

      final _ = await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Production Workspace',
          type: WorkspaceType.remote,
          url: const Value('https://prod.example.com'),
        ),
      );

      // Search for workspaces
      final results = await workspaceDao.searchWorkspacesByName('Development');

      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('Development Workspace'));
    });

    test('should get workspace count by type', () async {
      final workspaceDao = database.workspaceDao;

      // Insert test workspaces
      final _ = await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Local Workspace 1',
          type: WorkspaceType.local,
        ),
      );

      final _ = await workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Local Workspace 2',
          type: WorkspaceType.local,
        ),
      );

      final _ = await workspaceDao.insertWorkspace(
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
