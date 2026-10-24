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
      if (column['defaultValue'] != null) {
        await _column(column, {
          column['id'] as String: column['defaultValue'],
        }, const {});
      }
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
    final change = (column: column, values: values, previous: previous);
    if (await _preserve(change) || _added(change).isEmpty) return;
    await _target(_targetId(change));
    for (final id in _added(change)) {
      await _checkRecord(_targetId(change), id);
    }
  }

  Future<bool> _preserve(_ColumnChange change) async {
    if (_oldIds(change).isEmpty || await _canRead(_targetId(change)))
      return false;
    _retain(change);

    return true;
  }

  Future<void> _checkRecord(String tableId, String id) async {
    final record = await _resource(.tableRecord, id);
    if (record == null ||
        record.deletedAt != null ||
        _data(record)['tableId'] != tableId) {
      throw const FormatException();
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
    if (visible == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.permissionDenied,
      );
    }

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

typedef _ColumnChange = ({
  Map<String, Object?> column,
  Map<String, Object?> values,
  Map<String, Object?> previous,
});
String _columnId(_ColumnChange change) => change.column['id'] as String;
String _targetId(_ColumnChange change) =>
    change.column['targetTableId'] as String;
List<String> _oldIds(_ColumnChange change) =>
    _ids(change.previous[_columnId(change)]);
Iterable<String> _added(_ColumnChange change) {
  final old = _oldIds(change);
  return _ids(change.values[_columnId(change)])
      .where((id) => !old.contains(id));
}

void _retain(_ColumnChange change) {
  final id = _columnId(change);
  final values = change.values;
  final previous = change.previous;
  if (values.containsKey(id) &&
      jsonEncode(values[id]) != jsonEncode(previous[id])) {
    throw CloudWorkspaceException(code: .permissionDenied);
  }
  values[id] = previous[id];
}
