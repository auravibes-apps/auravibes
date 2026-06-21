// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_compaction_settings_dao.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:drift/drift.dart';

class WorkspaceCompactionSettingsRepository {
  WorkspaceCompactionSettingsRepository(this._dao);

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

  Stream<CompactionSettings> watchEffectiveSettings(String workspaceId) {
    return _dao.watchByWorkspaceId(workspaceId).map(_resolveEffective);
  }

  Future<CompactionSettings> getEffectiveSettings(String workspaceId) async {
    final row = await _dao.getByWorkspaceId(workspaceId);

    return _resolveEffective(row);
  }

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

  Future<CompactionSettings> resetOverrides(String workspaceId) async {
    await _dao.deleteByWorkspaceId(workspaceId);

    return CompactionSettings.defaults;
  }
}
