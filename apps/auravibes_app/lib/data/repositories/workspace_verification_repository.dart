import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_reservations.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

export 'workspace_verification_reservations.dart'
    show ScopedVerificationReservation, VerificationReservationRequest;

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

  Future<ScopedVerificationReservation> reserve(
    VerificationReservationRequest request,
  ) => database.transaction(
    () => WorkspaceVerificationReservations(
      database,
      _sessionId,
      getSettings,
    ).reserve(request),
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
  await _requireLocalSettingsOwner(request);
  final current = await request.getSettings(request.workspaceId);
  await _persistNextSettings(request, current);
}

Future<void> _requireLocalSettingsOwner(_SaveWorkspaceSettings request) async {
  final database = request.database;
  final workspaceId = request.workspaceId;
  if (!await isLocalVerificationWorkspace(database, workspaceId)) {
    throw const WorkspaceTableException(denied: true);
  }
}

Future<void> _persistNextSettings(
  _SaveWorkspaceSettings request,
  ScopedVerificationSettings current,
) async {
  final requested = request.settings;
  if (current.revision != requested.revision) {
    throw const WorkspaceTableException(conflict: true);
  }
  final next = _nextSettingsRevision(requested, current.revision);
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
  final row = await _verificationRun(request);
  if (row == null) return verificationUnavailable('workspace_unavailable');

  return await _completeRunForCurrentSession(request, row);
}

Future<WorkspaceVerificationRunRow?> _verificationRun(
  _CompleteWorkspaceVerification request,
) async {
  final database = request.database;
  final query = database.select(database.workspaceVerificationRuns)
    ..where((row) => row.id.equals(request.operationId));

  return await query.getSingleOrNull();
}

Future<ScopedVerificationResult> _completeRunForCurrentSession(
  _CompleteWorkspaceVerification request,
  WorkspaceVerificationRunRow row,
) async {
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
  final safe = _resultAuthorizedBySettings(request, row, settings);
  final rows = await _runsForTurn(request.database, row);
  final remaining = verificationRepairsRemaining(rows);

  return _resultWithRepairAuthority(safe, remaining);
}

ScopedVerificationResult _resultAuthorizedBySettings(
  _CompleteWorkspaceVerification request,
  WorkspaceVerificationRunRow row,
  ScopedVerificationSettings settings,
) => settings.enabled && settings.revision == row.configRevision
    ? request.result
    : verificationUnavailable('configuration_changed');

Future<List<WorkspaceVerificationRunRow>> _runsForTurn(
  AppDatabase database,
  WorkspaceVerificationRunRow row,
) async {
  final query = database.select(database.workspaceVerificationRuns)
    ..where(
      (entry) =>
          entry.workspaceId.equals(row.workspaceId) &
          entry.turnId.equals(row.turnId),
    );

  return await query.get();
}

ScopedVerificationResult _resultWithRepairAuthority(
  ScopedVerificationResult result,
  int remaining,
) => ScopedVerificationResult.fromJson({
  ...result.toJson(),
  'repairAttemptsRemaining': remaining,
  'repairAllowed': result.outcome == .fail && remaining > 0,
});

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
