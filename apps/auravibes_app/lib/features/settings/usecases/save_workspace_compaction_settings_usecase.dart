// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
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
    int? contextLimit,
  }) {
    _validate(settings, contextLimit: contextLimit);
    return repository.saveOverrides(workspaceId, settings);
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

final saveWorkspaceCompactionSettingsUsecaseProvider =
    Provider<SaveWorkspaceCompactionSettingsUsecase>((ref) {
      return SaveWorkspaceCompactionSettingsUsecase(
        repository: ref.watch(workspaceCompactionSettingsRepositoryProvider),
      );
    });
