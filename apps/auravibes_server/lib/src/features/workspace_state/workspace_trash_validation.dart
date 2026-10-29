import 'package:auravibes_server/src/features/workspace_state/domain/workspace_table_constraints.dart';
import 'package:auravibes_server/src/features/workspace_state/workspace_trash_access.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_view_validation.dart';
import 'package:auravibes_server/src/generated/protocol.dart';

class const WorkspaceTrashValidation(final List<WorkspaceResource> all) {
  void tables(Set<String> ids) {
    for (final id in ids) {
      _table(id);
    }
  }

  bool dependencies(List<WorkspaceResource> restored) =>
      restored.any(_unresolved);
  void _table(String id) {
    final table = _activeTable(id);
    if (table == null) trashInvalid();
    try {
      WorkspaceTableConstraints.records(
        trashData(table),
        _records(id).map(_values),
      );
    } on FormatException {
      trashInvalid();
    }
  }

  Iterable<WorkspaceResource> _records(String id) => all.where(
    (row) =>
        row.resourceKind == .tableRecord &&
        row.deletedAt == null &&
        trashData(row)['tableId'] == id,
  );
  WorkspaceResource? _activeTable(String id) => all
      .where(
        (row) =>
            row.resourceKind == .table &&
            row.resourceId == id &&
            row.deletedAt == null,
      )
      .firstOrNull;
  bool _unresolved(WorkspaceResource row) => switch (row.resourceKind) {
    .view => _view(row),
    .tableRecord => _record(row),
    _ => false,
  };
  bool _view(WorkspaceResource row) {
    if (trashData(row)['tableId'] == '' &&
        trashData(row)['connected'] != null) {
      return false;
    }
    final table = _activeTable(trashData(row)['tableId'] as String);
    if (table == null) return true;
    try {
      _viewColumns(row, table);
    } on CloudWorkspaceException {
      return true;
    }

    return false;
  }

  void _viewColumns(WorkspaceResource row, WorkspaceResource table) =>
      WorkspaceViewValidation.columns(
        WorkspaceViewValidation.parse(row.data, row.resourceId),
        trashData(table)['columns'] as List<dynamic>,
      );
  bool _record(WorkspaceResource row) {
    final data = trashData(row);
    final table = _activeTable(data['tableId'] as String);
    if (table == null) return true;
    final values = data['values'] as Map;

    return _references(table).any((column) => _missing(column, values));
  }

  bool _missing(Map column, Map values) =>
      _ids(values[column['id']])
          .any((id) => !_activeTarget(all, id, column['targetTableId']));
}

Map<String, Object?> _values(WorkspaceResource row) =>
    (trashData(row)['values'] as Map).cast<String, Object?>();
Iterable<Map> _references(WorkspaceResource table) =>
    (trashData(table)['columns'] as List).cast<Map>().where(
      (column) => column['type'] == 'reference',
    );
Iterable<Object?> _ids(Object? value) => switch (value) {
  final List values => values,
  final String id => [id],
  _ => const [],
};

bool _activeTarget(List<WorkspaceResource> rows, Object? id, Object? tableId) =>
    rows.any((row) => _matchesTarget(row, id, tableId));
bool _matchesTarget(WorkspaceResource row, Object? id, Object? tableId) =>
    row.resourceKind == .tableRecord &&
    row.resourceId == id &&
    row.deletedAt == null &&
    trashData(row)['tableId'] == tableId;
