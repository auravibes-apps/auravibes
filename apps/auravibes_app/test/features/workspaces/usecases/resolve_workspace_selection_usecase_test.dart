import 'package:auravibes_app/data/repositories/last_workspace_selection_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/workspaces/usecases/resolve_workspace_selection_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ResolveWorkspaceSelectionUsecase', () {
    test('uses a valid saved workspace selection', () async {
      final repository = await _createRepository();
      await repository.save('ws-2');
      final usecase = ResolveWorkspaceSelectionUsecase(
        loadWorkspaces: () async => [_workspace('ws-1'), _workspace('ws-2')],
        selectionRepository: repository,
      );

      final selection = await usecase();

      expect(selection, isNotNull);
      expect(selection?.workspaces, hasLength(2));
      expect(selection?.savedWorkspaceId, 'ws-2');
    });

    test(
      'clears a saved workspace ID no longer in the workspace list',
      () async {
        final repository = await _createRepository();
        await repository.save('missing');
        final usecase = ResolveWorkspaceSelectionUsecase(
          loadWorkspaces: () async => [_workspace('ws-1')],
          selectionRepository: repository,
        );

        final selection = await usecase();

        expect(selection, isNotNull);
        expect(selection?.savedWorkspaceId, isNull);
        expect(await repository.read(), isNull);
      },
    );

    test('does not clear selection when loading workspaces fails', () async {
      final repository = await _createRepository();
      await repository.save('ws-1');
      final usecase = ResolveWorkspaceSelectionUsecase(
        loadWorkspaces: () => Future<List<WorkspaceEntity>>.error(
          StateError('workspace load failed'),
        ),
        selectionRepository: repository,
      );

      final selection = await usecase();

      expect(selection, isNull);
      expect(await repository.read(), 'ws-1');
    });

    test('falls back when clearing a stale selection fails', () async {
      final usecase = ResolveWorkspaceSelectionUsecase(
        loadWorkspaces: () => Future.value([_workspace('ws-1')]),
        selectionRepository: _ClearFailingSelectionRepository(),
      );

      final selection = await usecase();

      expect(selection, isNotNull);
      expect(selection?.savedWorkspaceId, isNull);
    });

    test('falls back when reading the saved selection fails', () async {
      final usecase = ResolveWorkspaceSelectionUsecase(
        loadWorkspaces: () => Future.value([_workspace('ws-1')]),
        selectionRepository: _ReadFailingSelectionRepository(),
      );

      final selection = await usecase();

      expect(selection, isNotNull);
      expect(selection?.workspaces, hasLength(1));
      expect(selection?.savedWorkspaceId, isNull);
    });
  });
}

class _ClearFailingSelectionRepository implements WorkspaceSelectionRepository {
  @override
  Future<void> clearIfMatches(String workspaceId) =>
      Future<void>.error(StateError('clear failed'));

  @override
  Future<String?> read() => Future<String?>.value('missing');

  @override
  Future<void> save(String workspaceId) => Future<void>.value();
}

class _ReadFailingSelectionRepository implements WorkspaceSelectionRepository {
  @override
  Future<void> clearIfMatches(String workspaceId) => Future<void>.value();

  @override
  Future<String?> read() => Future<String?>.error(StateError('read failed'));

  @override
  Future<void> save(String workspaceId) => Future<void>.value();
}

Future<LastWorkspaceSelectionRepository> _createRepository() async {
  final preferences = await _preferences();

  return LastWorkspaceSelectionRepository(
    Future<SharedPreferences>.value(preferences),
  );
}

Future<SharedPreferences> _preferences() {
  SharedPreferences.setMockInitialValues({});

  return SharedPreferences.getInstance();
}

WorkspaceEntity _workspace(String id) {
  return WorkspaceEntity(
    id: id,
    name: 'Workspace',
    type: WorkspaceType.local,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}
