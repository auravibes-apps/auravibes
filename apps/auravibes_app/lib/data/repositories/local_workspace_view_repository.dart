import 'dart:convert';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceViewRepository(final AppDatabase database, final String workspaceId)
    implements WorkspaceViewRepository {
  @override
  Future<List<WorkspaceView>> list({String? parentId}) async {
    await _authorize();
    final rows = await (database.select(database.workspaceViews)..where((row) => row.workspaceId.equals(workspaceId))).get();
    return rows.map((row) => workspaceViewFromJson(jsonDecode(row.data) as Map<String, dynamic>))
      .where((view) => view.parentId == parentId).toList();
  }
  @override
  Future<WorkspaceView> read(String id) async => workspaceViewFromJson(jsonDecode((await _row(id)).data) as Map<String,dynamic>);
  @override
  Future<List<WorkspaceView>> history(String id) async =>
    (jsonDecode((await _row(id)).history) as List<dynamic>)
      .map((entry) => workspaceViewFromJson(entry as Map<String,dynamic>)).toList();

  @override
  Future<WorkspaceView> save(WorkspaceView view) => database.transaction(() async {
    await _authorize();
    final existing = await (database.select(database.workspaceViews)..where((row) => row.id.equals(view.id) & row.workspaceId.equals(workspaceId))).getSingleOrNull();
    if ((existing?.revision ?? 0) != view.revision) throw const WorkspaceTableException(conflict: true);
    if (view.parentId != null) {
      final parent = await (database.select(database.workspaceFolders)..where((row) => row.id.equals(view.parentId!) & row.workspaceId.equals(workspaceId) & row.deletedAt.isNull())).getSingleOrNull();
      if (parent == null) throw const WorkspaceTableException();
    }
    final data = {...workspaceViewJson(view), 'revision': view.revision + 1};
    final snapshots = existing == null ? <dynamic>[] : jsonDecode(existing.history) as List<dynamic>;
    final _ = await database.into(database.workspaceViews).insertOnConflictUpdate(WorkspaceViewsCompanion.insert(
      id: Value(view.id), workspaceId: workspaceId, data: jsonEncode(data), revision: view.revision + 1,
      history: jsonEncode([...snapshots, data])));
    return workspaceViewFromJson(data);
  });

  Future<WorkspaceViewRow> _row(String id) async {
    await _authorize();
    final row = await (database.select(database.workspaceViews)..where((row) => row.id.equals(id) & row.workspaceId.equals(workspaceId))).getSingleOrNull();
    if (row == null) throw const WorkspaceTableException(denied: true);
    return row;
  }
  Future<void> _authorize() async {
    final row = await (database.select(database.workspaces)..where((row) => row.id.equals(workspaceId))).getSingleOrNull();
    if (row == null || row.type != .local) throw const WorkspaceTableException(denied: true);
  }
}
