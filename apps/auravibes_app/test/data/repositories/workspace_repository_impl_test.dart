import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_repository_impl.dart';
import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceRepositoryImpl', () {
    late AppDatabase database;
    late WorkspaceRepositoryImpl repository;

    setUp(() {
      // Create an in-memory database for testing
      database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      repository = WorkspaceRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should create and retrieve a workspace', () async {
      // Arrange
      const workspace = WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      );

      // Act
      final createResult = await repository.createWorkspace(workspace);
      final getResult = await repository.getWorkspaceById(createResult.id);

      // Assert
      expect(createResult.name, 'Test Workspace');
      expect(createResult.type, WorkspaceType.local);

      expect(getResult!.id, createResult.id);
      expect(getResult.name, 'Test Workspace');
    });

    test('should retrieve all workspaces', () async {
      // Arrange
      const workspace1 = WorkspaceToCreate(
        name: 'Test Workspace 1',
        type: WorkspaceType.local,
      );
      const workspace2 = WorkspaceToCreate(
        name: 'Test Workspace 2',
        type: WorkspaceType.remote,
        url: 'https://example.com',
      );

      // Act
      await repository.createWorkspace(workspace1);
      await repository.createWorkspace(workspace2);
      final result = await repository.getAllWorkspaces();

      // Assert
      expect(result.length, 2);
      expect(result[0].name, 'Test Workspace 1');
      expect(result[1].name, 'Test Workspace 2');
    });

    test('should update a workspace', () async {
      // Arrange
      const workspace = WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      );
      final createdWorkspace = await repository.createWorkspace(workspace);

      const updatedWorkspace = WorkspacePatch(name: 'Updated Workspace');

      // Act
      final result = await repository.patchWorkspace(
        createdWorkspace.id,
        updatedWorkspace,
      );

      // Assert
      expect(result.name, 'Updated Workspace');
    });

    test('should delete a workspace', () async {
      // Arrange
      const workspace = WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      );
      final cretadWorkspace = await repository.createWorkspace(workspace);

      // Act
      final deleteResult = await repository.deleteWorkspace(cretadWorkspace.id);
      final getResult = await repository.getWorkspaceById(cretadWorkspace.id);

      // Assert
      expect(deleteResult, true);

      expect(getResult, isNull);
    });

    test('should search workspaces by name', () async {
      // Arrange
      const workspace1 = WorkspaceToCreate(
        name: 'Development Workspace',
        type: WorkspaceType.local,
      );
      const workspace2 = WorkspaceToCreate(
        name: 'Production Workspace',
        type: WorkspaceType.remote,
        url: 'https://example.com',
      );

      await repository.createWorkspace(workspace1);
      await repository.createWorkspace(workspace2);

      // Act
      final result = await repository.searchWorkspacesByName('Development');

      // Assert
      expect(result.length, 1);
      expect(result[0].name, 'Development Workspace');
    });

    test('should handle invalid workspace creation', () async {
      // Arrange - Create invalid workspace (local with URL)
      const invalidWorkspace = WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
        url: 'https://example.com', // Local workspace shouldn't have URL
      );

      // Act
      await expectLater(
        repository.createWorkspace(invalidWorkspace),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });
  });
}
