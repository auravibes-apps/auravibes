// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compaction_settings_provider.g.dart';

@riverpod
Stream<CompactionSettings> compactionSettings(Ref ref, String workspaceId) {
  final repository = ref.watch(workspaceCompactionSettingsRepositoryProvider);

  return repository.watchEffectiveSettings(workspaceId);
}
