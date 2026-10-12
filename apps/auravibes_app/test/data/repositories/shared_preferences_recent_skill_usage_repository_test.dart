import 'package:auravibes_app/data/repositories/shared_preferences_recent_skill_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('records skills newest first and removes duplicate entries', () async {
    final preferences = await SharedPreferences.getInstance();
    expect(
      await preferences.setStringList('skills.recent.workspace-1', [
        'writing',
        'research',
        'writing',
      ]),
      isTrue,
    );
    final repository = SharedPreferencesRecentSkillRepository(
      .value(preferences),
    );

    expect(await repository.readRecentSkillSlugs('workspace-1'), [
      'writing',
      'research',
    ]);

    await repository.recordUseNow(
      workspaceId: 'workspace-1',
      skillSlug: 'research',
    );

    expect(await repository.readRecentSkillSlugs('workspace-1'), [
      'research',
      'writing',
    ]);
  });

  test(
    'keeps workspaces isolated and survives repository recreation',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = SharedPreferencesRecentSkillRepository(
        .value(preferences),
      );
      await repository.recordUseNow(
        workspaceId: 'workspace-1',
        skillSlug: 'research',
      );
      await repository.recordUseNow(
        workspaceId: 'workspace-2',
        skillSlug: 'writing',
      );

      final restartedRepository = SharedPreferencesRecentSkillRepository(
        .value(await SharedPreferences.getInstance()),
      );

      expect(await restartedRepository.readRecentSkillSlugs('workspace-1'), [
        'research',
      ]);
      expect(await restartedRepository.readRecentSkillSlugs('workspace-2'), [
        'writing',
      ]);
      expect(
        await restartedRepository.readRecentSkillSlugs('workspace-3'),
        isEmpty,
      );
    },
  );

  test('keeps environment namespaces separate', () async {
    final preferences = await SharedPreferences.getInstance();
    final defaultRepository = SharedPreferencesRecentSkillRepository(
      .value(preferences),
    );
    final isolatedRepository = SharedPreferencesRecentSkillRepository(
      .value(preferences),
      storageNamespace: 'auravibes_app_test',
    );
    await defaultRepository.recordUseNow(
      workspaceId: 'workspace-1',
      skillSlug: 'research',
    );

    expect(
      await isolatedRepository.readRecentSkillSlugs('workspace-1'),
      isEmpty,
    );
  });
}
