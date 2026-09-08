// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_settings_adapter_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compaction_settings_provider.g.dart';

@riverpod
Stream<CompactionSettings> compactionSettings(
  Ref ref,
  String workspaceId,
) async* {
  final cloudAdapter = await cloudSkillSettingsAdapterForWorkspace(
    ref,
    workspaceId,
  );
  if (cloudAdapter == null) {
    yield* ref
        .watch(workspaceCompactionSettingsRepositoryProvider)
        .watchEffectiveSettings(workspaceId);

    return;
  }

  yield* cloudAdapter.watchCompactionSettings();
}
// Top-level API/provider declarations are required by their consumers.
