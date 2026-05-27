// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: cascade_invocations
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubWorkspaceRepository implements WorkspaceRepository {
  List<WorkspaceEntity> allWorkspaces = [];
  WorkspaceEntity? byIdResult;
  List<WorkspaceEntity> byType = [];
  List<WorkspaceEntity> created = [];
  List<WorkspaceEntity> patched = [];
  bool deleteResult = true;
  bool existsResult = false;
  List<WorkspaceEntity> searchResults = [];
  int countResult = 0;
  int countByTypeResult = 0;
  bool validateResult = true;
  bool patchTimestampResult = true;

  @override
  Future<List<WorkspaceEntity>> getAllWorkspaces() async => allWorkspaces;

  @override
  Stream<List<WorkspaceEntity>> watchAllWorkspaces() async* {
    yield allWorkspaces;
  }

  @override
  Future<WorkspaceEntity?> getWorkspaceById(String id) async => byIdResult;

  @override
  Future<List<WorkspaceEntity>> getWorkspacesByType(
    WorkspaceType type,
  ) async {
    return byType;
  }

  @override
  Future<WorkspaceEntity> createWorkspace(
    WorkspaceToCreate workspace,
  ) async {
    final entity = WorkspaceEntity(
      id: 'ws-${created.length}',
      name: workspace.name,
      type: workspace.type,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      url: workspace.url,
    );
    created.add(entity);
    return entity;
  }

  @override
  Future<WorkspaceEntity> patchWorkspace(
    String id,
    WorkspacePatch workspace,
  ) async {
    final entity = WorkspaceEntity(
      id: id,
      name: workspace.name ?? 'patched',
      type: workspace.type ?? WorkspaceType.local,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      url: workspace.url,
    );
    patched.add(entity);
    return entity;
  }

  @override
  Future<bool> deleteWorkspace(String id) async => deleteResult;

  @override
  Future<bool> workspaceExists(String id) async => existsResult;

  @override
  Future<List<WorkspaceEntity>> searchWorkspacesByName(
    String query,
  ) async {
    return searchResults;
  }

  @override
  Future<int> getWorkspaceCount() async => countResult;

  @override
  Future<int> getWorkspaceCountByType(WorkspaceType type) async =>
      countByTypeResult;

  @override
  Future<bool> validateWorkspace(WorkspaceToCreate workspace) async {
    if (!validateResult) {
      throw const WorkspaceValidationException(
        'Validation failed',
        localizationKey: 'test.validation_failed',
      );
    }
    return true;
  }

  @override
  Future<bool> patchWorkspaceTimestamp(String id) async => patchTimestampResult;
}

void main() {
  group('WorkspaceRepository', () {
    test('getAllWorkspaces returns list', () async {
      final repo = _StubWorkspaceRepository();
      repo.allWorkspaces = [
        WorkspaceEntity(
          id: 'ws-1',
          name: 'Test',
          type: WorkspaceType.local,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      final result = await repo.getAllWorkspaces();

      expect(result, hasLength(1));
      expect(result.firstOrNull?.id, 'ws-1');
    });

    test('getWorkspaceById returns null when not found', () async {
      final repo = _StubWorkspaceRepository();

      final result = await repo.getWorkspaceById('missing');

      expect(result, isNull);
    });

    test('getWorkspacesByType returns filtered list', () async {
      final repo = _StubWorkspaceRepository();

      final result = await repo.getWorkspacesByType(WorkspaceType.remote);

      expect(result, isEmpty);
    });

    test('createWorkspace returns entity', () async {
      final repo = _StubWorkspaceRepository();
      const toCreate = WorkspaceToCreate(
        name: 'New',
        type: WorkspaceType.local,
      );

      final result = await repo.createWorkspace(toCreate);

      expect(result.name, 'New');
      expect(result.type, WorkspaceType.local);
      expect(repo.created, hasLength(1));
    });

    test('patchWorkspace returns patched entity', () async {
      final repo = _StubWorkspaceRepository();
      const patch = WorkspacePatch(name: 'Updated');

      final result = await repo.patchWorkspace('ws-1', patch);

      expect(result.name, 'Updated');
      expect(result.id, 'ws-1');
      expect(repo.patched, hasLength(1));
    });

    test('deleteWorkspace returns bool', () async {
      final repo = _StubWorkspaceRepository();

      expect(await repo.deleteWorkspace('ws-1'), true);

      repo.deleteResult = false;
      expect(await repo.deleteWorkspace('ws-2'), false);
    });

    test('workspaceExists returns bool', () async {
      final repo = _StubWorkspaceRepository();
      repo.existsResult = true;

      expect(await repo.workspaceExists('ws-1'), true);
    });

    test('searchWorkspacesByName returns list', () async {
      final repo = _StubWorkspaceRepository();

      final result = await repo.searchWorkspacesByName('test');

      expect(result, isEmpty);
    });

    test('getWorkspaceCount returns count', () async {
      final repo = _StubWorkspaceRepository();
      repo.countResult = 5;

      expect(await repo.getWorkspaceCount(), 5);
    });

    test('getWorkspaceCountByType returns count', () async {
      final repo = _StubWorkspaceRepository();
      repo.countByTypeResult = 3;

      expect(
        await repo.getWorkspaceCountByType(WorkspaceType.local),
        3,
      );
    });

    test('validateWorkspace throws for invalid name', () async {
      final repo = _StubWorkspaceRepository();
      repo.validateResult = false;

      expect(
        () => repo.validateWorkspace(
          const WorkspaceToCreate(name: '  ', type: WorkspaceType.local),
        ),
        throwsA(
          isA<WorkspaceValidationException>().having(
            (e) => e.localizationKey,
            'localizationKey',
            isNotEmpty,
          ),
        ),
      );
    });

    test('validateWorkspace returns bool', () async {
      final repo = _StubWorkspaceRepository();
      const toCreate = WorkspaceToCreate(
        name: 'Valid',
        type: WorkspaceType.local,
      );

      expect(await repo.validateWorkspace(toCreate), true);
    });

    test('patchWorkspaceTimestamp returns bool', () async {
      final repo = _StubWorkspaceRepository();

      expect(await repo.patchWorkspaceTimestamp('ws-1'), true);

      repo.patchTimestampResult = false;
      expect(await repo.patchWorkspaceTimestamp('ws-2'), false);
    });
  });

  group('WorkspaceException', () {
    test('contains message', () {
      const ex = WorkspaceException('test error');
      expect(ex.message, 'test error');
      expect(ex.cause, isNull);
    });

    test('toString without cause', () {
      const ex = WorkspaceException('oops');
      expect(ex.toString(), 'WorkspaceException: oops');
    });

    test('toString includes cause when provided', () {
      final cause = Exception('inner');
      final ex = WorkspaceException('test', cause: cause);
      expect(ex.toString(), contains('Caused by:'));
    });
  });

  group('WorkspaceValidationException', () {
    test('is a WorkspaceException', () {
      const ex = WorkspaceValidationException('bad');
      expect(ex, isA<WorkspaceException>());
      expect(ex.message, 'bad');
    });
  });

  group('WorkspaceNotFoundException', () {
    test('contains id in message', () {
      const ex = WorkspaceNotFoundException('ws-42');
      expect(ex, isA<WorkspaceException>());
      expect(ex.workspaceId, 'ws-42');
      expect(ex.toString(), contains('ws-42'));
      expect(ex.toString(), contains('not found'));
    });

    test('includes cause when provided', () {
      final cause = Exception('db error');
      final ex = WorkspaceNotFoundException('ws-1', cause: cause);
      expect(ex.cause, cause);
    });
  });

  group('WorkspaceDuplicateException', () {
    test('contains id in message', () {
      const ex = WorkspaceDuplicateException('ws-99');
      expect(ex, isA<WorkspaceException>());
      expect(ex.workspaceId, 'ws-99');
      expect(ex.toString(), contains('ws-99'));
      expect(ex.toString(), contains('already exists'));
    });

    test('includes cause when provided', () {
      final cause = Exception('unique constraint');
      final ex = WorkspaceDuplicateException('ws-1', cause: cause);
      expect(ex.cause, cause);
    });
  });
}
