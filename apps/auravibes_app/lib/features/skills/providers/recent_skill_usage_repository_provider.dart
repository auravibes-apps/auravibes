import 'package:auravibes_app/data/repositories/shared_preferences_recent_skill_repository.dart';
import 'package:auravibes_app/domain/repositories/recent_skill_usage_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_skill_usage_repository_provider.g.dart';

@Riverpod(keepAlive: true)
RecentSkillUsageRepository recentSkillUsageRepository(Ref ref) {
  return SharedPreferencesRecentSkillRepository(
    ref.watch(sharedPreferencesProvider.future),
    storageNamespace: ref.watch(appStorageNamespaceProvider),
  );
}
