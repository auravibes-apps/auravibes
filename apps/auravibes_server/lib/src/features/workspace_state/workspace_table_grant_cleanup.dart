import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_revision_capture.dart';

class const WorkspaceTableGrantCleanup(
  final Session _session,
  final Transaction _transaction,
) {
  Future<void> remove(WorkspaceMember member, DateTime now) async {
    final tables = await WorkspaceResource.db.find(
      _session,
      where: (row) => _workspaceTables(row, member.workspaceId),
      transaction: _transaction,
    );
    for (final table in tables) {
      await _remove(table, (userId: member.userId, now: now));
    }
  }

  Future<void> _remove(
    WorkspaceResource table,
    ({String userId, DateTime now}) removal,
  ) async {
    final data = _withoutGrant(table, removal.userId);
    if (data == null) return;
    await WorkspaceRevisionCapture(_session, _transaction).save(table);
    final updated = await WorkspaceResource.db.updateRow(
      _session,
      _updatedTable(table, data, removal.now),
      transaction: _transaction,
    );
    await WorkspaceRevisionCapture(_session, _transaction).save(updated);
  }
}

Expression _workspaceTables(WorkspaceResourceTable row, int workspaceId) =>
    row.workspaceId.equals(workspaceId) &
    row.resourceKind.equals(WorkspaceResourceKind.table);

Map<String, dynamic>? _withoutGrant(WorkspaceResource table, String userId) {
  final data = jsonDecode(table.data) as Map<String, dynamic>;
  final grants = data['memberAccess'];
  if (grants is! Map<String, dynamic>) return null;

  return grants.remove(userId) == null ? null : data;
}

WorkspaceResource _updatedTable(
  WorkspaceResource table,
  Map<String, dynamic> data,
  DateTime now,
) => table.copyWith(
  data: jsonEncode(data),
  revision: table.revision + 1,
  updatedAt: now,
);
