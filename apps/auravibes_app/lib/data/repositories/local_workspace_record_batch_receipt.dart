import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_record_batch_receipts.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceRecordBatchReceipt(
  final AppDatabase database,
  final String workspaceId,
) {
  static String digest(List<WorkspaceRecordChange> changes) => sha256
      .convert(utf8.encode(jsonEncode(changes.map(_payload).toList())))
      .toString();
  Future<bool> replayed(String requestId, String digest) async {
    final query = database.select(database.workspaceRecordBatchReceipts)
      ..where((row) => _scope(row, requestId));
    final previous = await query.getSingleOrNull();
    if (previous == null) return false;
    if (previous.digest != digest) {
      throw const WorkspaceTableException(conflict: true);
    }

    return true;
  }

  Future<void> save(String requestId, String digest) async {
    final _ = await database
        .into(database.workspaceRecordBatchReceipts)
        .insert(
          WorkspaceRecordBatchReceiptsCompanion.insert(
            workspaceId: workspaceId,
            requestId: requestId,
            digest: digest,
          ),
        );
  }

  static Map<String, Object?> _payload(WorkspaceRecordChange change) => {
    'id': change.record.id,
    'revision': change.record.revision,
    ...change.toJson(),
  };
  Expression<bool> _scope(WorkspaceRecordBatchReceipts row, String requestId) =>
      row.workspaceId.equals(workspaceId) & row.requestId.equals(requestId);
}
