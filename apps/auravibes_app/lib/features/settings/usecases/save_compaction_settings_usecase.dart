import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/domain/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:riverpod/riverpod.dart';

class SaveWorkspaceCompactionSettingsUsecase {
  const SaveWorkspaceCompactionSettingsUsecase({required this.repository});

  final WorkspaceCompactionSettingsRepository repository;

  Future<CompactionSettings> call({
    required String workspaceId,
    required CompactionSettings settings,
  }) async {
    _validate(settings);
    return repository.saveOverrides(workspaceId, settings);
  }

  void _validate(CompactionSettings settings) {
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
  }
}

final saveWorkspaceCompactionSettingsUsecaseProvider =
    Provider<SaveWorkspaceCompactionSettingsUsecase>((ref) {
      return SaveWorkspaceCompactionSettingsUsecase(
        repository: ref.watch(workspaceCompactionSettingsRepositoryProvider),
      );
    });
