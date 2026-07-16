// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_settings_adapter.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compaction_settings_provider.g.dart';

@Dependencies([cloudWorkspaceStateGateway])
@riverpod
Stream<CompactionSettings> compactionSettings(Ref ref, String workspaceId) {
  final gateway = ref.watch(cloudWorkspaceStateGatewayProvider);

  return gateway.when(
    data: (value) => value == null
        ? ref
              .watch(workspaceCompactionSettingsRepositoryProvider)
              .watchEffectiveSettings(workspaceId)
        : CloudSkillSettingsAdapter(value).watchCompactionSettings(),
    error: Stream.error,
    loading: () => const Stream.empty(),
  );
}
