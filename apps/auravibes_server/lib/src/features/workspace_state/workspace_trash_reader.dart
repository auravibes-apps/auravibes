import 'dart:convert';

import '../../generated/protocol.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_context.dart';
import 'workspace_trash_store.dart';

class const WorkspaceTrashReader(final WorkspaceTrashContext context) {
  Future<List<String>> list() async {
    final rows = await context.store.resources();
    final result = <String>[];
    for (final batch in await context.store.batches()) {
      final visible = await _visible(batch, rows);
      if (visible != null) result.add(visible);
    }
    return result;
  }

  Future<String> deletedReference(String tableId, String recordId) async {
    final rows = await context.store.resources();
    if (!await _readableRecord(rows, tableId, recordId)) return 'null';
    final batch = await _batchForRecord(recordId);
    if (batch == null) return 'null';
    final allowed = await _canRestore(batch, rows);
    return _recovery(batch.batchId, allowed);
  }

  Future<bool> _readableRecord(
    List<WorkspaceResource> rows,
    String tableId,
    String recordId,
  ) async {
    final record = _record(rows, tableId, recordId);
    return record != null && await context.readable(record);
  }

  Future<WorkspaceTrashBatch?> _batchForRecord(String id) async {
    for (final batch in await context.store.batches()) {
      if (_contains(trashMembers(batch), 'tableRecord', id)) return batch;
    }
    return null;
  }

  Future<String?> _visible(
    WorkspaceTrashBatch batch,
    List<WorkspaceResource> rows,
  ) async {
    for (final member in trashMembers(batch)) {
      final row = trashMemberResource(rows, member);
      if (row == null || !await context.readable(row)) return null;
    }
    return jsonEncode({
      ...trashBatchJson(batch),
      'canRestore': await _canRestore(batch, rows),
    });
  }

  Future<bool> _canRestore(
    WorkspaceTrashBatch batch,
    List<WorkspaceResource> rows,
  ) async {
    final members = trashMembers(batch);
    for (final member in members) {
      final row = trashMemberResource(rows, member);
      if (row == null ||
          !await context.writable(row) ||
          !_tableAvailable(row, rows, members)) {
        return false;
      }
    }
    return true;
  }
}

bool _contains(List<Map<String, dynamic>> members, String kind, String id) =>
    members.any((row) => row['kind'] == kind && row['id'] == id);
WorkspaceResource? _record(
  List<WorkspaceResource> rows,
  String tableId,
  String recordId,
) => rows.where((row) => _matchesRecord(row, tableId, recordId)).firstOrNull;
bool _matchesRecord(WorkspaceResource row, String tableId, String recordId) =>
    row.resourceKind == .tableRecord &&
    row.resourceId == recordId &&
    row.deletedAt != null &&
    trashData(row)['tableId'] == tableId;
bool _tableAvailable(
  WorkspaceResource row,
  List<WorkspaceResource> rows,
  List<Map<String, dynamic>> members,
) {
  if (row.resourceKind != .tableRecord) return true;
  final id = trashData(row)['tableId'] as String;
  final table = _table(rows, id);
  return table != null &&
      (table.deletedAt == null || _contains(members, 'table', id));
}

WorkspaceResource? _table(List<WorkspaceResource> rows, String id) => rows
    .where((row) => row.resourceKind == .table && row.resourceId == id)
    .firstOrNull;
String _recovery(String id, bool allowed) =>
    jsonEncode({'batchId': id, 'canRestore': allowed});
