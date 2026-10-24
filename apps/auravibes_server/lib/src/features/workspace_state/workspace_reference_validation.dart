import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_table_access.dart';

class const WorkspaceReferenceValidation(
  final WorkspaceStateRepository repository,
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  Future<void> columns(Map<String, Object?> schema) async {
    for (final column in _columns(schema)) {
      await _target(column['targetTableId'] as String);
    }
  }

  Future<void> values(
    Map<String, Object?> schema,
    Map<String, Object?> values,
    Map<String, Object?> previous,
  ) async {
    for (final column in _columns(schema)) {
      await _column(column, values, previous);
    }
  }

  Future<void> _column(
    Map<String, Object?> column,
    Map<String, Object?> values,
    Map<String, Object?> previous,
  ) async {
    final id = column['id'] as String;
    final oldIds = _ids(previous[id]);
    if (oldIds.isNotEmpty &&
        !await _canRead(column['targetTableId'] as String)) {
      values[id] = previous[id];
      return;
    }
    final added = _ids(values[id]).where((id) => !oldIds.contains(id));
    if (added.isEmpty) return;
    final tableId = column['targetTableId'] as String;
    await _target(tableId);
    for (final id in added) {
      final record = await _resource(.tableRecord, id);
      if (record == null ||
          record.deletedAt != null ||
          _data(record)['tableId'] != tableId) {
        throw const FormatException();
      }
    }
  }

  Future<bool> _canRead(String id) async {
    final table = await _resource(.table, id);
    return table != null &&
        await WorkspaceTableAccess(transaction: transaction)
                .visible(session, member, table) !=
            null;
  }

  Future<WorkspaceResource> _target(String id) async {
    final table = await _resource(.table, id);
    if (table == null || table.deletedAt != null) throw const FormatException();
    final visible = await WorkspaceTableAccess(transaction: transaction)
        .visible(session, member, table);
    if (visible == null)
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.permissionDenied,
      );
    return table;
  }

  Future<WorkspaceResource?> _resource(WorkspaceResourceKind kind, String id) =>
      repository.findResource(
        session,
        workspaceId: member.workspaceId,
        kind: kind,
        resourceId: id,
        transaction: transaction,
      );
}

Iterable<Map<String, Object?>> _columns(Map<String, Object?> schema) =>
    (schema['columns'] as List).cast<Map<String, dynamic>>().where(
      (column) => column['type'] == 'reference',
    );

List<String> _ids(Object? value) => switch (value) {
  final String id => [id],
  final List<dynamic> ids => ids.cast<String>(),
  _ => const [],
};

Map<String, Object?> _data(WorkspaceResource row) =>
    (jsonDecode(row.data) as Map).cast<String, Object?>();
