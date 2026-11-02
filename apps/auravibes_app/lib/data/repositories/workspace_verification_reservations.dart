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

/// Used only inside the repository's SQLite transaction.
class const WorkspaceVerificationReservations(
  final AppDatabase database,
  final String sessionId,
  final Future<ScopedVerificationSettings> Function(String workspaceId)
  getSettings,
) {
  Future<ScopedVerificationReservation> reserve(
    VerificationReservationRequest request,
  ) async {
    if (!await isLocalVerificationWorkspace(database, request.workspaceId)) {
      return _noRun('unsupported_workspace', outcome: .skipped);
    }
    if (!await _validTurn(request)) return _noRun('invalid_turn');
    final rows = await _recoverRows(request);
    final existing = _existingReservation(rows, request.toolCallId);
    if (existing != null) {
      return existing;
    }
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
    if (request.toolCallId.isEmpty || request.toolCallId.length > 512) {
      return false;
    }
    final message = await database.messageDao.getMessageById(request.turnId);
    if (message == null || !message.isUser) return false;
    final chat = await (database.select(
      database.conversations,
    )..where((row) => row.id.equals(message.conversationId))).getSingleOrNull();

    return chat?.workspaceId == request.workspaceId;
  }

  Future<List<WorkspaceVerificationRunRow>> _recoverRows(
    VerificationReservationRequest request,
  ) async {
    final rows = await _queryRows(request);
    for (final row in rows) {
      await _recoverInterruptedRow(row);
    }

    return await _queryRows(request);
  }

  Future<ScopedVerificationReservation> _insert(
    ({
      VerificationReservationRequest request,
      int ordinal,
      int limit,
      bool repair,
      int used,
    })
    entry,
  ) async {
    final id = const Uuid().v4();
    final request = entry.request;
    final _ = await database
        .into(database.workspaceVerificationRuns)
        .insert(
          WorkspaceVerificationRunsCompanion.insert(
            id: id,
            workspaceId: request.workspaceId,
            turnId: request.turnId,
            toolCallId: request.toolCallId,
            sessionId: sessionId,
            configRevision: request.configRevision,
            ordinal: entry.ordinal,
            repairLimit: entry.limit,
            isRepair: entry.repair,
          ),
        );

    return (
      operationId: id,
      result: null,
      repairAttemptsRemaining: max(
        0,
        entry.limit - entry.used - (entry.repair ? 1 : 0),
      ),
      shouldRun: true,
    );
  }

  Future<List<WorkspaceVerificationRunRow>> _queryRows(
    VerificationReservationRequest request,
  ) =>
      (database.select(database.workspaceVerificationRuns)
            ..where(
              (row) =>
                  row.workspaceId.equals(request.workspaceId) &
                  row.turnId.equals(request.turnId),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.ordinal)]))
          .get();

  Future<void> _recoverInterruptedRow(WorkspaceVerificationRunRow row) async {
    if (row.resultJson != null || row.sessionId == sessionId) return;
    final saved = jsonEncode(verificationUnavailable('interrupted').toJson());
    final _ =
        await (database.update(database.workspaceVerificationRuns)..where(
              (entry) => entry.id.equals(row.id) & entry.resultJson.isNull(),
            ))
            .write(WorkspaceVerificationRunsCompanion(resultJson: .new(saved)));
  }
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
        ? verificationUnavailable('verification_in_progress')
        : decodeVerificationResult(saved),
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
    .map((row) => decodeVerificationResult(row.resultJson ?? ''))
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
  if (blocked != null) {
    return (limit: 0, repair: false, used: 0, result: blocked);
  }
  final results = rows
      .map((row) => decodeVerificationResult(row.resultJson ?? ''))
      .toList();
  final limit = min(
    rows.firstOrNull?.repairLimit ?? request.maxRepairAttempts,
    settings.maxRepairAttempts,
  );
  final used = rows.where((row) => row.isRepair).length;
  final repair = results.isNotEmpty && results.last.outcome == .fail;
  final result = repair && used >= limit
      ? _noRun('repair_limit_reached')
      : null;

  return (limit: limit, repair: repair, used: used, result: result);
}

Future<bool> isLocalVerificationWorkspace(
  AppDatabase database,
  String workspaceId,
) async {
  final row = await database.workspaceDao.getWorkspaceById(workspaceId);

  return row != null &&
      row.type == .local &&
      row.url == null &&
      !(row.cloudAccountId != null && row.cloudWorkspaceId != null);
}

ScopedVerificationResult verificationUnavailable(String reason) =>
    ScopedVerificationResult(outcome: .incomplete, reason: reason);

ScopedVerificationResult decodeVerificationResult(String source) {
  try {
    return ScopedVerificationResult.fromJson(jsonDecode(source));
  } on FormatException {
    return verificationUnavailable('invalid_saved_result');
  }
}

int verificationRepairsRemaining(List<WorkspaceVerificationRunRow> rows) {
  if (rows.isEmpty) return 0;
  final limit = rows.map((row) => row.repairLimit).reduce(min);

  return max(0, limit - rows.where((row) => row.isRepair).length);
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
