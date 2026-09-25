// Required: Existing test and UI helpers keep compact return flow.
import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';

class WorkspaceCompactionSettingsRepository(
  final WorkspaceCompactionSettingsDao _dao,
) {
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
      autoCompactEnabled: .new(overrides.autoCompactionEnabled),
      usagePercentageThreshold: .new(overrides.usagePercentageThreshold),
      remainingTokenThreshold: .new(overrides.remainingTokenThreshold),
      modelOverridesJson: .new(
        jsonEncode({
          for (final entry in overrides.modelOverrides.entries)
            entry.key: entry.value.toJson(),
        }),
      ),
    );
    final row = await _dao.upsert(workspaceId, companion);

    return _resolveEffective(row);
  }

  Future<CompactionSettings> resetOverrides(String workspaceId) async {
    await _dao.deleteByWorkspaceId(workspaceId);

    return CompactionSettings.defaults;
  }

  CompactionSettings _resolveEffective(WorkspaceCompactionSettingsTable? row) {
    if (row == null) return CompactionSettings.defaults;

    const defaults = CompactionSettings.defaults;

    return CompactionSettings(
      autoCompactionEnabled:
          row.autoCompactEnabled ?? defaults.autoCompactionEnabled,
      usagePercentageThreshold:
          row.usagePercentageThreshold ?? defaults.usagePercentageThreshold,
      remainingTokenThreshold:
          row.remainingTokenThreshold ?? defaults.remainingTokenThreshold,
      updatedAt: row.updatedAt,
      modelOverrides: _decodeModelOverrides(row.modelOverridesJson),
    );
  }

  Map<String, CompactionModelOverride> _decodeModelOverrides(String? json) {
    if (json == null) return const {};
    try {
      return CompactionSettings.fromJson({'modelOverrides': jsonDecode(json)})
          .modelOverrides;
    } on FormatException {
      return const {};
    }
  }
}
