import 'dart:convert';

import '../../generated/protocol.dart';
import '../objects/object_attachment_projection.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_history_context.dart';
import 'workspace_history_retention.dart';
import 'workspace_reference_visibility.dart';
import 'workspace_table_access.dart';
import 'workspace_trash_access.dart';

class const WorkspaceHistoryReader(final WorkspaceHistoryContext context) {
  Future<List<String>> read(HistoryTarget target) async {
    final current = await context.current(target, write: false);
    await WorkspaceHistoryRetention(
      context.session,
      context.workspaceId,
      context.transaction,
    ).prune();
    final snapshots = await context.snapshots(current);
    final locked = await context.access.lock();

    return await _visible(snapshots.reversed, locked.member);
  }

  Future<List<String>> _visible(
    Iterable<WorkspaceRevision> snapshots,
    WorkspaceMember member,
  ) async {
    final result = <String>[];
    final projection = _HistoryProjection(context, member);
    for (final snapshot in snapshots) {
      result.add(
        jsonEncode({
          'revision': snapshot.revision,
          'data': await projection.data(snapshot),
        }),
      );
    }

    return result;
  }
}

class const _HistoryProjection(
  final WorkspaceHistoryContext context,
  final WorkspaceMember member,
) {
  Future<Map<String, dynamic>> data(WorkspaceRevision snapshot) async {
    if (snapshot.resourceKind == .table) return await _table(snapshot);
    final data = _decode(snapshot.data);
    final values = data['values'] as Map<String, dynamic>;
    await _hideReferences(values, data);
    await _hideAttachments(values, data);

    return {'tableId': data['tableId'], 'values': values};
  }

  Future<Map<String, dynamic>> _table(WorkspaceRevision snapshot) async {
    final visibility = WorkspaceReferenceVisibility(
      context.session,
      member,
      context.transaction,
    );
    final projected = await visibility.table(_resource(snapshot));
    final data = _decode(projected.data);

    return {
      'columns': data['columns'],
      'schemaRevision': data['schemaRevision'],
      'labelColumnId': data['labelColumnId'],
    };
  }

  Future<void> _hideReferences(
    Map<String, dynamic> values,
    Map<String, dynamic> data,
  ) async {
    final targets = data['historyReferenceTargets'];
    if (targets is! Map<String, dynamic>) trashInvalid();
    for (final entry in targets.entries) {
      if (!await _readable(entry.value as String)) values.remove(entry.key);
    }
  }

  Future<bool> _readable(String id) async {
    final table = await _targetTable(id);
    if (table == null) return false;

    return await WorkspaceTableAccess(transaction: context.transaction)
        .canReadTable(context.session, member, table, includeDeleted: true);
  }

  Future<void> _hideAttachments(
    Map<String, dynamic> values,
    Map<String, dynamic> data,
  ) async {
    final columns = data['historyAttachmentColumns'];
    if (columns is! List) return;
    final projection = ObjectAttachmentProjection(
      context.session,
      member,
      context.transaction,
    );
    final hidden = await projection.restricted(
      columns.whereType<String>().map((id) => {'id': id, 'type': 'attachment'}),
      values,
    );
    for (final column in hidden) {
      values.remove(column);
    }
  }

  Future<WorkspaceResource?> _targetTable(String id) =>
      WorkspaceStateRepository().findResource(
        context.session,
        workspaceId: context.workspaceId,
        kind: .table,
        resourceId: id,
        transaction: context.transaction,
      );
}

Map<String, dynamic> _decode(String data) =>
    jsonDecode(data) as Map<String, dynamic>;
WorkspaceResource _resource(WorkspaceRevision snapshot) => WorkspaceResource(
  workspaceId: snapshot.workspaceId,
  resourceKind: .table,
  resourceId: snapshot.resourceId,
  data: snapshot.data,
  revision: snapshot.revision,
  createdAt: snapshot.capturedAt,
  updatedAt: snapshot.capturedAt,
);
