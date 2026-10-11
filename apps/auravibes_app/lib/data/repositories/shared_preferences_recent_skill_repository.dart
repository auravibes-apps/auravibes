import 'dart:async';

import 'package:auravibes_app/domain/repositories/recent_skill_usage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesRecentSkillRepository(
  final Future<SharedPreferences> _preferences, {
  final String storageNamespace = 'auravibes_app',
}) implements RecentSkillUsageRepository {
  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<List<String>> readRecentSkillSlugs(String workspaceId) async {
    await _writeQueue;
    final preferences = await _preferences;

    return _unique(preferences.getStringList(_storageKey(workspaceId)) ?? []);
  }

  @override
  Future<void> recordUseNow({
    required String workspaceId,
    required String skillSlug,
  }) => _enqueueWrite((preferences) async {
    final key = _storageKey(workspaceId);
    final recent = [
      skillSlug,
      for (final slug in _unique(preferences.getStringList(key) ?? []))
        if (slug != skillSlug) slug,
    ];

    final didSave = await preferences.setStringList(key, recent);
    if (!didSave) {
      throw StateError('Unable to save recent skill usage.');
    }
  });

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

  String _storageKey(String workspaceId) {
    final key = 'skills.recent.$workspaceId';
    if (storageNamespace == 'auravibes_app') return key;

    return '$storageNamespace.$key';
  }
}

List<String> _unique(List<String> values) {
  final seen = <String>{};

  return [
    for (final value in values)
      if (seen.add(value)) value,
  ];
}
