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
  ) => database.transaction(
    () => _saveWorkspaceSettings(database, getSettings, workspaceId, settings),
  );

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
  ) => database.transaction(
    () => _completeWorkspaceVerification((
      database: database,
      sessionId: _sessionId,
      getSettings: getSettings,
      operationId: operationId,
      result: result,
    )),
  );
}

typedef _CompleteWorkspaceVerification = ({
  AppDatabase database,
  String sessionId,
  Future<ScopedVerificationSettings> Function(String workspaceId) getSettings,
  String operationId,
  ScopedVerificationResult result,
});

typedef _SaveWorkspaceSettings = ({
  AppDatabase database,
  Future<ScopedVerificationSettings> Function(String workspaceId) getSettings,
  String workspaceId,
  ScopedVerificationSettings settings,
});

Future<void> _saveWorkspaceSettings(
  AppDatabase database,
  Future<ScopedVerificationSettings> Function(String workspaceId) getSettings,
  String workspaceId,
  ScopedVerificationSettings settings,
) => _saveWorkspaceSettingsInTransaction((
  database: database,
  getSettings: getSettings,
  workspaceId: workspaceId,
  settings: settings,
));

Future<void> _saveWorkspaceSettingsInTransaction(
  _SaveWorkspaceSettings request,
) async {
  if (!await isLocalVerificationWorkspace(
    request.database,
    request.workspaceId,
  )) {
    throw const WorkspaceTableException(denied: true);
  }
  final current = await request.getSettings(request.workspaceId);
  if (current.revision != request.settings.revision) {
    throw const WorkspaceTableException(conflict: true);
  }
  final next = _nextSettingsRevision(request.settings, current.revision);
  await _storeSettings(request.database, request.workspaceId, next);
}

Future<void> _storeSettings(
  AppDatabase database,
  String workspaceId,
  ScopedVerificationSettings settings,
) async {
  final _ = await database
      .into(database.workspaceVerificationSettings)
      .insertOnConflictUpdate(
        WorkspaceVerificationSettingsCompanion.insert(
          workspaceId: workspaceId,
          settingsJson: settings.encode(),
          revision: settings.revision,
        ),
      );
}

Future<ScopedVerificationResult> _completeWorkspaceVerification(
  _CompleteWorkspaceVerification request,
) async {
  final row = await (request.database.select(
    request.database.workspaceVerificationRuns,
  )..where((row) => row.id.equals(request.operationId))).getSingleOrNull();
  if (row == null) return verificationUnavailable('workspace_unavailable');
  final saved = _completedResult(row);
  if (saved != null) return saved;
  if (row.sessionId != request.sessionId) {
    return verificationUnavailable('interrupted');
  }
  final result = await _resultWithCurrentAuthority(request, row);
  await _saveCompletedResult(request.database, request.operationId, result);

  return result;
}

ScopedVerificationResult? _completedResult(WorkspaceVerificationRunRow row) {
  if (row.resultJson case final String saved) {
    return decodeVerificationResult(saved);
  }

  return null;
}

Future<ScopedVerificationResult> _resultWithCurrentAuthority(
  _CompleteWorkspaceVerification request,
  WorkspaceVerificationRunRow row,
) async {
  final settings = await request.getSettings(row.workspaceId);
  final safe = settings.enabled && settings.revision == row.configRevision
      ? request.result
      : verificationUnavailable('configuration_changed');
  final rows =
      await (request.database.select(request.database.workspaceVerificationRuns)
            ..where(
              (entry) =>
                  entry.workspaceId.equals(row.workspaceId) &
                  entry.turnId.equals(row.turnId),
            ))
          .get();
  final remaining = verificationRepairsRemaining(rows);

  return ScopedVerificationResult.fromJson({
    ...safe.toJson(),
    'repairAttemptsRemaining': remaining,
    'repairAllowed': safe.outcome == .fail && remaining > 0,
  });
}

Future<void> _saveCompletedResult(
  AppDatabase database,
  String operationId,
  ScopedVerificationResult result,
) async {
  final _ =
      await (database.update(database.workspaceVerificationRuns)..where(
            (entry) => entry.id.equals(operationId) & entry.resultJson.isNull(),
          ))
          .write(
            WorkspaceVerificationRunsCompanion(
              resultJson: .new(jsonEncode(result.toJson())),
            ),
          );
}

ScopedVerificationSettings _nextSettingsRevision(
  ScopedVerificationSettings settings,
  int currentRevision,
) => ScopedVerificationSettings.decode(
  jsonEncode({...settings.toJson(), 'revision': currentRevision + 1}),
);

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
