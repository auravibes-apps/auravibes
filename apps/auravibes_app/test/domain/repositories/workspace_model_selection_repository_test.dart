import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubRepository implements WorkspaceModelSelectionRepository {
  final List<WorkspaceModelSelectionToCreate> created = [];
  List<WorkspaceModelSelectionWithConnectionEntity> selectionResults = [];
  WorkspaceModelSelectionWithConnectionEntity? byIdResult;

  @override
  Future<void> createWorkspaceModelSelections(
    List<WorkspaceModelSelectionToCreate> workspaceModelSelections,
  ) async {
    created.addAll(workspaceModelSelections);
  }

  @override
  Future<List<WorkspaceModelSelectionWithConnectionEntity>>
  getWorkspaceModelSelections(
    WorkspaceModelSelectionFilter filter,
  ) async {
    return selectionResults;
  }

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?>
  getWorkspaceModelSelectionById(
    String id,
  ) async {
    return byIdResult;
  }
}

void main() {
  group('WorkspaceModelSelectionRepository', () {
    test('createWorkspaceModelSelections stores selections', () async {
      final repo = _StubRepository();
      const toCreate = WorkspaceModelSelectionToCreate(
        modelId: 'model-1',
        modelConnectionId: 'conn-1',
      );

      await repo.createWorkspaceModelSelections([toCreate]);

      expect(repo.created, hasLength(1));
      expect(repo.created.first.modelId, 'model-1');
      expect(repo.created.first.modelConnectionId, 'conn-1');
    });

    test('getWorkspaceModelSelections returns empty by default', () async {
      final repo = _StubRepository();

      final result = await repo.getWorkspaceModelSelections(
        const WorkspaceModelSelectionFilter(),
      );

      expect(result, isEmpty);
    });

    test('getWorkspaceModelSelectionById returns null by default', () async {
      final repo = _StubRepository();

      final result = await repo.getWorkspaceModelSelectionById('id-1');

      expect(result, isNull);
    });
  });

  group('WorkspaceModelSelectionException', () {
    test('contains message', () {
      const ex = WorkspaceModelSelectionException('test error');
      expect(ex.message, 'test error');
      expect(ex.cause, isNull);
    });

    test('toString includes message', () {
      const ex = WorkspaceModelSelectionException('test error');
      expect(ex.toString(), contains('test error'));
    });

    test('toString includes cause when provided', () {
      final cause = Exception('inner');
      final ex = WorkspaceModelSelectionException('test', cause);
      expect(ex.toString(), contains('Caused by:'));
    });
  });

  group('WorkspaceModelSelectionValidationException', () {
    test('is a WorkspaceModelSelectionException', () {
      const ex = WorkspaceModelSelectionValidationException('bad');
      expect(ex, isA<WorkspaceModelSelectionException>());
      expect(ex.message, 'bad');
    });
  });

  group('WorkspaceModelSelectionNotFoundException', () {
    test('contains id in message', () {
      const ex = WorkspaceModelSelectionNotFoundException('ws-123');
      expect(ex, isA<WorkspaceModelSelectionException>());
      expect(ex.workspaceModelSelectionId, 'ws-123');
      expect(ex.toString(), contains('ws-123'));
    });
  });
}
