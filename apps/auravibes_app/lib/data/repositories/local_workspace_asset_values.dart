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
      final value = values[column.id];
      if (value is! List) continue;
      for (final id in value) {
        if (!await _active(id)) {
          result.add(column.id);
          break;
        }
      }
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
      values: Map.of(record.values)
        ..removeWhere((key, _) => hidden.contains(key)),
      revision: record.revision,
      restrictedReferenceColumns: {
        ...record.restrictedReferenceColumns,
        ...hidden,
      }.toList(),
    );
  }

  Future<Map<String, dynamic>> history(Map<String, dynamic> data) async {
    final values = data['values'];
    if (values is! Map<String, dynamic>) return await schema(data);
    final hidden = await restricted(_historicalColumns(data), values);

    return Map.of(data)
      ..['values'] = (Map.of(values)
        ..removeWhere((key, _) => hidden.contains(key)));
  }

  Future<Map<String, dynamic>> schema(Map<String, dynamic> data) async {
    final raw = data['columns'];
    if (raw is! List) return data;
    final columns = raw
        .cast<Map<String, dynamic>>()
        .map(WorkspaceColumn.fromJson)
        .toList();
    final hidden = await restricted(columns, _defaults(columns));

    return Map.of(data)
      ..['columns'] = [
        for (final column in raw.cast<Map<String, dynamic>>())
          if (hidden.contains(column['id']))
            Map.of(column)..remove('defaultValue')
          else
            column,
      ];
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

  Future<bool> _active(Object? id) async {
    if (id is! String) return false;
    final asset =
        await (database.select(database.workspaceAssets)..where(
              (row) =>
                  row.workspaceId.equals(workspaceId) &
                  row.id.equals(id) &
                  row.status.equals('active'),
            ))
            .getSingleOrNull();

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

Map<String, Object?> retainedWorkspaceAttachmentValues(
  List<WorkspaceColumn> columns,
  Map<String, Object?> values,
) => {
  for (final column in columns.where((column) => column.type == .attachment))
    if (values.containsKey(column.id)) column.id: values[column.id],
};

List<WorkspaceColumn> _historicalColumns(Map<String, dynamic> data) {
  final ids = data['historyAttachmentColumns'];
  if (ids is! List) return [];

  return ids
      .whereType<String>()
      .map((id) => WorkspaceColumn(id: id, name: '', type: .attachment))
      .toList();
}
