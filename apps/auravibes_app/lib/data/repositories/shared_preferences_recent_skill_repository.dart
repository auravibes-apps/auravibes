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
  }) => _enqueueWrite(
    (preferences) => _recordUseNow(preferences, workspaceId, skillSlug),
  );

  Future<void> _recordUseNow(
    SharedPreferences preferences,
    String workspaceId,
    String skillSlug,
  ) async {
    final key = _storageKey(workspaceId);
    final current = preferences.getStringList(key) ?? [];
    final recent = _recentSkillsAfterUse(current, skillSlug);
    await _writeRecentSkills(preferences, key, recent);
  }

  Future<void> _writeRecentSkills(
    SharedPreferences preferences,
    String key,
    List<String> skills,
  ) async {
    final didSave = await preferences.setStringList(key, skills);
    if (didSave) return;

    throw StateError('Unable to save recent skill usage.');
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

List<String> _recentSkillsAfterUse(List<String> current, String skillSlug) => [
  skillSlug,
  for (final slug in _unique(current))
    if (slug != skillSlug) slug,
];
