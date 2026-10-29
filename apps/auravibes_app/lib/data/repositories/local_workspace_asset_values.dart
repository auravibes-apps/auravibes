import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceAssetValues(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<List<String>> restricted(
    List<WorkspaceColumn> columns,
    Map<String, Object?> values,
  ) async {
    final result = <String>[];
    for (final column in columns.where(
      (column) => column.type == .attachment,
    )) {
      if (await _unavailable(values[column.id])) result.add(column.id);
    }

    return result;
  }

  Future<WorkspaceRecord> project(
    List<WorkspaceColumn> columns,
    WorkspaceRecord record,
  ) async {
    final hidden = await restricted(columns, record.values);

    return WorkspaceRecord(
      id: record.id,
      tableId: record.tableId,
      values: _without(record.values, hidden),
      revision: record.revision,
      restrictedReferenceColumns: _hidden(record, hidden),
    );
  }

  Future<Map<String, dynamic>> history(Map<String, dynamic> data) async {
    final values = data['values'];
    if (values is! Map<String, dynamic>) return await schema(data);
    final hidden = await restricted(_historicalColumns(data), values);

    return Map.of(data)..['values'] = _without(values, hidden);
  }

  Future<Map<String, dynamic>> schema(Map<String, dynamic> data) async {
    final raw = data['columns'];
    if (raw is! List) return data;
    final columns = _parseColumns(raw);
    final hidden = await restricted(columns, _defaults(columns));

    return Map.of(data)..['columns'] = _hideDefaults(raw, hidden);
  }

  Future<List<WorkspaceColumn>> preserveDefaults(
    List<WorkspaceColumn> columns,
    List<WorkspaceColumn> previous,
  ) async {
    final values = _defaults(columns);
    await preserve(columns, values, _defaults(previous));

    return [for (final column in columns) _withDefault(column, values)];
  }

  Future<void> preserve(
    List<WorkspaceColumn> columns,
    Map<String, Object?> values,
    Map<String, Object?> previous,
  ) async {
    for (final id in await restricted(columns, previous)) {
      if (values.containsKey(id) &&
          jsonEncode(values[id]) != jsonEncode(previous[id])) {
        throw const WorkspaceTableException(denied: true);
      }
      values[id] = previous[id];
    }
  }

  static Map<String, Object?> retained(
    List<WorkspaceColumn> columns,
    Map<String, Object?> values,
  ) => {
    for (final column in columns.where((column) => column.type == .attachment))
      if (values.containsKey(column.id)) column.id: values[column.id],
  };

  Future<bool> _unavailable(Object? value) async {
    if (value is! List) return false;
    for (final id in value) {
      if (!await _active(id)) return true;
    }

    return false;
  }

  Future<bool> _active(Object? id) async {
    if (id is! String) return false;
    final asset = await (database.select(
      database.workspaceAssets,
    )..where((row) => _matchesAsset(row, workspaceId, id))).getSingleOrNull();

    return asset != null;
  }
}

Map<String, Object?> _defaults(List<WorkspaceColumn> columns) => {
  for (final column in columns.where((column) => column.type == .attachment))
    if (column.defaultValue != null) column.id: column.defaultValue,
};
WorkspaceColumn _withDefault(
  WorkspaceColumn column,
  Map<String, Object?> values,
) => values.containsKey(column.id)
    ? WorkspaceColumn.fromJson({
        ...column.toJson(),
        'defaultValue': values[column.id],
      })
    : column;

List<WorkspaceColumn> _historicalColumns(Map<String, dynamic> data) {
  final ids = data['historyAttachmentColumns'];
  if (ids is! List) return [];

  return ids
      .whereType<String>()
      .map((id) => WorkspaceColumn(id: id, name: '', type: .attachment))
      .toList();
}

Map<String, Object?> _without(
  Map<String, Object?> values,
  List<String> hidden,
) => Map.of(values)..removeWhere((key, _) => hidden.contains(key));
List<String> _hidden(WorkspaceRecord record, List<String> hidden) =>
    {...record.restrictedReferenceColumns, ...hidden}.toList();
List<WorkspaceColumn> _parseColumns(List<dynamic> raw) =>
    raw.cast<Map<String, dynamic>>().map(WorkspaceColumn.fromJson).toList();
List<Map<String, dynamic>> _hideDefaults(
  List<dynamic> raw,
  List<String> hidden,
) => [
  for (final column in raw.cast<Map<String, dynamic>>())
    if (hidden.contains(column['id'] as String))
      Map.of(column)..remove('defaultValue')
    else
      column,
];
Expression<bool> _matchesAsset(
  $WorkspaceAssetsTable row,
  String workspaceId,
  String id,
) =>
    row.id.equals(id) &
    row.workspaceId.equals(workspaceId) &
    row.status.equals('active');
