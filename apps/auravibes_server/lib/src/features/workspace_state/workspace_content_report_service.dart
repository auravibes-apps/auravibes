import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/auth_user_lock.dart';
import 'workspace_history_context.dart';
import 'workspace_history_retention.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_context.dart';
import 'workspace_trash_selection.dart';
import 'workspace_trash_writer.dart';

class const WorkspaceContentReportService(
  final Session session,
  final int workspaceId,
  final String userId,
) {
  Future<String> submit(String targetJson, String reportId) async {
    _reportId(reportId);

    return await session.db.transaction((transaction) async {
      await _requireActor(transaction);
      final history = WorkspaceHistoryContext(
        session,
        workspaceId,
        userId,
        transaction,
      );
      await WorkspaceHistoryRetention(
        session,
        workspaceId,
        transaction,
      ).prune();
      final target = WorkspaceHistoryContext.target(targetJson);
      final current = await history.current(target, write: false);
      final snapshot = (await history.snapshots(current))
          .where((row) => row.revision == target.revision)
          .firstOrNull;
      if (snapshot?.aiInvolved != true) trashDenied();

      final existing = await _report(reportId, transaction);
      if (existing != null) {
        if (existing.reporterUserId != userId ||
            existing.resourceId != target.id ||
            existing.revision != target.revision) {
          trashDenied();
        }

        return _receipt(existing);
      }

      final report = WorkspaceContentReport(
        workspaceId: workspaceId,
        reportId: reportId,
        resourceKind: target.kind,
        resourceId: target.id,
        tableId: target.tableId,
        revision: target.revision,
        conversationId: snapshot!.conversationId,
        reporterUserId: userId,
        status: _submitted,
        submittedAt: DateTime.now().toUtc(),
      );
      await WorkspaceContentReport.db.insertRow(
        session,
        report,
        transaction: transaction,
      );

      return _receipt(report);
    });
  }

  Future<List<String>> list() => session.db.transaction((transaction) async {
    await _requireReviewer(transaction);
    await WorkspaceHistoryRetention(session, workspaceId, transaction).prune();
    final reports = await WorkspaceContentReport.db.find(
      session,
      where: (row) => row.workspaceId.equals(workspaceId),
      orderBy: (row) => row.submittedAt.desc(),
      transaction: transaction,
    );

    return reports.map(_reportJson).toList();
  });

  Future<String> resolve(String reportId, String action) async {
    _reportId(reportId);
    if (action != _dismiss && action != _remove) trashInvalid();

    return await session.db.transaction((transaction) async {
      await _requireActor(transaction);
      await _requireReviewer(transaction);
      await WorkspaceHistoryRetention(
        session,
        workspaceId,
        transaction,
      ).prune();
      final report = await _report(reportId, transaction);
      if (report == null) trashDenied();
      final expectedStatus = action == _dismiss ? _dismissed : _removed;
      if (report.status != _submitted) {
        if (report.status == expectedStatus) return _reportJson(report);
        trashConflict();
      }

      if (action == _remove) await _removeReportedContent(report, transaction);
      final resolved = report.copyWith(
        status: expectedStatus,
        reviewerUserId: userId,
        reviewedAt: DateTime.now().toUtc(),
      );
      final updated = await WorkspaceContentReport.db.updateRow(
        session,
        resolved,
        transaction: transaction,
      );

      return _reportJson(updated);
    });
  }

  Future<void> _removeReportedContent(
    WorkspaceContentReport report,
    Transaction transaction,
  ) async {
    final target = _targetJson(report);
    final context = await WorkspaceTrashContext.load(
      session,
      workspaceId,
      userId,
      transaction,
    );
    final selection = await WorkspaceTrashSelection.load(context, target);
    await WorkspaceTrashWriter(context).trash(
      'report-${report.reportId}',
      target,
      await selection.token(),
    );
  }

  Future<void> _requireReviewer(Transaction transaction) async {
    final locked = await WorkspaceTrashAccess(
      session,
      workspaceId,
      userId,
      transaction,
    ).lock();
    if (!const {'owner', 'admin'}.contains(locked.member.role)) trashDenied();
  }

  Future<void> _requireActor(Transaction transaction) async {
    final actor = await const AuthUserLock().lock(
      session,
      userId: userId,
      transaction: transaction,
    );
    if (actor == null) trashDenied();
  }

  Future<WorkspaceContentReport?> _report(
    String reportId,
    Transaction transaction,
  ) => WorkspaceContentReport.db.findFirstRow(
    session,
    where: (row) =>
        row.workspaceId.equals(workspaceId) & row.reportId.equals(reportId),
    transaction: transaction,
  );
}

const _submitted = 'submitted';
const _dismiss = 'dismiss';
const _remove = 'remove';
const _dismissed = 'dismissed';
const _removed = 'removed';

void _reportId(String value) {
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value)) {
    trashInvalid();
  }
}

String _receipt(WorkspaceContentReport report) => jsonEncode({
  'receiptId': report.reportId,
  'status': report.status,
});

String _reportJson(WorkspaceContentReport report) => jsonEncode({
  'reportId': report.reportId,
  'kind': report.resourceKind == .tableRecord ? 'record' : 'table',
  'resourceId': report.resourceId,
  'tableId': report.tableId,
  'revision': report.revision,
  'conversationId': report.conversationId,
  'status': report.status,
  'submittedAt': report.submittedAt.toUtc().toIso8601String(),
  'reviewerUserId': report.reviewerUserId,
  'reviewedAt': report.reviewedAt?.toUtc().toIso8601String(),
});

String _targetJson(WorkspaceContentReport report) => jsonEncode({
  'kind': report.resourceKind == .tableRecord ? 'record' : 'table',
  'id': report.resourceId,
  'tableId': report.tableId,
  'revision': report.revision,
});
