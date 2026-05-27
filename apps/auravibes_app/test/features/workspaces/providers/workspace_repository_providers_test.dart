// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

QueryExecutor _testConnection() {
  return DatabaseConnection.delayed(
    Future(
      () => DatabaseConnection(
        LazyDatabase(() async => NativeDatabase.memory()),
      ),
    ),
  );
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  @override
  Future<List<WorkspaceEntity>> getAllWorkspaces() async => [];

  @override
  Stream<List<WorkspaceEntity>> watchAllWorkspaces() async* {
    yield [];
  }

  @override
  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteWorkspace(String id) {
    throw UnimplementedError();
  }

  @override
  Future<int> getWorkspaceCount() {
    throw UnimplementedError();
  }

  @override
  Future<int> getWorkspaceCountByType(WorkspaceType type) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceEntity?> getWorkspaceById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<WorkspaceEntity>> getWorkspacesByType(WorkspaceType type) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceEntity> patchWorkspace(
    String id,
    WorkspacePatch workspace,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateWorkspace(WorkspaceToCreate workspace) {
    throw UnimplementedError();
  }

  @override
  Future<bool> workspaceExists(String id) {
    throw UnimplementedError();
  }

  @override
  Future<bool> patchWorkspaceTimestamp(String id) {
    throw UnimplementedError();
  }
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase testDatabase;
  late ProviderContainer container;

  setUp(() {
    testDatabase = AppDatabase(connection: _testConnection());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(testDatabase)],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDatabase.close();
  });

  group('workspaceRepositoryProvider', () {
    test('returns a WorkspaceRepository instance', () {
      final repo = container.read(workspaceRepositoryProvider);
      expect(repo, isA<WorkspaceRepository>());
    });
  });

  group('allWorkspacesProvider', () {
    test('emits list from repository', () async {
      final fakeRepo = _FakeWorkspaceRepository();
      final testContainer = ProviderContainer(
        overrides: [
          workspaceRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(testContainer.dispose);

      // Keep provider alive during async test
      final _ = testContainer.listen(allWorkspacesProvider, (_, _) {});

      final result = await testContainer.read(allWorkspacesProvider.future);
      expect(result, isEmpty);
    });

    test('returns same instance on subsequent reads (keepAlive)', () async {
      final fakeRepo = _FakeWorkspaceRepository();
      final testContainer = ProviderContainer(
        overrides: [
          workspaceRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(testContainer.dispose);

      // Keep provider alive during async test
      final _ = testContainer.listen(allWorkspacesProvider, (_, _) {});

      final first = await testContainer.read(allWorkspacesProvider.future);
      final second = await testContainer.read(allWorkspacesProvider.future);
      expect(identical(first, second), isTrue);
    });
  });
}
