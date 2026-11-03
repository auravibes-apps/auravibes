import 'dart:convert';
import 'dart:math';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

typedef VerificationReservationRequest = ({
  String workspaceId,
  String turnId,
  String toolCallId,
  int configRevision,
  int maxRepairAttempts,
});
typedef ScopedVerificationReservation = ({
  String? operationId,
  ScopedVerificationResult? result,
  int repairAttemptsRemaining,
  bool shouldRun,
});

typedef _ReservationEntry = ({
  VerificationReservationRequest request,
  int ordinal,
  int limit,
  bool repair,
  int used,
});

typedef _ReservationWriteRequest = ({
  AppDatabase database,
  String sessionId,
  _ReservationEntry entry,
  String id,
});

/// Used only inside the repository's SQLite transaction.
class WorkspaceVerificationReservations {
  new(this.database, this.sessionId, this.getSettings)
    : _recovery = _WorkspaceVerificationReservationRecovery(
        database,
        sessionId,
      );

  final AppDatabase database;
  final String sessionId;
  final Future<ScopedVerificationSettings> Function(String workspaceId)
  getSettings;
  final _WorkspaceVerificationReservationRecovery _recovery;

  Future<ScopedVerificationReservation> reserve(
    VerificationReservationRequest request,
  ) async {
    final invalid = await _invalidReservation(request);
    if (invalid != null) return invalid;
    final rows = await _recovery.recoverRows(request);
    final existing = _existingReservation(rows, request.toolCallId);
    if (existing != null) return existing;

    return await _reserveNext(request, rows);
  }

  Future<ScopedVerificationReservation?> _invalidReservation(
    VerificationReservationRequest request,
  ) async {
    final supported =
        await WorkspaceVerificationReservationHelpers.isLocalVerificationWorkspace(
          database,
          request.workspaceId,
        );
    if (!supported) return _noRun('unsupported_workspace', outcome: .skipped);
    if (!await _validTurn(request)) return _noRun('invalid_turn');

    return null;
  }

  Future<ScopedVerificationReservation> _reserveNext(
    VerificationReservationRequest request,
    List<WorkspaceVerificationRunRow> rows,
  ) async {
    final settings = await getSettings(request.workspaceId);
    final plan = _reservationPlan(request, rows, settings);
    if (plan.result case final result?) return result;

    return await _insert((
      request: request,
      ordinal: rows.length,
      limit: plan.limit,
      repair: plan.repair,
      used: plan.used,
    ));
  }

  Future<bool> _validTurn(VerificationReservationRequest request) async {
    if (!_validToolCallId(request.toolCallId)) return false;
    final message = await database.messageDao.getMessageById(request.turnId);
    if (message == null || !message.isUser) return false;

    return await _messageBelongsToWorkspace(message.conversationId, request);
  }

  bool _validToolCallId(String toolCallId) =>
      toolCallId.isNotEmpty && toolCallId.length <= 512;

  Future<bool> _messageBelongsToWorkspace(
    String conversationId,
    VerificationReservationRequest request,
  ) async {
    final chat = await (database.select(
      database.conversations,
    )..where((row) => row.id.equals(conversationId))).getSingleOrNull();

    return chat?.workspaceId == request.workspaceId;
  }

  Future<ScopedVerificationReservation> _insert(_ReservationEntry entry) async {
    final id = const Uuid().v4();
    await _writeReservation(entry, id);

    return _createdReservation(entry, id);
  }

  Future<void> _writeReservation(_ReservationEntry entry, String id) =>
      _persistReservation((
        database: database,
        sessionId: sessionId,
        entry: entry,
        id: id,
      ));

  ScopedVerificationReservation _createdReservation(
    _ReservationEntry entry,
    String id,
  ) => (
    operationId: id,
    result: null,
    repairAttemptsRemaining: max(
      0,
      entry.limit - entry.used - (entry.repair ? 1 : 0),
    ),
    shouldRun: true,
  );
}

class _WorkspaceVerificationReservationRecovery {
  _WorkspaceVerificationReservationRecovery(this.database, this.sessionId);

  final AppDatabase database;
  final String sessionId;

  Future<List<WorkspaceVerificationRunRow>> recoverRows(
    VerificationReservationRequest request,
  ) async {
    final rows = await _queryRows(request);
    for (final row in rows) {
      await _recoverInterruptedRow(row);
    }

    return await _queryRows(request);
  }

  Future<List<WorkspaceVerificationRunRow>> _queryRows(
    VerificationReservationRequest request,
  ) async {
    final query = database.select(database.workspaceVerificationRuns)
      ..where(_reservationRowsFilter(request))
      ..orderBy(_reservationRowsOrder);

    return await query.get();
  }

  Future<void> _recoverInterruptedRow(WorkspaceVerificationRunRow row) async {
    if (row.resultJson != null || row.sessionId == sessionId) return;
    await _markInterrupted(row.id);
  }

  Future<void> _markInterrupted(String runId) async {
    final saved = _interruptedResultJson();
    await _saveInterruptedResult(database, runId, saved);
  }
}

Expression<bool> Function($WorkspaceVerificationRunsTable row)
_reservationRowsFilter(VerificationReservationRequest request) =>
    (row) =>
        row.workspaceId.equals(request.workspaceId) &
        row.turnId.equals(request.turnId);

List<OrderingTerm Function($WorkspaceVerificationRunsTable row)>
_reservationRowsOrder = [(row) => OrderingTerm.asc(row.ordinal)];

String _interruptedResultJson() => jsonEncode(
  WorkspaceVerificationReservationHelpers.verificationUnavailable('interrupted')
      .toJson(),
);

Future<void> _saveInterruptedResult(
  AppDatabase database,
  String runId,
  String saved,
) async {
  final update = database.update(database.workspaceVerificationRuns)
    ..where((entry) => entry.id.equals(runId) & entry.resultJson.isNull());
  final _ = await update.write(
    WorkspaceVerificationRunsCompanion(resultJson: .new(saved)),
  );
}

ScopedVerificationReservation? _existingReservation(
  List<WorkspaceVerificationRunRow> rows,
  String toolCallId,
) {
  final existing = rows
      .where((row) => row.toolCallId == toolCallId)
      .firstOrNull;
  if (existing == null) return null;
  final saved = existing.resultJson;

  return (
    operationId: null,
    result: saved == null
        ? WorkspaceVerificationReservationHelpers.verificationUnavailable(
            'verification_in_progress',
          )
        : WorkspaceVerificationReservationHelpers.decodeVerificationResult(
            saved,
          ),
    repairAttemptsRemaining: 0,
    shouldRun: false,
  );
}

ScopedVerificationReservation? _reservationBlockReason(
  VerificationReservationRequest request,
  List<WorkspaceVerificationRunRow> rows,
  ScopedVerificationSettings settings,
) {
  if (!settings.enabled) return _noRun('disabled', outcome: .skipped);
  if (settings.revision != request.configRevision) {
    return _noRun('configuration_changed');
  }
  if (_hasUnfinishedRun(rows)) return _noRun('verification_in_progress');
  if (_hasUnreconciledResult(rows)) return _noRun('unreconciled_check');
  if (!_validRepairLimit(request, rows, settings)) {
    return _noRun('invalid_repair_limit');
  }

  return null;
}

bool _hasUnfinishedRun(List<WorkspaceVerificationRunRow> rows) =>
    rows.any((row) => row.resultJson == null);

bool _hasUnreconciledResult(List<WorkspaceVerificationRunRow> rows) => rows
    .map(
      (row) => WorkspaceVerificationReservationHelpers.decodeVerificationResult(
        row.resultJson ?? '',
      ),
    )
    .any(
      (result) => result.outcome == .incomplete || result.outcome == .cancelled,
    );

bool _validRepairLimit(
  VerificationReservationRequest request,
  List<WorkspaceVerificationRunRow> rows,
  ScopedVerificationSettings settings,
) {
  final limit = min(
    rows.firstOrNull?.repairLimit ?? request.maxRepairAttempts,
    settings.maxRepairAttempts,
  );

  return limit >= 0 && limit <= ScopedVerificationLimits.maxRepairAttempts;
}

({int limit, bool repair, int used, ScopedVerificationReservation? result})
_reservationPlan(
  VerificationReservationRequest request,
  List<WorkspaceVerificationRunRow> rows,
  ScopedVerificationSettings settings,
) {
  final blocked = _reservationBlockReason(request, rows, settings);
  if (blocked != null) return _blockedReservationPlan(blocked);

  return _availableReservationPlan(request, rows, settings);
}

({int limit, bool repair, int used, ScopedVerificationReservation? result})
_blockedReservationPlan(ScopedVerificationReservation result) =>
    (limit: 0, repair: false, used: 0, result: result);

({int limit, bool repair, int used, ScopedVerificationReservation? result})
_availableReservationPlan(
  VerificationReservationRequest request,
  List<WorkspaceVerificationRunRow> rows,
  ScopedVerificationSettings settings,
) {
  final limit = _repairLimit(request, rows, settings);
  final used = _usedRepairAttempts(rows);
  final repair = _repairIsNeeded(rows);
  final result = _repairBlock(repair: repair, used: used, limit: limit);

  return (limit: limit, repair: repair, used: used, result: result);
}

int _usedRepairAttempts(List<WorkspaceVerificationRunRow> rows) =>
    rows.where((row) => row.isRepair).length;

bool _repairIsNeeded(List<WorkspaceVerificationRunRow> rows) {
  final last = rows.lastOrNull;
  if (last == null || last.resultJson == null) return false;

  return WorkspaceVerificationReservationHelpers.decodeVerificationResult(
        last.resultJson!,
      ).outcome ==
      .fail;
}

ScopedVerificationReservation? _repairBlock({
  required bool repair,
  required int used,
  required int limit,
}) => repair && used >= limit ? _noRun('repair_limit_reached') : null;

int _repairLimit(
  VerificationReservationRequest request,
  List<WorkspaceVerificationRunRow> rows,
  ScopedVerificationSettings settings,
) => min(
  rows.firstOrNull?.repairLimit ?? request.maxRepairAttempts,
  settings.maxRepairAttempts,
);

abstract final class WorkspaceVerificationReservationHelpers {
  static Future<bool> isLocalVerificationWorkspace(
    AppDatabase database,
    String workspaceId,
  ) async {
    final row = await database.workspaceDao.getWorkspaceById(workspaceId);

    return row != null &&
        row.type == .local &&
        row.url == null &&
        !(row.cloudAccountId != null && row.cloudWorkspaceId != null);
  }

  static ScopedVerificationResult verificationUnavailable(String reason) =>
      ScopedVerificationResult(outcome: .incomplete, reason: reason);

  static ScopedVerificationResult decodeVerificationResult(String source) {
    try {
      return ScopedVerificationResult.fromJson(jsonDecode(source));
    } on FormatException {
      return verificationUnavailable('invalid_saved_result');
    }
  }

  static int verificationRepairsRemaining(
    List<WorkspaceVerificationRunRow> rows,
  ) {
    if (rows.isEmpty) return 0;
    final limit = rows.map((row) => row.repairLimit).reduce(min);

    return max(0, limit - rows.where((row) => row.isRepair).length);
  }
}

Future<void> _persistReservation(_ReservationWriteRequest request) async {
  final companion = _reservationCompanion(request);
  final _ = await request.database
      .into(request.database.workspaceVerificationRuns)
      .insert(companion);
}

// This is a direct mapping to the generated Drift insert companion.
// ignore: halstead-volume
WorkspaceVerificationRunsCompanion _reservationCompanion(
  _ReservationWriteRequest request,
) {
  final entry = request.entry;
  final reservation = entry.request;

  return WorkspaceVerificationRunsCompanion.insert(
    id: request.id,
    workspaceId: reservation.workspaceId,
    turnId: reservation.turnId,
    toolCallId: reservation.toolCallId,
    sessionId: request.sessionId,
    configRevision: reservation.configRevision,
    ordinal: entry.ordinal,
    repairLimit: entry.limit,
    isRepair: entry.repair,
  );
}

ScopedVerificationReservation _noRun(
  String reason, {
  ScopedVerificationOutcome outcome = .incomplete,
}) => (
  operationId: null,
  result: .new(outcome: outcome, reason: reason),
  repairAttemptsRemaining: 0,
  shouldRun: false,
);
