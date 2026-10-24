import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_history_retention.dart';
import 'workspace_trash_access.dart';

typedef HistoryTarget = ({
  WorkspaceResourceKind kind,
  String id,
  int revision,
  String? tableId,
});

class const WorkspaceHistoryContext(
  final Session session,
  final int workspaceId,
  final String userId,
  final Transaction transaction,
) {
  WorkspaceTrashAccess get access =>
      .new(session, workspaceId, userId, transaction);

  Future<WorkspaceResource> current(
    HistoryTarget target, {
    required bool write,
  }) async {
    final locked = await access.lock();
    final current = await _resource(target);
    final allowed = write
        ? await access.writable(locked.member, current)
        : await access.readable(locked.member, current);
    if (!allowed) trashDenied();

    return current;
  }

  Future<List<WorkspaceRevision>> snapshots(WorkspaceResource current) async {
    await WorkspaceHistoryRetention(session, workspaceId, transaction).prune();

    return WorkspaceRevision.db.find(
      session,
      where: (row) => _matches(row, current),
      orderBy: (row) => row.revision,
      transaction: transaction,
    );
  }

  static HistoryTarget target(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      trashInvalid();
    }
    if (decoded is! Map<String, dynamic>) trashInvalid();

    return _target(decoded);
  }

  Future<WorkspaceResource> _resource(HistoryTarget target) async {
    final current = await WorkspaceStateRepository().findResource(
      session,
      workspaceId: workspaceId,
      kind: target.kind,
      resourceId: target.id,
      transaction: transaction,
    );

    return _requireCurrent(current, target);
  }
}

HistoryTarget _target(Map<String, dynamic> data) {
  final id = _id(data['id']);
  final revision = _revision(data['revision']);
  final kind = _kind(data['kind']);

  return (
    kind: kind,
    id: id,
    revision: revision,
    tableId: _tableId(kind, data['tableId']),
  );
}

String _id(Object? value) {
  if (value is! String || value.isEmpty) trashInvalid();

  return value;
}

int _revision(Object? value) {
  if (value is! int || value < 1) trashInvalid();

  return value;
}

WorkspaceResourceKind _kind(Object? value) => switch (value) {
  'record' => .tableRecord,
  'table' => .table,
  _ => trashInvalid(),
};
String? _tableId(WorkspaceResourceKind kind, Object? value) =>
    kind == .tableRecord ? _id(value) : null;
WorkspaceResource _requireCurrent(
  WorkspaceResource? resource,
  HistoryTarget target,
) {
  if (resource == null || resource.deletedAt != null) trashDenied();
  if (target.kind == .tableRecord &&
      trashData(resource)['tableId'] != target.tableId) {
    trashDenied();
  }

  return resource;
}

Expression _matches(WorkspaceRevisionTable row, WorkspaceResource current) =>
    row.workspaceId.equals(current.workspaceId) &
    row.resourceKind.equals(current.resourceKind) &
    row.resourceId.equals(current.resourceId);
