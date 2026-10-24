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
