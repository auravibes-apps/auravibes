import 'package:auravibes_app/data/repositories/last_workspace_selection_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LastWorkspaceSelectionRepository', () {
    test('returns no selection when none is stored', () async {
      final repository = await _createRepository();

      expect(await repository.read(), isNull);
    });

    test('saves the selected workspace ID', () async {
      final repository = await _createRepository();

      await repository.save('ws-1');

      expect(await repository.read(), 'ws-1');
    });

    test('stores selection under configured key', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = LastWorkspaceSelectionRepository(
        Future<SharedPreferences>.value(preferences),
        storageKey: 'auravibes_app_0123456789abcdef.last_selected_workspace_id',
      );

      await repository.save('ws-1');

      expect(preferences.getString('last_selected_workspace_id'), isNull);
      expect(
        preferences.getString(
          'auravibes_app_0123456789abcdef.last_selected_workspace_id',
        ),
        'ws-1',
      );
    });

    test('waits for queued writes before reading', () async {
      final repository = await _createRepository();

      final save = repository.save('ws-1');

      expect(await repository.read(), 'ws-1');
      await save;
    });

    test('clears the stored workspace ID', () async {
      final repository = await _createRepository();
      await repository.save('ws-1');

      await repository.clear();

      expect(await repository.read(), isNull);
    });

    test('clears a matching selection', () async {
      final repository = await _createRepository();
      await repository.save('ws-1');

      await repository.clearIfMatches('ws-1');

      expect(await repository.read(), isNull);
    });

    test('does not clear a newer selection', () async {
      final repository = await _createRepository();
      await repository.save('stale-workspace');
      await repository.save('new-workspace');

      await repository.clearIfMatches('stale-workspace');

      expect(await repository.read(), 'new-workspace');
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
