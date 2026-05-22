import 'package:auravibes_app/domain/entities/compaction.dart';

abstract class WorkspaceCompactionSettingsRepository {
  Stream<CompactionSettings> watchEffectiveSettings(String workspaceId);

  Future<CompactionSettings> getEffectiveSettings(String workspaceId);

  Future<CompactionSettings> saveOverrides(
    String workspaceId,
    CompactionSettings overrides,
  );

  Future<CompactionSettings> resetOverrides(String workspaceId);
}
