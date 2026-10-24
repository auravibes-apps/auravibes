import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceTrashViewStore(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<void> tombstone(String id, DateTime? time, String? parentId) async {
    final row = await _row(id);
    final data = _data(row, parentId);
    final changed = await _update(row).write(_change(row, data, time));
    if (changed != 1) throw const WorkspaceTableException(conflict: true);
  }

  Future<WorkspaceViewRow> _row(String id) =>
      (database.select(database.workspaceViews)..where(
            (row) => row.workspaceId.equals(workspaceId) & row.id.equals(id),
          ))
          .getSingle();
  UpdateStatement<$WorkspaceViewsTable, WorkspaceViewRow> _update(
    WorkspaceViewRow current,
  ) => database.update(database.workspaceViews)
    ..where(
      (row) =>
          row.workspaceId.equals(workspaceId) &
          row.id.equals(current.id) &
          row.revision.equals(current.revision),
    );
}

Map<String, dynamic> _data(WorkspaceViewRow row, String? parentId) =>
    (jsonDecode(row.data) as Map<String, dynamic>)
      ..addAll({'parentId': parentId, 'revision': row.revision + 1});
WorkspaceViewsCompanion _change(
  WorkspaceViewRow row,
  Map<String, dynamic> data,
  DateTime? time,
) => .new(
  deletedAt: .new(time),
  updatedAt: .new(DateTime.now()),
  revision: .new(row.revision + 1),
  data: .new(jsonEncode(data)),
  history: .new(_history(row, data, time)),
);
String _history(
  WorkspaceViewRow row,
  Map<String, dynamic> data,
  DateTime? time,
) {
  final snapshots = jsonDecode(row.history) as List<dynamic>;
  if (time == null) snapshots.add(data);

  return jsonEncode(snapshots);
}
