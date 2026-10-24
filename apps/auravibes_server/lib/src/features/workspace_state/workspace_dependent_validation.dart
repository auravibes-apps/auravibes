import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_table_access.dart';

/// Checks incoming relationships when a referenced record changes its parent.
class const WorkspaceDependentValidation(
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  Future<void> record(
    String id,
    Map<String, Object?> data,
    WorkspaceResource? previous,
  ) async {
    if (previous == null) return;
    final change = _change(id, data, previous);
    for (final source in await _rows(.table)) {
      await _recordSource(source, change);
    }
  }

  Future<void> schema(String id, Map<String, Object?> schema) async {
    for (final source in await _rows(.table)) {
      await _schemaSource(source, id, schema);
    }
  }

  Future<void> _recordSource(
    WorkspaceResource source,
    _TargetChange change,
  ) async {
    for (final column in _rules(source, change.tableId)) {
      final match = column['targetMatchColumnId'];
      if (change.before[match] == change.after[match]) continue;
      await _readable(source);
      await _records((
        source: source.resourceId,
        column: column,
        id: change.id,
        parent: change.after[match],
      ));
    }
  }

  Future<void> _schemaSource(
    WorkspaceResource source,
    String id,
    Map<String, Object?> schema,
  ) async {
    for (final column in _rules(source, id)) {
      await _readable(source);
      _checkSchema(source, column, schema);
    }
  }

  // Shortcut: Scan workspace rows. Add indexes after #1680 measures capacity.
  Future<List<WorkspaceResource>> _rows(WorkspaceResourceKind kind) =>
      WorkspaceResource.db.find(
        session,
        where: (row) =>
            row.workspaceId.equals(member.workspaceId) &
            row.resourceKind.equals(kind) &
            row.deletedAt.equals(null),
        transaction: transaction,
      );
  Future<void> _readable(WorkspaceResource source) async {
    if (!await WorkspaceTableAccess(transaction: transaction)
        .canReadTable(session, member, source)) {
      throw CloudWorkspaceException(code: .permissionDenied);
    }
  }

  Future<void> _records(_IncomingLink link) async {
    for (final row in await _rows(.tableRecord)) {
      _checkRecord(_data(row), link);
    }
  }
}

typedef _TargetChange = ({String id, String tableId, Map before, Map after});
typedef _IncomingLink = ({
  String source,
  Map column,
  String id,
  Object? parent,
});
_TargetChange _change(String id, Map data, WorkspaceResource previous) => (
  id: id,
  tableId: data['tableId'] as String,
  before: _data(previous)['values'] as Map,
  after: data['values'] as Map,
);
Iterable<Map> _rules(WorkspaceResource source, String target) =>
    (_data(source)['columns'] as List).cast<Map>().where(
      (column) =>
          column['targetTableId'] == target &&
          column['dependsOnColumnId'] != null,
    );
void _checkSchema(WorkspaceResource source, Map column, Map schema) {
  final match = _column(schema, column['targetMatchColumnId']);
  final parent = _column(_data(source), column['dependsOnColumnId']);
  if (parent == null || !_compatible(match, parent)) {
    throw const FormatException();
  }
}

bool _compatible(Map? match, Map parent) =>
    match != null &&
    match['type'] == 'reference' &&
    match['referenceMultiple'] != true &&
    match['dependsOnColumnId'] == null &&
    match['targetTableId'] == parent['targetTableId'];
Map? _column(Map schema, Object? id) => (schema['columns'] as List)
    .cast<Map>()
    .where((column) => column['id'] == id)
    .firstOrNull;
void _checkRecord(Map data, _IncomingLink link) {
  if (data['tableId'] != link.source) return;
  final values = data['values'] as Map;
  if (!_contains(values[link.column['id']], link.id)) return;
  if (link.parent == null ||
      values[link.column['dependsOnColumnId']] != link.parent) {
    throw CloudWorkspaceException(code: .incompatibleRelationship);
  }
}

bool _contains(Object? value, String id) =>
    value == id || (value is List && value.contains(id));
Map<String, dynamic> _data(WorkspaceResource resource) =>
    jsonDecode(resource.data) as Map<String, dynamic>;
