import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../objects/object_asset_release.dart';
import 'workspace_history_receipts.dart';
import 'workspace_trash_access.dart';

class const WorkspaceHistoryRetention(
  final Session session,
  final int workspaceId,
  final Transaction transaction,
) {
  static const resourceId = 'history-retention';

  static void validate(Object? days) {
    if (days != null && (days is! int || days < 1 || days > 9007199254740991)) {
      trashInvalid();
    }
  }

  Future<WorkspaceResource?> policy() => WorkspaceResource.db.findFirstRow(
    session,
    where: (row) => _policy(row, workspaceId),
    transaction: transaction,
  );

  Future<void> prune() async {
    final current = await policy();
    if (current == null || current.deletedAt != null) return;
    final days = (jsonDecode(current.data) as Map<String, dynamic>)['days'];
    validate(days);
    await apply(days as int?);
  }

  Future<void> apply(int? days) async {
    validate(days);
    if (days == null) return;
    await _prune(days);
    await WorkspaceHistoryReceipts(
      session,
      workspaceId,
      transaction,
    ).expire(days);
  }

  Future<void> _prune(int days) async {
    final now = DateTime.now().toUtc();
    final expired = await _expired(now, days);
    if (expired.isEmpty) return;
    await ObjectAssetRelease(
      session,
      workspaceId,
      transaction,
    ).mutate(() => _deleteRows(expired));
  }

  Future<void> _deleteRows(Iterable<WorkspaceRevision> expired) async {
    for (final row in expired) {
      final _ = await WorkspaceRevision.db.deleteRow(
        session,
        row,
        transaction: transaction,
      );
    }
  }

  Future<Iterable<WorkspaceRevision>> _expired(DateTime now, int days) async =>
      (await _snapshots()).where(
        (row) => now.difference(row.capturedAt).inDays >= days,
      );

  Future<List<WorkspaceRevision>> _snapshots() => WorkspaceRevision.db.find(
    session,
    where: (row) => row.workspaceId.equals(workspaceId) & (row.revision > 0),
    transaction: transaction,
  );
}

Expression _policy(WorkspaceResourceTable row, int workspaceId) =>
    row.workspaceId.equals(workspaceId) &
    row.resourceKind.equals(.workspaceSetting) &
    row.resourceId.equals(WorkspaceHistoryRetention.resourceId);
