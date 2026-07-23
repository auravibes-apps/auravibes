import 'package:auravibes_app/data/repositories/last_workspace_selection_repository.dart';
import 'package:auravibes_app/features/workspaces/usecases/select_workspace_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SelectWorkspaceUsecase', () {
    test('persists and returns an explicit workspace selection', () async {
      final repository = await _createRepository();
      final usecase = SelectWorkspaceUsecase(
        selectionRepository: repository,
      );

      final workspaceId = await usecase(workspaceId: 'ws-1');

      expect(workspaceId, 'ws-1');
      expect(await repository.read(), 'ws-1');
    });

    test('rejects a workspace ID that cannot be a route segment', () async {
      final repository = await _createRepository();
      final usecase = SelectWorkspaceUsecase(
        selectionRepository: repository,
      );

      await expectLater(
        usecase(workspaceId: 'workspace/other'),
        throwsA(isA<ArgumentError>()),
      );
      expect(await repository.read(), isNull);
    });

    test('rejects a dot-segment workspace ID', () async {
      final repository = await _createRepository();
      final usecase = SelectWorkspaceUsecase(
        selectionRepository: repository,
      );

      await expectLater(
        usecase(workspaceId: '..'),
        throwsA(isA<ArgumentError>()),
      );
      expect(await repository.read(), isNull);
    });

    test('rejects a current-directory workspace ID', () async {
      final repository = await _createRepository();
      final usecase = SelectWorkspaceUsecase(
        selectionRepository: repository,
      );

      await expectLater(
        usecase(workspaceId: '.'),
        throwsA(isA<ArgumentError>()),
      );
      expect(await repository.read(), isNull);
    });

    test('rejects an empty workspace ID', () async {
      final repository = await _createRepository();
      final usecase = SelectWorkspaceUsecase(
        selectionRepository: repository,
      );

      await expectLater(
        usecase(workspaceId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(await repository.read(), isNull);
    });
  });
}

Future<LastWorkspaceSelectionRepository> _createRepository() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  return LastWorkspaceSelectionRepository(
    Future<SharedPreferences>.value(preferences),
  );
}
