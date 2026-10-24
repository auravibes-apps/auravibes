import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_state/workspace_table_access.dart';

/// Item reachability never substitutes workspace membership for table grants.
class const ObjectItemAccess(
  final Session session,
  final WorkspaceMember member, {
  final Transaction? transaction,
  final String? excludedRecordId,
  final String? excludedTableId,
}) {
  Future<bool> canRead(int objectId) async {
    final resources = await _resources();
    for (final resource in resources) {
      if (resource.deletedAt != null) continue;
      final data = _data(resource);
      if (resource.resourceKind == .table &&
          resource.resourceId != excludedTableId &&
          _defaultContains(data, '$objectId') &&
          await WorkspaceTableAccess(transaction: transaction)
              .canReadTable(session, member, resource)) {
        return true;
      }
      if (resource.resourceKind == .file && data['assetId'] == '$objectId') {
        return true;
      }
      if (resource.resourceKind != .tableRecord ||
          resource.resourceId == excludedRecordId) {
        continue;
      }
      final table = resources
          .where(
            (row) =>
                row.resourceKind == .table && row.resourceId == data['tableId'],
          )
          .firstOrNull;
      if (table == null || !_contains(table, data, '$objectId')) continue;
      if (await WorkspaceTableAccess(transaction: transaction)
          .canReadTable(session, member, table)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> retained(int objectId) async {
    final resources = await _resources();
    for (final resource in resources) {
      final data = _data(resource);
      if (resource.resourceKind == .table &&
          resource.resourceId != excludedTableId &&
          _defaultContains(data, '$objectId')) {
        return true;
      }
      if (resource.resourceKind == .file && data['assetId'] == '$objectId') {
        return true;
      }
      if (resource.resourceKind != .tableRecord ||
          resource.resourceId == excludedRecordId) {
        continue;
      }
      final table = resources
          .where(
            (row) =>
                row.resourceKind == .table && row.resourceId == data['tableId'],
          )
          .firstOrNull;
      if (table != null && _contains(table, data, '$objectId')) return true;
    }
    return false;
  }

  Future<bool> publiclyReadable(int objectId) async => (await _resources()).any(
    (row) =>
        row.resourceKind == .file &&
        row.deletedAt == null &&
        _data(row)['assetId'] == '$objectId',
  );

  Future<bool> canReuseInTable(int objectId, String tableId) async {
    final resources = await _resources();
    final target = resources
        .where(
          (row) =>
              row.resourceKind == .table &&
              row.resourceId == tableId &&
              row.deletedAt == null,
        )
        .firstOrNull;
    if (target == null) return false;
    final targetReaders = _readers(target);
    for (final source in resources.where(
      (row) =>
          row.resourceKind == .table &&
          row.deletedAt == null &&
          row.resourceId != excludedTableId,
    )) {
      if (!_defaultContains(_data(source), '$objectId')) continue;
      if (targetReaders.difference(_readers(source)).isNotEmpty) continue;
      if (await WorkspaceTableAccess(transaction: transaction)
          .canReadTable(session, member, source)) {
        return true;
      }
    }

    for (final record in resources) {
      if (record.resourceKind != .tableRecord ||
          record.deletedAt != null ||
          record.resourceId == excludedRecordId) {
        continue;
      }
      final data = _data(record);
      final source = resources
          .where(
            (row) =>
                row.resourceKind == .table &&
                row.resourceId == data['tableId'] &&
                row.deletedAt == null,
          )
          .firstOrNull;
      if (source == null || !_contains(source, data, '$objectId')) continue;
      if (targetReaders.difference(_readers(source)).isNotEmpty) continue;
      if (await WorkspaceTableAccess(transaction: transaction)
          .canReadTable(session, member, source)) {
        return true;
      }
    }
    return false;
  }

  Future<List<WorkspaceResource>> _resources() => WorkspaceResource.db.find(
    session,
    where: (row) =>
        row.workspaceId.equals(member.workspaceId) &
        row.resourceKind.inSet({.file, .table, .tableRecord}),
    transaction: transaction,
  );
}

Map<String, dynamic> _data(WorkspaceResource row) =>
    jsonDecode(row.data) as Map<String, dynamic>;

bool _contains(
  WorkspaceResource table,
  Map<String, dynamic> record,
  String id,
) {
  final columns = _data(table)['columns'];
  final values = record['values'];
  if (columns is! List || values is! Map) return false;
  for (final column in columns.whereType<Map>()) {
    if (column['type'] != 'attachment') continue;
    final value = values[column['id']];
    if (value is List && value.contains(id)) return true;
  }
  return false;
}

Set<String> _readers(WorkspaceResource table) {
  final grants = _data(table)['memberAccess'];
  return grants is Map ? grants.keys.cast<String>().toSet() : {};
}

bool _defaultContains(Map<String, dynamic> data, String id) {
  final columns = data['columns'];
  if (columns is! List) return false;
  return columns.whereType<Map>().any(
    (column) =>
        column['type'] == 'attachment' &&
        column['defaultValue'] is List &&
        (column['defaultValue'] as List).contains(id),
  );
}
