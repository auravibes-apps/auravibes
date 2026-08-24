// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_settings_adapter.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'save_workspace_compaction_settings_usecase.g.dart';

class SaveWorkspaceCompactionSettingsUsecase {
  const SaveWorkspaceCompactionSettingsUsecase({
    this.repository,
    this.cloudAdapter,
  });

  final WorkspaceCompactionSettingsRepository? repository;
  final CloudSkillSettingsAdapter? cloudAdapter;

  Future<CompactionSettings> call({
    required String workspaceId,
    required CompactionSettings settings,
    int? contextLimit,
  }) {
    _validate(settings, contextLimit: contextLimit);
    final cloud = cloudAdapter;
    if (cloud != null) return cloud.saveCurrentCompactionSettings(settings);
    final localRepository = repository;
    if (localRepository == null) {
      throw StateError('Compaction settings store is unavailable');
    }

    return localRepository.saveOverrides(workspaceId, settings);
  }

  Future<void> reset({required String workspaceId}) async {
    final cloud = cloudAdapter;
    if (cloud != null) return cloud.resetCompactionSettings();
    final localRepository = repository;
    if (localRepository == null) {
      throw StateError('Compaction settings store is unavailable');
    }
    final _ = await localRepository.resetOverrides(workspaceId);
  }

  void _validate(CompactionSettings settings, {int? contextLimit}) {
    if (settings.usagePercentageThreshold < 5 ||
        settings.usagePercentageThreshold > 100) {
      throw const CompactionSettingsValidationException(
        LocaleKeys.compaction_settings_validation_usage_range,
      );
    }
    if (settings.remainingTokenThreshold <= 0) {
      throw const CompactionSettingsValidationException(
        LocaleKeys.compaction_settings_validation_remaining_positive,
      );
    }
    if (contextLimit != null &&
        settings.remainingTokenThreshold >= contextLimit) {
      throw const CompactionSettingsValidationException(
        LocaleKeys.compaction_settings_validation_remaining_below_limit,
      );
    }
  }
}

@riverpod
Future<SaveWorkspaceCompactionSettingsUsecase>
saveWorkspaceCompactionSettingsUsecase(Ref ref, String workspaceId) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (session.cloud case final CloudWorkspaceRef _) {
    final gateway = await ref.watch(
      cloudWorkspaceStateGatewayProvider(session).future,
    );
    if (gateway == null) {
      throw StateError('Cloud workspace gateway is unavailable');
    }

    return SaveWorkspaceCompactionSettingsUsecase(
      cloudAdapter: CloudSkillSettingsAdapter(gateway),
    );
  }

  return SaveWorkspaceCompactionSettingsUsecase(
    repository: ref.watch(workspaceCompactionSettingsRepositoryProvider),
  );
}
// Top-level API/provider declarations are required by their consumers.
