import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_table_access.dart';

class const WorkspaceReferenceVisibility(
  final Session session,
  final WorkspaceMember member,
  final Transaction? transaction,
) {
  Future<WorkspaceResource> record(WorkspaceResource row) async {
    final data = _data(row);
    final table = await _table(data['tableId'] as String);
    if (table == null) return row;
    final values = (data['values'] as Map).cast<String, Object?>();
    final restricted = <String>[];
    for (final column
        in (_data(table)['columns'] as List).cast<Map<String, dynamic>>()) {
      if (column['type'] != 'reference') continue;
      if (await _visible(column['targetTableId'] as String)) continue;
      final id = column['id'] as String;
      values.remove(id);
      restricted.add(id);
    }
    return row.copyWith(
      data: jsonEncode({
        ...data,
        'values': values,
        'restrictedReferenceColumns': restricted,
      }),
    );
  }

  Future<bool> _visible(String id) async {
    final table = await _table(id);
    if (table == null) return false;
    return await WorkspaceTableAccess(transaction: transaction)
            .visible(session, member, table) !=
        null;
  }

  Future<WorkspaceResource?> _table(String id) =>
      WorkspaceStateRepository().findResource(
        session,
        workspaceId: member.workspaceId,
        kind: .table,
        resourceId: id,
        transaction: transaction,
      );
}

Map<String, dynamic> _data(WorkspaceResource resource) =>
    jsonDecode(resource.data) as Map<String, dynamic>;
