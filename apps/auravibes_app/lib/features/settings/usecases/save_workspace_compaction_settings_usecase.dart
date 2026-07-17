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
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

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

@Dependencies([workspaceSession, cloudWorkspaceStateGateway])
final saveWorkspaceCompactionSettingsUsecaseProvider =
    Provider<SaveWorkspaceCompactionSettingsUsecase>(
      (ref) {
        CloudWorkspaceRef? cloud;
        try {
          cloud = ref.watch(workspaceSessionProvider).cloud;
        } on Exception {
          cloud = null;
        }
        if (cloud != null) {
          final gateway = ref
              .watch(cloudWorkspaceStateGatewayProvider)
              .requireValue;
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
      },
      dependencies: [
        workspaceSessionProvider,
        cloudWorkspaceStateGatewayProvider,
      ],
    );
