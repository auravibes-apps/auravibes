import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_table_access.dart';
import 'workspace_dependent_validation.dart';

class const WorkspaceReferenceValidation(
  final WorkspaceStateRepository repository,
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  WorkspaceDependentValidation get dependents =>
      WorkspaceDependentValidation(session, member, transaction);
  Future<void> columns(Map<String, Object?> schema) async {
    final dependent = _DependentReferences(this);
    for (final column in _columns(schema)) {
      await _target(column['targetTableId'] as String);
      await dependent.schema(schema, column);
      await dependent.defaults(schema, column);
    }
  }

  Future<void> values(
    Map<String, Object?> schema,
    Map<String, Object?> values,
    Map<String, Object?> previous,
  ) async {
    for (final column in _columns(schema)) {
      final _ = await _preserve((
        column: column,
        values: values,
        previous: previous,
      ));
    }
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
    if (await _preserve(change)) {
      if (_parentChanged(change)) {
        throw CloudWorkspaceException(code: .permissionDenied);
      }
      return;
    }
    if (_dependencyChanged(change)) {
      await _DependentReferences(this).values(column, values);
    }
    await _checkAdded(change);
  }

  Future<void> _checkAdded(_ColumnChange change) async {
    if (_added(change).isEmpty) return;
    await _target(_targetId(change));
    for (final id in _added(change)) {
      await _checkRecord(_targetId(change), id);
    }
  }

  Future<bool> _preserve(_ColumnChange change) async {
    if (_oldIds(change).isEmpty || await _canRead(_targetId(change))) {
      return false;
    }
    _retain(change);

    return true;
  }

  Future<WorkspaceResource> _checkRecord(String tableId, String id) async {
    final record = await _resource(.tableRecord, id);
    if (record == null ||
        record.deletedAt != null ||
        _data(record)['tableId'] != tableId) {
      throw const FormatException();
    }

    return record;
  }

  Future<bool> _canRead(String id) async {
    final table = await _resource(.table, id);

    return table != null &&
        await WorkspaceTableAccess(transaction: transaction)
            .canReadTable(session, member, table);
  }

  Future<WorkspaceResource> _target(String id) async {
    final table = await _resource(.table, id);
    if (table == null || table.deletedAt != null) throw const FormatException();
    final readable = await WorkspaceTableAccess(transaction: transaction)
        .canReadTable(session, member, table);
    if (!readable) throw CloudWorkspaceException(code: .permissionDenied);

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

bool _parent(Map column) =>
    column['type'] == 'reference' &&
    column['referenceMultiple'] != true &&
    column['dependsOnColumnId'] == null;

bool _parentChanged(_ColumnChange change) {
  final id = change.column['dependsOnColumnId'];

  return id != null && change.values[id] != change.previous[id];
}

bool _dependencyChanged(_ColumnChange change) =>
    change.column['dependsOnColumnId'] != null &&
    (_parentChanged(change) ||
        jsonEncode(change.values[_columnId(change)]) !=
            jsonEncode(change.previous[_columnId(change)]));
Map? _findColumn(Map schema, Object? id) => (schema['columns'] as List)
    .cast<Map>()
    .where((column) => column['id'] == id)
    .firstOrNull;
bool _compatible(Map? parent, Map? match, Object? id) {
  if (parent == null || match == null || parent['id'] == id) return false;

  return _parent(parent) &&
      _parent(match) &&
      parent['targetTableId'] == match['targetTableId'];
}

Map<String, Object?> _defaults(Map schema) => {
  for (final column in (schema['columns'] as List).cast<Map>())
    if (column['defaultValue'] != null)
      column['id'] as String: column['defaultValue'],
};

class const _DependentReferences(
  final WorkspaceReferenceValidation references,
) {
  Future<void> defaults(
    Map<String, Object?> schema,
    Map<String, Object?> column,
  ) async {
    if (column['defaultValue'] == null) return;
    for (final id in _ids(column['defaultValue'])) {
      await references._checkRecord(column['targetTableId'] as String, id);
    }
    final defaults = _defaults(schema);
    if (column['dependsOnColumnId'] != null &&
        defaults.containsKey(column['dependsOnColumnId'])) {
      await values(column, defaults);
    }
  }

  Future<void> schema(
    Map<String, Object?> schema,
    Map<String, Object?> column,
  ) async {
    if (column['dependsOnColumnId'] == null &&
        column['targetMatchColumnId'] == null) {
      return;
    }
    final parent = _findColumn(schema, column['dependsOnColumnId']);
    final target = await references._target(column['targetTableId'] as String);
    final match = _findColumn(_data(target), column['targetMatchColumnId']);
    if (parent == null || !_compatible(parent, match, column['id'])) {
      throw const FormatException();
    }
  }

  Future<void> values(
    Map<String, Object?> column,
    Map<String, Object?> values,
  ) async {
    final ids = _ids(values[column['id']]);
    if (ids.isEmpty) return;
    final parent = values[column['dependsOnColumnId']];
    if (parent is! String) {
      throw CloudWorkspaceException(code: .incompatibleRelationship);
    }
    await _authorize(column);
    for (final id in ids) {
      await _match(column, id, parent);
    }
  }

  Future<void> _authorize(Map<String, Object?> column) async {
    final table = await references._target(column['targetTableId'] as String);
    final match = _findColumn(_data(table), column['targetMatchColumnId']);
    if (match == null) throw const FormatException();
    await references._target(match['targetTableId'] as String);
  }

  Future<void> _match(
    Map<String, Object?> column,
    String id,
    String parent,
  ) async {
    final target = await references._checkRecord(
      column['targetTableId'] as String,
      id,
    );
    final values = _data(target)['values'] as Map;
    if (values[column['targetMatchColumnId']] != parent) {
      throw CloudWorkspaceException(code: .incompatibleRelationship);
    }
  }
}
