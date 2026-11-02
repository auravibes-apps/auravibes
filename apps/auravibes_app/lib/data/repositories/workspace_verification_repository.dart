import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_reservations.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

export 'workspace_verification_reservations.dart'
    show ScopedVerificationReservation;

/// Local owner policy and durable records. This repository never runs tools.
class WorkspaceVerificationRepository {
  new(this.database) : _sessionId = const Uuid().v4();

  final AppDatabase database;
  final String _sessionId;

  Future<ScopedVerificationSettings> getSettings(String workspaceId) async {
    if (!await isLocalVerificationWorkspace(database, workspaceId)) {
      return ScopedVerificationSettings();
    }
    final row = await (database.select(
      database.workspaceVerificationSettings,
    )..where((row) => row.workspaceId.equals(workspaceId))).getSingleOrNull();

    return _decodeSettings(row);
  }

  Stream<ScopedVerificationSettings> watchSettings(String workspaceId) async* {
    if (!await isLocalVerificationWorkspace(database, workspaceId)) {
      yield ScopedVerificationSettings();

      return;
    }
    yield* (database.select(database.workspaceVerificationSettings)
          ..where((row) => row.workspaceId.equals(workspaceId)))
        .watchSingleOrNull()
        .map(_decodeSettings);
  }

  Future<void> saveSettings(
    String workspaceId,
    ScopedVerificationSettings settings,
  ) => database.transaction(() async {
    if (!await isLocalVerificationWorkspace(database, workspaceId)) {
      throw const WorkspaceTableException(denied: true);
    }
    final current = await getSettings(workspaceId);
    if (current.revision != settings.revision) {
      throw const WorkspaceTableException(conflict: true);
    }
    final next = ScopedVerificationSettings.decode(
      jsonEncode({...settings.toJson(), 'revision': current.revision + 1}),
    );
    final _ = await database
        .into(database.workspaceVerificationSettings)
        .insertOnConflictUpdate(
          WorkspaceVerificationSettingsCompanion.insert(
            workspaceId: workspaceId,
            settingsJson: next.encode(),
            revision: next.revision,
          ),
        );
  });

  Future<ScopedVerificationReservation> reserve({
    required String workspaceId,
    required String turnId,
    required String toolCallId,
    required int configRevision,
    required int maxRepairAttempts,
  }) => database.transaction(
    () => WorkspaceVerificationReservations(database, _sessionId, getSettings)
        .reserve((
          workspaceId: workspaceId,
          turnId: turnId,
          toolCallId: toolCallId,
          configRevision: configRevision,
          maxRepairAttempts: maxRepairAttempts,
        )),
  );

  /// Returns the persisted winner so late replies cannot restore a pass.
  Future<ScopedVerificationResult> complete(
    String operationId,
    ScopedVerificationResult result,
  ) => database.transaction(() async {
    final row = await (database.select(
      database.workspaceVerificationRuns,
    )..where((row) => row.id.equals(operationId))).getSingleOrNull();
    if (row == null) return verificationUnavailable('workspace_unavailable');
    if (row.resultJson case final String saved) {
      return decodeVerificationResult(saved);
    }
    if (row.sessionId != _sessionId) {
      return verificationUnavailable('interrupted');
    }
    final settings = await getSettings(row.workspaceId);
    final safe = settings.enabled && settings.revision == row.configRevision
        ? result
        : verificationUnavailable('configuration_changed');
    final rows =
        await (database.select(database.workspaceVerificationRuns)..where(
              (entry) =>
                  entry.workspaceId.equals(row.workspaceId) &
                  entry.turnId.equals(row.turnId),
            ))
            .get();
    final remaining = verificationRepairsRemaining(rows);
    final finalResult = ScopedVerificationResult.fromJson({
      ...safe.toJson(),
      'repairAttemptsRemaining': remaining,
      'repairAllowed': safe.outcome == .fail && remaining > 0,
    });
    final _ =
        await (database.update(database.workspaceVerificationRuns)..where(
              (entry) =>
                  entry.id.equals(operationId) & entry.resultJson.isNull(),
            ))
            .write(
              WorkspaceVerificationRunsCompanion(
                resultJson: .new(jsonEncode(finalResult.toJson())),
              ),
            );

    return finalResult;
  });
}

ScopedVerificationSettings _decodeSettings(
  WorkspaceVerificationSettingsRow? row,
) {
  if (row == null) return ScopedVerificationSettings();
  try {
    final settings = ScopedVerificationSettings.decode(row.settingsJson);
    if (settings.revision == row.revision) return settings;
  } on FormatException {
    // Invalid stored authority is disabled until the local owner saves again.
  }

  return ScopedVerificationSettings(revision: row.revision);
}
