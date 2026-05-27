// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

// ignore_for_file: cascade_invocations
// Required: test expectations use chaining on matchers
// (e.g. find.text().findsOneWidget) which triggers cascade_invocations lint.
// Not applicable in test assertions.

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/workspaces/models/management_mode.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/features/workspaces/usecases/usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<WorkspaceEntity> _workspaces = [];
  var _nextId = 1;

  @override
  Future<List<WorkspaceEntity>> getAllWorkspaces() async =>
      List.unmodifiable(_workspaces);

  @override
  Stream<List<WorkspaceEntity>> watchAllWorkspaces() async* {
    yield List.unmodifiable(_workspaces);
  }

  @override
  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace) async {
    final entity = WorkspaceEntity(
      id: 'ws-${_nextId++}',
      name: workspace.name,
      type: workspace.type,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    _workspaces.add(entity);
    return entity;
  }

  @override
  Future<WorkspaceEntity> patchWorkspace(
    String id,
    WorkspacePatch workspace,
  ) async {
    final index = _workspaces.indexWhere((w) => w.id == id);
    if (index == -1) throw Exception('Workspace not found');
    final existing = _workspaces[index];
    final updated = existing.copyWith(
      name: workspace.name ?? existing.name,
      updatedAt: DateTime(2026),
    );
    _workspaces[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteWorkspace(String id) async {
    final index = _workspaces.indexWhere((w) => w.id == id);
    if (index == -1) return false;
    final _ = _workspaces.removeAt(index);
    return true;
  }

  @override
  Future<int> getWorkspaceCount() async => _workspaces.length;

  @override
  Future<int> getWorkspaceCountByType(WorkspaceType type) async =>
      _workspaces.where((w) => w.type == type).length;

  @override
  Future<WorkspaceEntity?> getWorkspaceById(String id) async =>
      _workspaces.where((w) => w.id == id).firstOrNull;

  @override
  Future<List<WorkspaceEntity>> getWorkspacesByType(WorkspaceType type) async =>
      _workspaces.where((w) => w.type == type).toList();

  @override
  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query) async =>
      _workspaces
          .where((w) => w.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

  @override
  Future<bool> validateWorkspace(WorkspaceToCreate workspace) async => true;

  @override
  Future<bool> workspaceExists(String id) async =>
      _workspaces.any((w) => w.id == id);

  @override
  Future<bool> patchWorkspaceTimestamp(String id) async => true;
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkspaceManagementMode', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is list mode with no editing workspace', () {
      final state = container.read(workspaceManagementModeProvider);

      expect(state.mode, ManagementMode.list);
      expect(state.editingWorkspace, isNull);
    });

    test('setMode changes mode', () {
      final notifier = container.read(
        workspaceManagementModeProvider.notifier,
      );

      notifier.setMode(ManagementMode.create);

      final state = container.read(workspaceManagementModeProvider);
      expect(state.mode, ManagementMode.create);
      expect(state.editingWorkspace, isNull);
    });

    test('setMode with editingWorkspace', () {
      final workspace = WorkspaceEntity(
        id: 'ws-1',
        name: 'Test',
        type: WorkspaceType.local,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final notifier = container.read(
        workspaceManagementModeProvider.notifier,
      );

      notifier.setMode(ManagementMode.edit, editingWorkspace: workspace);

      final state = container.read(workspaceManagementModeProvider);
      expect(state.mode, ManagementMode.edit);
      expect(state.editingWorkspace, workspace);
    });

    test('clearEditing resets to list mode', () {
      final workspace = WorkspaceEntity(
        id: 'ws-1',
        name: 'Test',
        type: WorkspaceType.local,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final notifier = container.read(
        workspaceManagementModeProvider.notifier,
      );

      notifier.setMode(ManagementMode.edit, editingWorkspace: workspace);
      notifier.clearEditing();

      final state = container.read(workspaceManagementModeProvider);
      expect(state.mode, ManagementMode.list);
      expect(state.editingWorkspace, isNull);
    });
  });

  group('ValidateWorkspaceNameUseCase', () {
    const usecase = ValidateWorkspaceNameUseCase();

    test('accepts name with 3 characters', () {
      expect(() => usecase.call(name: 'abc'), returnsNormally);
    });

    test('accepts name with 20 characters', () {
      expect(() => usecase.call(name: 'a' * 20), returnsNormally);
    });

    test('throws for name shorter than 3 characters', () {
      expect(
        () => usecase.call(name: 'ab'),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws for name longer than 20 characters', () {
      expect(
        () => usecase.call(name: 'a' * 21),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws for empty name', () {
      expect(
        () => usecase.call(name: ''),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('accepts whitespace-only name if length is in range', () {
      expect(() => usecase.call(name: '   '), returnsNormally);
    });
  });

  group('CreateWorkspaceUseCase', () {
    late _FakeWorkspaceRepository repository;
    late CreateWorkspaceUseCase usecase;

    setUp(() {
      repository = _FakeWorkspaceRepository();
      usecase = CreateWorkspaceUseCase(
        repository: repository,
        validateName: const ValidateWorkspaceNameUseCase(),
      );
    });

    test('creates workspace with valid name', () async {
      final result = await usecase.call(name: 'New Workspace');

      expect(result.name, 'New Workspace');
      expect(await repository.getWorkspaceCount(), 1);
    });

    test('throws validation error for short name', () async {
      expect(
        () => usecase.call(name: 'ab'),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('trims whitespace from name', () async {
      final result = await usecase.call(name: '  Test Name  ');

      expect(result.name, 'Test Name');
    });
  });

  group('EditWorkspaceUseCase', () {
    late _FakeWorkspaceRepository repository;
    late EditWorkspaceUseCase usecase;

    setUp(() {
      repository = _FakeWorkspaceRepository();
      usecase = EditWorkspaceUseCase(
        repository: repository,
        validateName: const ValidateWorkspaceNameUseCase(),
      );
    });

    test('edits workspace with valid name', () async {
      final created = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Old Name', type: WorkspaceType.local),
      );

      final result = await usecase.call(id: created.id, name: 'New Name');

      expect(result.name, 'New Name');
    });

    test('throws validation error for short name', () async {
      final created = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Old Name', type: WorkspaceType.local),
      );

      expect(
        () => usecase.call(id: created.id, name: 'ab'),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws when workspace not found', () async {
      expect(
        () => usecase.call(id: 'nonexistent', name: 'New Name'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('DeleteWorkspaceUseCase', () {
    late _FakeWorkspaceRepository repository;
    late DeleteWorkspaceUseCase usecase;

    setUp(() {
      repository = _FakeWorkspaceRepository();
      usecase = DeleteWorkspaceUseCase(repository: repository);
    });

    test('deletes workspace when multiple exist and not active', () async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'A', type: WorkspaceType.local),
      );
      final toDelete = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'B', type: WorkspaceType.local),
      );

      await usecase.call(
        id: toDelete.id,
        workspaceCount: 2,
        activeWorkspaceId: 'other',
      );

      expect(await repository.getWorkspaceCount(), 1);
    });

    test('throws when deleting last remaining workspace', () async {
      final only = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Only', type: WorkspaceType.local),
      );

      expect(
        () => usecase.call(
          id: only.id,
          workspaceCount: 1,
          activeWorkspaceId: 'other',
        ),
        throwsA(isA<WorkspaceDeleteLastException>()),
      );
    });

    test('throws when deleting active workspace', () async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'A', type: WorkspaceType.local),
      );
      final active = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'B', type: WorkspaceType.local),
      );

      expect(
        () => usecase.call(
          id: active.id,
          workspaceCount: 2,
          activeWorkspaceId: active.id,
        ),
        throwsA(isA<WorkspaceDeleteActiveException>()),
      );
    });
  });
}
