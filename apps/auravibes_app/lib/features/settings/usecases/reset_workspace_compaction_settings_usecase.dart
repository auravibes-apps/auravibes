import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

class ResetWorkspaceCompactionSettingsUsecase {
  const ResetWorkspaceCompactionSettingsUsecase({required this.repository});

  final WorkspaceCompactionSettingsRepository repository;

  Future<CompactionSettings> call({required String workspaceId}) {
    return repository.resetOverrides(workspaceId);
  }
}

final resetWorkspaceCompactionSettingsUsecaseProvider =
    Provider<ResetWorkspaceCompactionSettingsUsecase>((ref) {
      return ResetWorkspaceCompactionSettingsUsecase(
        repository: ref.watch(workspaceCompactionSettingsRepositoryProvider),
      );
    });
