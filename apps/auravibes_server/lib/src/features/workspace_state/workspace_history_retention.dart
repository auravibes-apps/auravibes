import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_trash_access.dart';
import 'workspace_history_receipts.dart';

class const WorkspaceHistoryRetention(final Session session, final int workspaceId, final Transaction transaction) {
  static const resourceId = 'history-retention';

  Future<WorkspaceResource?> policy() => WorkspaceResource.db.findFirstRow(session, where: (row) => _policy(row, workspaceId), transaction: transaction);

  Future<void> prune() async {
    final current = await policy();
    if (current == null || current.deletedAt != null) return;
    final days = (jsonDecode(current.data) as Map<String, dynamic>)['days'];
    validate(days);
    if (days is int) {
      await _prune(days);
      await WorkspaceHistoryReceipts(session, workspaceId, transaction).expire(days);
    }
  }

  Future<void> _prune(int days) async {
    final now = DateTime.now().toUtc();
    final rows = await _snapshots();
    for (final row in rows.where((row) => now.difference(row.capturedAt).inDays >= days)) {
      final _ = await WorkspaceRevision.db.deleteRow(session, row, transaction: transaction);
    }
  }

  Future<List<WorkspaceRevision>> _snapshots() => WorkspaceRevision.db.find(session, where: (row) => row.workspaceId.equals(workspaceId) & (row.revision > 0), transaction: transaction);

  static void validate(Object? days) {
    if (days != null && (days is! int || days < 1 || days > 9007199254740991)) trashInvalid();
  }
}

Expression _policy(WorkspaceResourceTable row, int workspaceId) => row.workspaceId.equals(workspaceId) & row.resourceKind.equals(.workspaceSetting) & row.resourceId.equals(WorkspaceHistoryRetention.resourceId);
