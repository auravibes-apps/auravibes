// Required: test expectations use chaining on matchers which triggers
// cascade_invocations lint. Not applicable in test assertions.

import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/delete_workspace_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/edit_workspace_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements WorkspaceRepository {
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
  Future<WorkspaceEntity?> getWorkspaceById(String id) async =>
      _workspaces.firstWhereOrNull((w) => w.id == id);

  @override
  Future<List<WorkspaceEntity>> getWorkspacesByType(
    WorkspaceType type,
  ) async => _workspaces.where((w) => w.type == type).toList();

  @override
  Future<WorkspaceEntity> createWorkspace(
    WorkspaceToCreate workspace,
  ) async {
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
    if (index == -1) {
      throw WorkspaceNotFoundException(id);
    }

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
    final before = _workspaces.length;
    _workspaces.removeWhere((w) => w.id == id);
    return _workspaces.length < before;
  }

  @override
  Future<bool> workspaceExists(String id) async =>
      _workspaces.any((w) => w.id == id);

  @override
  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query) async =>
      _workspaces
          .where((w) => w.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

  @override
  Future<int> getWorkspaceCount() async => _workspaces.length;

  @override
  Future<int> getWorkspaceCountByType(WorkspaceType type) async =>
      _workspaces.where((w) => w.type == type).length;

  @override
  Future<bool> validateWorkspace(WorkspaceToCreate workspace) async => true;

  @override
  Future<bool> patchWorkspaceTimestamp(String id) async => true;
}

void main() {
  group('ValidateWorkspaceNameUseCase', () {
    const usecase = ValidateWorkspaceNameUseCase();

    test('accepts name with exactly 3 characters', () {
      expect(() => usecase.call(name: 'abc'), returnsNormally);
    });

    test('accepts name with 20 characters', () {
      expect(() => usecase.call(name: 'a' * 20), returnsNormally);
    });

    test('accepts name within valid range', () {
      expect(() => usecase.call(name: 'My Workspace'), returnsNormally);
    });

    test('throws when name is empty', () {
      expect(
        () => usecase.call(name: ''),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws when name is 2 characters (below minimum)', () {
      expect(
        () => usecase.call(name: 'ab'),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws when name is 21 characters (above maximum)', () {
      expect(
        () => usecase.call(name: 'a' * 21),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('short name error has correct localization key', () {
      try {
        usecase.call(name: 'ab');
        fail('Expected exception');
      } on WorkspaceValidationException catch (e) {
        expect(e.localizationKey, isNotNull);
        expect(
          e.localizationKey,
          LocaleKeys.workspace_management_name_too_short_error,
        );
      }
    });

    test('long name error has correct localization key', () {
      try {
        usecase.call(name: 'a' * 21);
        fail('Expected exception');
      } on WorkspaceValidationException catch (e) {
        expect(e.localizationKey, isNotNull);
        expect(
          e.localizationKey,
          LocaleKeys.workspace_management_name_too_long_error,
        );
      }
    });
  });

  group('CreateWorkspaceUseCase', () {
    late _FakeRepository repository;
    late CreateWorkspaceUseCase usecase;

    setUp(() {
      repository = _FakeRepository();
      usecase = CreateWorkspaceUseCase(
        repository: repository,
        validateName: const ValidateWorkspaceNameUseCase(),
      );
    });

    test('creates workspace with valid name', () async {
      final entity = await usecase.call(name: 'My Workspace');

      expect(entity.name, 'My Workspace');
      expect(entity.type, WorkspaceType.local);
    });

    test('trims whitespace from name', () async {
      final entity = await usecase.call(name: '  Workspace  ');

      expect(entity.name, 'Workspace');
    });

    test('throws for name shorter than 3 characters', () async {
      expect(
        () => usecase.call(name: 'ab'),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws for name longer than 20 characters', () async {
      expect(
        () => usecase.call(name: 'a' * 21),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });
  });

  group('EditWorkspaceUseCase', () {
    late _FakeRepository repository;
    late EditWorkspaceUseCase usecase;

    setUp(() async {
      repository = _FakeRepository();
      await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Original', type: WorkspaceType.local),
      );
      usecase = EditWorkspaceUseCase(
        repository: repository,
        validateName: const ValidateWorkspaceNameUseCase(),
      );
    });

    test('edits workspace name successfully', () async {
      final entity = await usecase.call(
        id: 'ws-1',
        name: 'New Name',
      );

      expect(entity.name, 'New Name');
    });

    test('trims whitespace from edited name', () async {
      final entity = await usecase.call(
        id: 'ws-1',
        name: '  Updated  ',
      );

      expect(entity.name, 'Updated');
    });

    test('throws for invalid name', () async {
      expect(
        () => usecase.call(id: 'ws-1', name: 'ab'),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws for name longer than 20 characters', () async {
      expect(
        () => usecase.call(id: 'ws-1', name: 'a' * 21),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });
  });

  group('DeleteWorkspaceUseCase', () {
    late _FakeRepository repository;
    late DeleteWorkspaceUseCase usecase;

    setUp(() async {
      repository = _FakeRepository();
      usecase = DeleteWorkspaceUseCase(repository: repository);
    });

    test('deletes workspace successfully', () async {
      await repository.createWorkspace(
        const WorkspaceToCreate(name: 'WS1', type: WorkspaceType.local),
      );
      await repository.createWorkspace(
        const WorkspaceToCreate(name: 'WS2', type: WorkspaceType.local),
      );

      await usecase.call(
        id: 'ws-1',
        workspaceCount: 2,
        activeWorkspaceId: 'ws-2',
      );

      final remaining = await repository.getAllWorkspaces();
      expect(remaining, hasLength(1));
    });

    test('throws when deleting last remaining workspace', () async {
      await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Only', type: WorkspaceType.local),
      );

      expect(
        () => usecase.call(
          id: 'ws-1',
          workspaceCount: 1,
          activeWorkspaceId: null,
        ),
        throwsA(isA<WorkspaceDeleteLastException>()),
      );
    });

    test('throws when deleting active workspace', () async {
      await repository.createWorkspace(
        const WorkspaceToCreate(name: 'WS1', type: WorkspaceType.local),
      );
      await repository.createWorkspace(
        const WorkspaceToCreate(name: 'WS2', type: WorkspaceType.local),
      );

      expect(
        () => usecase.call(
          id: 'ws-1',
          workspaceCount: 2,
          activeWorkspaceId: 'ws-1',
        ),
        throwsA(isA<WorkspaceDeleteActiveException>()),
      );
    });

    test('last workspace guard takes priority over active guard', () async {
      await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Only', type: WorkspaceType.local),
      );

      expect(
        () => usecase.call(
          id: 'ws-1',
          workspaceCount: 1,
          activeWorkspaceId: 'ws-1',
        ),
        throwsA(isA<WorkspaceDeleteLastException>()),
      );
    });
  });
}
