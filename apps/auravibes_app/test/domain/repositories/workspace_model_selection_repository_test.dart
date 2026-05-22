import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
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
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
  watchWorkspaceModelSelections(
    WorkspaceModelSelectionFilter filter,
  ) {
    return Stream.value(selectionResults);
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

    test('watchWorkspaceModelSelections streams empty by default', () async {
      final repo = _StubRepository();

      final result = await repo
          .watchWorkspaceModelSelections(
            const WorkspaceModelSelectionFilter(),
          )
          .first;

      expect(result, isEmpty);
    });

    test('getWorkspaceModelSelectionById returns null by default', () async {
      final repo = _StubRepository();

      final result = await repo.getWorkspaceModelSelectionById('id-1');

      expect(result, isNull);
    });
  });
}
