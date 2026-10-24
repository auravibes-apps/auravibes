import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'usecases/workspace_state_usecases.dart';
import 'workspace_reference_visibility.dart';
import 'workspace_table_access.dart';
import 'workspace_trash_access.dart';

class const WorkspaceHistoryService(
  final Session session,
  final int workspaceId,
  final String userId,
) {
  Future<List<String>> history(String targetJson) =>
      session.db.transaction((transaction) async {
        final current = await _current(targetJson, transaction, write: false);
        final snapshots = await WorkspaceRevision.db.find(
          session,
          where: (row) =>
              row.workspaceId.equals(workspaceId) &
              row.resourceKind.equals(current.resourceKind) &
              row.resourceId.equals(current.resourceId),
          orderBy: (row) => row.revision,
          transaction: transaction,
        );
        final access = WorkspaceTrashAccess(
          session,
          workspaceId,
          userId,
          transaction,
        );
        final locked = await access.lock();
        final result = <String>[];
        for (final snapshot in snapshots.reversed) {
          final data = await _visible(snapshot, locked.member, transaction);
          result.add(jsonEncode({'revision': snapshot.revision, 'data': data}));
        }
        return result;
      });

  Future<void> restore(
    String targetJson,
    int revision,
    String requestId,
  ) async {
    final operation = await session.db.transaction((transaction) async {
      final current = await _current(targetJson, transaction, write: true);
      final snapshot = await WorkspaceRevision.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspaceId) &
            row.resourceKind.equals(current.resourceKind) &
            row.resourceId.equals(current.resourceId) &
            row.revision.equals(revision),
        transaction: transaction,
      );
      if (snapshot == null) trashInvalid();
      final data = jsonDecode(current.data) as Map<String, dynamic>;
      final saved = jsonDecode(snapshot.data) as Map<String, dynamic>;
      if (current.resourceKind == .tableRecord) {
        data['values'] = saved['values'];
      } else {
        data['columns'] = saved['columns'];
        data['schemaRevision'] = (data['schemaRevision'] as int) + 1;
      }
      return WorkspacePatchOperation(
        fieldMask: const [],
        operation: .update,
        resourceKind: current.resourceKind,
        resourceId: current.resourceId,
        expectedRevision: _target(targetJson)['revision'] as int,
        data: jsonEncode(data),
      );
    });
    final _ = await WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
      session,
      userId: userId,
      request: PatchWorkspaceStateRequest(
        workspaceId: workspaceId,
        requestId: requestId,
        operations: [operation],
      ),
    );
  }

  Future<Map<String, dynamic>> _visible(
    WorkspaceRevision snapshot,
    WorkspaceMember member,
    Transaction transaction,
  ) async {
    final data = jsonDecode(snapshot.data) as Map<String, dynamic>;
    if (snapshot.resourceKind == .table) {
      final projected =
          await WorkspaceReferenceVisibility(
            session,
            member,
            transaction,
          ).table(
            WorkspaceResource(
              workspaceId: workspaceId,
              resourceKind: .table,
              resourceId: snapshot.resourceId,
              data: snapshot.data,
              revision: snapshot.revision,
              createdAt: snapshot.capturedAt,
              updatedAt: snapshot.capturedAt,
            ),
          );
      return _publicData(.table, projected.data);
    }
    final values = data['values'] as Map<String, dynamic>;
    final targets = data['historyReferenceTargets'] as Map<String, dynamic>?;
    if (targets == null) trashInvalid();
    for (final entry in targets.entries) {
      final table = await WorkspaceStateRepository().findResource(
        session,
        workspaceId: workspaceId,
        kind: .table,
        resourceId: entry.value as String,
        transaction: transaction,
      );
      if (table == null ||
          !await WorkspaceTableAccess(transaction: transaction)
              .canReadTable(session, member, table, includeDeleted: true))
        values.remove(entry.key);
    }
    return {'tableId': data['tableId'], 'values': values};
  }

  Future<WorkspaceResource> _current(
    String targetJson,
    Transaction transaction, {
    required bool write,
  }) async {
    final target = _target(targetJson);
    final access = WorkspaceTrashAccess(
      session,
      workspaceId,
      userId,
      transaction,
    );
    final locked = await access.lock();
    final kind = target['kind'] == 'record'
        ? WorkspaceResourceKind.tableRecord
        : WorkspaceResourceKind.table;
    final current = await WorkspaceStateRepository().findResource(
      session,
      workspaceId: workspaceId,
      kind: kind,
      resourceId: target['id'] as String,
      transaction: transaction,
    );
    if (current == null || current.deletedAt != null) trashDenied();
    if (kind == .tableRecord &&
        trashData(current)['tableId'] != target['tableId']) {
      trashDenied();
    }
    final allowed = write
        ? await access.writable(locked.member, current)
        : await access.readable(locked.member, current);
    if (!allowed) trashDenied();
    return current;
  }
}

Map<String, dynamic> _target(String encoded) {
  try {
    final target = jsonDecode(encoded) as Map<String, dynamic>;
    if (!{'record', 'table'}.contains(target['kind']) ||
        target['id'] is! String ||
        target['revision'] is! int) {
      trashInvalid();
    }
    return target;
  } on FormatException {
    trashInvalid();
  }
}

Map<String, dynamic> _publicData(WorkspaceResourceKind kind, String encoded) {
  final data = jsonDecode(encoded) as Map<String, dynamic>;
  if (kind == .tableRecord) {
    return {'tableId': data['tableId'], 'values': data['values']};
  }
  return {
    'columns': data['columns'],
    'schemaRevision': data['schemaRevision'],
    'labelColumnId': data['labelColumnId'],
  };
}
