import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_trash_access.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

class const WorkspaceTrashViewStore(
  final Session session,
  final int workspaceId,
  final Transaction transaction,
) {
  Future<List<WorkspaceResource>> resources() async {
    final rows = await WorkspaceView.db.find(
      session,
      where: (row) => row.workspaceId.equals(workspaceId),
      transaction: transaction,
    );
    return rows.map(_resource).toList();
  }

  Future<void> write(WorkspaceResource resource) async {
    final current = await WorkspaceView.db.findById(
      session,
      resource.id!,
      transaction: transaction,
    );
    if (current == null) trashConflict();
    final next = _updated(current, resource);
    final _ = await WorkspaceView.db.updateRow(
      session,
      next,
      transaction: transaction,
    );
  }
}

WorkspaceResource _resource(WorkspaceView view) =>
    _active(view).copyWith(id: view.id, deletedAt: view.deletedAt);
WorkspaceResource _active(WorkspaceView view) => .new(
  workspaceId: view.workspaceId,
  resourceKind: .view,
  resourceId: view.stableId,
  data: view.data,
  revision: view.revision,
  createdAt: _epoch,
  updatedAt: _epoch,
);
WorkspaceView _updated(WorkspaceView current, WorkspaceResource resource) {
  final data = trashData(resource)..['revision'] = resource.revision;
  return current.copyWith(
    data: jsonEncode(data),
    revision: resource.revision,
    deletedAt: resource.deletedAt,
    history: _history(current, resource, data),
  );
}

String _history(
  WorkspaceView current,
  WorkspaceResource resource,
  Map<String, dynamic> data,
) {
  final history = jsonDecode(current.history) as List<dynamic>;
  if (resource.deletedAt == null) history.add(data);
  return jsonEncode(history);
}
