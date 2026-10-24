import 'dart:convert';

import '../../generated/protocol.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_context.dart';

typedef HistoryRetainedData = ({
  Map<String, dynamic> data,
  bool view,
  WorkspaceResourceKind kind,
  String id,
});

class const WorkspaceHistoryRetainedReader(
  final WorkspaceTrashContext context,
) {
  Future<List<HistoryRetainedData>> read(
    List<WorkspaceResource> rows,
    Set<String> scope,
  ) async => [
    ...rows
        .where((row) => !_scoped(scope, row.resourceKind, row.resourceId))
        .map(_resource),
    ...await _snapshots(scope),
    ...await _views(scope),
  ];

  Future<List<HistoryRetainedData>> _snapshots(Set<String> scope) async {
    final store = context.store;
    final snapshots = await WorkspaceRevision.db.find(
      store.session,
      where: (row) => row.workspaceId.equals(store.workspaceId),
      transaction: store.transaction,
    );

    return _retainedSnapshots(snapshots, scope);
  }

  Future<List<HistoryRetainedData>> _views(Set<String> scope) async {
    final store = context.store;
    final rows = await WorkspaceView.db.find(
      store.session,
      where: (row) => row.workspaceId.equals(store.workspaceId),
      transaction: store.transaction,
    );

    return _retainedViews(rows, scope);
  }
}

HistoryRetainedData _resource(WorkspaceResource row) => (
  data: trashData(row),
  view: row.resourceKind == .view,
  kind: row.resourceKind,
  id: row.resourceId,
);
HistoryRetainedData _snapshot(WorkspaceRevision row) => (
  data: jsonDecode(row.data) as Map<String, dynamic>,
  view: false,
  kind: row.resourceKind,
  id: row.resourceId,
);
Iterable<HistoryRetainedData> _viewHistory(WorkspaceView row) =>
    (jsonDecode(row.history) as List).cast<Map<String, dynamic>>().map(
      (data) => (data: data, view: true, kind: .view, id: row.stableId),
    );
bool _scoped(Set<String> scope, WorkspaceResourceKind kind, String id) =>
    scope.contains('${kind == .tableRecord ? 'record' : kind.name}:$id');

List<HistoryRetainedData> _retainedSnapshots(
  List<WorkspaceRevision> rows,
  Set<String> scope,
) => rows
    .where((row) => !_scoped(scope, row.resourceKind, row.resourceId))
    .map(_snapshot)
    .toList();
List<HistoryRetainedData> _retainedViews(
  List<WorkspaceView> rows,
  Set<String> scope,
) => rows
    .where((row) => !scope.contains('view:${row.stableId}'))
    .expand(_viewHistory)
    .toList();
