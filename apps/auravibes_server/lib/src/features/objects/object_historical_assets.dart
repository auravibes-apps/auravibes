import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_state/workspace_table_access.dart';

/// Only capture-time attachment provenance can retain or authorize an asset.
class const ObjectHistoricalAssets(
  final Session session,
  final int workspaceId,
  final Transaction? transaction,
) {
  Future<bool> retained(int objectId) async =>
      (await _snapshots()).any((row) => _contains(row, '$objectId'));

  Future<bool> readable(
    int objectId,
    WorkspaceMember member, {
    Set<String>? targetReaders,
  }) async {
    for (final snapshot in await _snapshots()) {
      if (!_contains(snapshot, '$objectId')) continue;
      final table = await _table(snapshot);
      if (table == null) continue;
      if (!_audienceFits(table, targetReaders)) continue;
      if (await WorkspaceTableAccess(transaction: transaction)
          .canReadTable(session, member, table)) {
        return true;
      }
    }
    return false;
  }

  Future<List<WorkspaceRevision>> _snapshots() => WorkspaceRevision.db.find(
    session,
    where: (row) =>
        row.workspaceId.equals(workspaceId) & row.revision.notEquals(0),
    transaction: transaction,
  );

  Future<WorkspaceResource?> _table(WorkspaceRevision snapshot) {
    final id = snapshot.resourceKind == .table
        ? snapshot.resourceId
        : _data(snapshot.data)['tableId'] as String?;

    return WorkspaceResource.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) &
          row.resourceKind.equals(.table) &
          row.resourceId.equals(id) &
          row.deletedAt.equals(null),
      transaction: transaction,
    );
  }
}

bool _audienceFits(WorkspaceResource table, Set<String>? targetReaders) {
  if (targetReaders == null) return true;
  final grants = _data(table.data)['memberAccess'];
  final readers = grants is Map
      ? grants.keys.cast<String>().toSet()
      : <String>{};

  return targetReaders.difference(readers).isEmpty;
}

bool _contains(WorkspaceRevision snapshot, String id) {
  final data = _data(snapshot.data);
  if (snapshot.resourceKind == .table) return _defaultContains(data, id);
  final columns = data['historyAttachmentColumns'];
  final values = data['values'];
  if (columns is! List || values is! Map) return false;

  return columns.whereType<String>().any(
    (column) => _includes(values[column], id),
  );
}

bool _defaultContains(Map<String, dynamic> data, String id) {
  final columns = data['columns'];
  if (columns is! List) return false;

  return columns.whereType<Map>().any(
    (column) =>
        column['type'] == 'attachment' && _includes(column['defaultValue'], id),
  );
}

bool _includes(Object? value, String id) => value is List && value.contains(id);
Map<String, dynamic> _data(String value) =>
    jsonDecode(value) as Map<String, dynamic>;
