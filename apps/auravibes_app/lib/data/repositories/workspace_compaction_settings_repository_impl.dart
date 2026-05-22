import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_compaction_settings_dao.dart';
import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:auravibes_app/domain/repositories/workspace_compaction_settings_repository.dart';
import 'package:drift/drift.dart';

class WorkspaceCompactionSettingsRepositoryImpl
    implements WorkspaceCompactionSettingsRepository {
  WorkspaceCompactionSettingsRepositoryImpl(this._dao);

  final WorkspaceCompactionSettingsDao _dao;

  CompactionSettings _resolveEffective(
    WorkspaceCompactionSettingsTable? row,
  ) {
    if (row == null) return CompactionSettings.defaults;

    return CompactionSettings(
      autoCompactionEnabled:
          row.autoCompactEnabled ??
          CompactionSettings.defaults.autoCompactionEnabled,
      usagePercentageThreshold:
          row.usagePercentageThreshold ??
          CompactionSettings.defaults.usagePercentageThreshold,
      remainingTokenThreshold:
          row.remainingTokenThreshold ??
          CompactionSettings.defaults.remainingTokenThreshold,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Stream<CompactionSettings> watchEffectiveSettings(String workspaceId) {
    return _dao.watchByWorkspaceId(workspaceId).map(_resolveEffective);
  }

  @override
  Future<CompactionSettings> getEffectiveSettings(String workspaceId) async {
    final row = await _dao.getByWorkspaceId(workspaceId);
    return _resolveEffective(row);
  }

  @override
  Future<CompactionSettings> saveOverrides(
    String workspaceId,
    CompactionSettings overrides,
  ) async {
    final companion = WorkspaceCompactionSettingsCompanion(
      autoCompactEnabled: Value(overrides.autoCompactionEnabled),
      usagePercentageThreshold: Value(overrides.usagePercentageThreshold),
      remainingTokenThreshold: Value(overrides.remainingTokenThreshold),
    );
    final row = await _dao.upsert(workspaceId, companion);
    return _resolveEffective(row);
  }

  @override
  Future<CompactionSettings> resetOverrides(String workspaceId) async {
    await _dao.deleteByWorkspaceId(workspaceId);
    return CompactionSettings.defaults;
  }
}
