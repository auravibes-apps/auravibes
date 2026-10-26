import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_state/workspace_table_access.dart';
import 'object_asset_references.dart';

/// Only capture-time attachment provenance can retain or authorize an asset.
class const ObjectHistoricalAssets(
  final Session session,
  final int workspaceId,
  final Transaction? transaction,
) {
  Future<Set<String>> ids() async => {
    for (final row in await _snapshots()) ..._references(row),
  };

  Future<bool> retained(int objectId) async =>
      (await ids()).contains('$objectId');

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

  Future<WorkspaceResource?> _table(WorkspaceRevision snapshot) =>
      _currentTable(_tableId(snapshot));

  Future<WorkspaceResource?> _currentTable(String? id) =>
      WorkspaceResource.db.findFirstRow(
        session,
        where: (row) => _matches(row, id),
        transaction: transaction,
      );

  Expression _matches(WorkspaceResourceTable row, String? id) =>
      row.workspaceId.equals(workspaceId) &
      row.resourceKind.equals(.table) &
      row.resourceId.equals(id) &
      row.deletedAt.equals(null);

  static String? _tableId(WorkspaceRevision snapshot) =>
      snapshot.resourceKind == .table
      ? snapshot.resourceId
      : _data(snapshot.data)['tableId'] as String?;
}

bool _audienceFits(WorkspaceResource table, Set<String>? targetReaders) {
  if (targetReaders == null) return true;
  final grants = _data(table.data)['memberAccess'];
  final readers = grants is Map
      ? grants.keys.cast<String>().toSet()
      : <String>{};

  return targetReaders.difference(readers).isEmpty;
}

bool _contains(WorkspaceRevision snapshot, String id) =>
    _references(snapshot).contains(id);

Iterable<String> _references(WorkspaceRevision snapshot) {
  final data = _data(snapshot.data);

  return snapshot.resourceKind == .table
      ? ObjectAssetReferences.defaults(data)
      : ObjectAssetReferences.historicalRecord(data);
}

Map<String, dynamic> _data(String value) =>
    jsonDecode(value) as Map<String, dynamic>;
