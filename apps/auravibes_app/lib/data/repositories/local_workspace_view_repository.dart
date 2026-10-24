import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_folders.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_views.dart';
import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceViewRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceViewRepository {
  @override
  Future<List<WorkspaceView>> list({
    String? parentId,
    bool allFolders = false,
  }) async {
    await _authorize(database, workspaceId);
    final rows = await _views(database, workspaceId).get();
    final views = rows.map(_decodeRow);

    return views
        .where((view) => _matches(view, parentId, allFolders: allFolders))
        .toList();
  }

  @override
  Future<WorkspaceView> read(String id) async => _decode((await _row(id)).data);
  @override
  Future<List<WorkspaceView>> history(String id) async =>
      _snapshots((await _row(id)).history);
  @override
  Future<WorkspaceView> save(WorkspaceView view, {required String requestId}) =>
      database.transaction(
        () => _LocalViewWriter(
          database,
          workspaceId,
          view,
          _operation(view, requestId),
        ).save(),
      );

  Future<WorkspaceViewRow> _row(String id) async {
    await _authorize(database, workspaceId);
    final row = await (_views(
      database,
      workspaceId,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (row == null) throw const WorkspaceTableException(denied: true);

    return row;
  }
}

class const _LocalViewWriter(
  final AppDatabase database,
  final String workspaceId,
  final WorkspaceView view,
  final _ViewOperation operation,
) {
  Future<WorkspaceView> save() async {
    await _authorize(database, workspaceId);
    final current = await _current();
    _checkWorkspace(current);
    final replay = _replay(current, operation);
    if (replay != null) return replay;
    _checkRevision(current);
    await _checkParent();

    return await _persist(current);
  }

  Future<WorkspaceViewRow?> _current() => (database.select(
    database.workspaceViews,
  )..where((row) => row.id.equals(view.id))).getSingleOrNull();
  void _checkWorkspace(WorkspaceViewRow? current) {
    if (current != null && current.workspaceId != workspaceId) {
      throw const WorkspaceTableException(denied: true);
    }
  }

  void _checkRevision(WorkspaceViewRow? current) {
    if (current != null && current.workspaceId != workspaceId) {
      throw const WorkspaceTableException(denied: true);
    }
    if ((current?.revision ?? 0) != view.revision) {
      throw const WorkspaceTableException(conflict: true);
    }
  }

  Future<void> _checkParent() async {
    final id = view.parentId;
    if (id == null) return;
    final query = database.select(database.workspaceFolders)
      ..where((row) => _parentMatches(row, id));
    if (await query.getSingleOrNull() == null) {
      throw const WorkspaceTableException();
    }
  }

  Expression<bool> _parentMatches(WorkspaceFolders row, String id) =>
      row.id.equals(id) &
      row.workspaceId.equals(workspaceId) &
      row.deletedAt.isNull();
  Future<WorkspaceView> _persist(WorkspaceViewRow? current) async {
    final next = view.withRevision(view.revision + 1);
    final snapshots = current == null
        ? <WorkspaceView>[]
        : _snapshots(current.history);
    final _ = await database
        .into(database.workspaceViews)
        .insertOnConflictUpdate(
          _companion(next, [...snapshots, next], current),
        );

    return next;
  }

  WorkspaceViewsCompanion _companion(
    WorkspaceView next,
    List<WorkspaceView> snapshots,
    WorkspaceViewRow? current,
  ) => .insert(
    id: Value(next.id),
    workspaceId: workspaceId,
    data: jsonEncode(WorkspaceViewMapper.toJson(next)),
    revision: next.revision,
    mutations: Value(_mutationJson(current, operation, next.revision)),
    history: jsonEncode(snapshots.map(WorkspaceViewMapper.toJson).toList()),
  );
}

SimpleSelectStatement<WorkspaceViews, WorkspaceViewRow> _views(
  AppDatabase database,
  String workspaceId,
) =>
    database.select(database.workspaceViews)
      ..where((row) => row.workspaceId.equals(workspaceId));
WorkspaceView _decode(String source) =>
    WorkspaceViewMapper.fromJson(jsonDecode(source) as Map<String, dynamic>);
List<WorkspaceView> _snapshots(String source) =>
    (jsonDecode(source) as List<dynamic>)
        .map(
          (entry) =>
              WorkspaceViewMapper.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
Future<void> _authorize(AppDatabase database, String workspaceId) async {
  final row = await (database.select(
    database.workspaces,
  )..where((row) => row.id.equals(workspaceId))).getSingleOrNull();
  if (row == null || row.type != .local) {
    throw const WorkspaceTableException(denied: true);
  }
}

WorkspaceView _decodeRow(WorkspaceViewRow row) => _decode(row.data);
bool _matches(
  WorkspaceView view,
  String? parentId, {
  required bool allFolders,
}) => allFolders || view.parentId == parentId;

typedef _ViewOperation = ({String id, String hash});
_ViewOperation _operation(WorkspaceView view, String requestId) => (
  id: requestId,
  hash: sha256
      .convert(utf8.encode(jsonEncode(WorkspaceViewMapper.toJson(view))))
      .toString(),
);
Map<String, dynamic> _mutations(WorkspaceViewRow? row) =>
    row == null ? {} : jsonDecode(row.mutations) as Map<String, dynamic>;
WorkspaceView? _replay(WorkspaceViewRow? row, _ViewOperation operation) {
  if (row == null) return null;
  final receipt = _mutations(row)[operation.id] as Map?;
  if (receipt == null) return null;
  if (receipt['hash'] != operation.hash) {
    throw const WorkspaceTableException(conflict: true);
  }

  return _snapshots(row.history)
      .firstWhere((view) => view.revision == receipt['revision']);
}

String _mutationJson(
  WorkspaceViewRow? row,
  _ViewOperation operation,
  int revision,
) => jsonEncode({
  ..._mutations(row),
  operation.id: {'hash': operation.hash, 'revision': revision},
});
