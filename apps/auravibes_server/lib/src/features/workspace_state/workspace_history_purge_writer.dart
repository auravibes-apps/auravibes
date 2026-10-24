import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_store.dart';

class const WorkspaceHistoryPurgeWriter(final WorkspaceTrashStore store) {
  Future<void> delete(WorkspaceResource resource) async {
    if (resource.deletedAt == null) trashConflict();
    if (resource.resourceKind == .view) {
      await _view(resource);
    } else {
      final _ = await WorkspaceResource.db.deleteRow(
        store.session,
        resource,
        transaction: store.transaction,
      );
    }
    await _history(resource);
  }

  Future<void> _view(WorkspaceResource resource) async {
    final view = await WorkspaceView.db.findById(
      store.session,
      _id(resource),
      transaction: store.transaction,
    );
    if (view == null) trashConflict();
    final _ = await WorkspaceView.db.deleteRow(
      store.session,
      view,
      transaction: store.transaction,
    );
  }

  Future<void> _history(WorkspaceResource resource) async {
    final key = _HistoryKey(resource);
    final _ = await WorkspaceRevision.db.deleteWhere(
      store.session,
      where: key.matches,
      transaction: store.transaction,
    );
    final _ = await WorkspaceRevision.db.insertRow(
      store.session,
      _marker(resource),
      transaction: store.transaction,
    );
  }
}

class const _HistoryKey(final WorkspaceResource resource) {
  Expression matches(WorkspaceRevisionTable row) =>
      row.workspaceId.equals(resource.workspaceId) &
      row.resourceKind.equals(resource.resourceKind) &
      row.resourceId.equals(resource.resourceId);
}

int _id(WorkspaceResource resource) => resource.id ?? trashConflict();
WorkspaceRevision _marker(WorkspaceResource resource) => WorkspaceRevision(
  workspaceId: resource.workspaceId,
  resourceKind: resource.resourceKind,
  resourceId: resource.resourceId,
  revision: 0,
  data: '{}',
  capturedAt: DateTime.now().toUtc(),
);
