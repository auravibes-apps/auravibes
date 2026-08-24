import 'dart:async';

import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastWorkspaceSelectionRepository implements WorkspaceSelectionRepository {
  LastWorkspaceSelectionRepository(
    this._preferences, {
    this.storageKey = 'last_selected_workspace_id',
  });
  final String storageKey;

  final Future<SharedPreferences> _preferences;
  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<String?> read() async {
    await _writeQueue;
    final preferences = await _preferences;

    return preferences.getString(storageKey);
  }

  @override
  Future<void> save(String workspaceId) => _enqueueWrite((preferences) async {
    final didSave = await preferences.setString(storageKey, workspaceId);
    if (!didSave) {
      throw StateError('Unable to save the selected workspace.');
    }
  });

  Future<void> clear() => _enqueueWrite(_clear);

  @override
  Future<void> clearIfMatches(String workspaceId) {
    return _enqueueWrite((preferences) async {
      if (preferences.getString(storageKey) != workspaceId) return;

      await _clear(preferences);
    });
  }

  Future<void> _enqueueWrite(
    Future<void> Function(SharedPreferences preferences) write,
  ) async {
    final previousWrite = _writeQueue;
    final completion = Completer<void>();
    _writeQueue = completion.future;

    try {
      await previousWrite;
      final preferences = await _preferences;
      await write(preferences);
      completion.complete();
    } on Object {
      completion.complete();
      rethrow;
    }
  }

  Future<void> _clear(SharedPreferences preferences) async {
    final didClear = await preferences.remove(storageKey);
    if (!didClear) {
      throw StateError('Unable to clear the selected workspace.');
    }
  }
}
