import 'dart:convert';
import 'dart:math';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class const ScopedVerificationReservation({
  final String? operationId,
  final ScopedVerificationResult? result,
  final int repairAttemptsRemaining = 0,
}) {
  bool get shouldRun => operationId != null && result == null;
}

typedef VerificationReservationRequest = ({
  String workspaceId, String turnId, String toolCallId,
  int configRevision, int maxRepairAttempts,
});

/// Used only inside the repository's SQLite transaction.
class const WorkspaceVerificationReservations(
  final AppDatabase database,
  final String sessionId,
  final Future<ScopedVerificationSettings> Function(String workspaceId) getSettings,
) {
  Future<ScopedVerificationReservation> reserve(VerificationReservationRequest request) async {
    if (!await isLocalVerificationWorkspace(database, request.workspaceId)) {
      return _noRun('unsupported_workspace', outcome: .skipped);
    }
    if (!await _validTurn(request)) return _noRun('invalid_turn');
    final rows = await _recoverRows(request);
    final matches = rows.where((row) => row.toolCallId == request.toolCallId);
    if (matches.isNotEmpty) {
      final existing = matches.first;
      return ScopedVerificationReservation(result: existing.resultJson == null
        ? verificationUnavailable('verification_in_progress')
        : decodeVerificationResult(existing.resultJson!));
    }
    final settings = await getSettings(request.workspaceId);
    if (!settings.enabled) return _noRun('disabled', outcome: .skipped);
    if (settings.revision != request.configRevision) return _noRun('configuration_changed');
    if (rows.any((row) => row.resultJson == null)) return _noRun('verification_in_progress');
    final results = rows.map((row) => decodeVerificationResult(row.resultJson!)).toList();
    if (results.any((result) => result.outcome == .incomplete || result.outcome == .cancelled)) {
      return _noRun('unreconciled_check');
    }
    final limit = rows.isEmpty ? min(request.maxRepairAttempts, settings.maxRepairAttempts)
      : min(rows.first.repairLimit, settings.maxRepairAttempts);
    if (limit < 0 || limit > ScopedVerificationLimits.maxRepairAttempts) {
      return _noRun('invalid_repair_limit');
    }
    final used = rows.where((row) => row.isRepair).length;
    final repair = results.isNotEmpty && results.last.outcome == .fail;
    if (repair && used >= limit) return _noRun('repair_limit_reached');

    return await _insert((request: request, ordinal: rows.length, limit: limit, repair: repair, used: used));
  }

  Future<bool> _validTurn(VerificationReservationRequest request) async {
    if (request.toolCallId.isEmpty || request.toolCallId.length > 512) return false;
    final message = await database.messageDao.getMessageById(request.turnId);
    if (message == null || !message.isUser) return false;
    final chat = await (database.select(database.conversations)
      ..where((row) => row.id.equals(message.conversationId))).getSingleOrNull();

    return chat?.workspaceId == request.workspaceId;
  }

  Future<List<WorkspaceVerificationRunRow>> _recoverRows(VerificationReservationRequest request) async {
    final rows = await (database.select(database.workspaceVerificationRuns)
      ..where((row) => row.workspaceId.equals(request.workspaceId) & row.turnId.equals(request.turnId))
      ..orderBy([(row) => OrderingTerm.asc(row.ordinal)])).get();
    for (final row in rows) {
      if (row.resultJson == null && row.sessionId != sessionId) {
        final saved = jsonEncode(verificationUnavailable('interrupted').toJson());
        await (database.update(database.workspaceVerificationRuns)
          ..where((entry) => entry.id.equals(row.id) & entry.resultJson.isNull()))
            .write(WorkspaceVerificationRunsCompanion(resultJson: Value(saved)));
      }
    }

    return await (database.select(database.workspaceVerificationRuns)
      ..where((row) => row.workspaceId.equals(request.workspaceId) & row.turnId.equals(request.turnId))
      ..orderBy([(row) => OrderingTerm.asc(row.ordinal)])).get();
  }

  Future<ScopedVerificationReservation> _insert(({
    VerificationReservationRequest request, int ordinal, int limit, bool repair, int used,
  }) entry) async {
    final id = const Uuid().v4();
    final request = entry.request;
    final _ = await database.into(database.workspaceVerificationRuns).insert(
      WorkspaceVerificationRunsCompanion.insert(
        id: id, workspaceId: request.workspaceId, turnId: request.turnId,
        toolCallId: request.toolCallId, sessionId: sessionId,
        configRevision: request.configRevision, ordinal: entry.ordinal,
        repairLimit: entry.limit, isRepair: entry.repair,
      ),
    );

    return ScopedVerificationReservation(operationId: id, repairAttemptsRemaining: max(0, entry.limit - entry.used - (entry.repair ? 1 : 0)));
  }
}

Future<bool> isLocalVerificationWorkspace(AppDatabase database, String workspaceId) async {
  final row = await database.workspaceDao.getWorkspaceById(workspaceId);

  return row != null && row.type == .local && row.url == null &&
      !(row.cloudAccountId != null && row.cloudWorkspaceId != null);
}

ScopedVerificationResult verificationUnavailable(String reason) => ScopedVerificationResult(outcome: .incomplete, reason: reason);

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

ScopedVerificationReservation _noRun(String reason, {ScopedVerificationOutcome outcome = .incomplete}) => ScopedVerificationReservation(
  result: ScopedVerificationResult(outcome: outcome, reason: reason),
);
