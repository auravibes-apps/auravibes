import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../objects/object_attachment_projection.dart';
import 'workspace_table_access.dart';

class const WorkspaceReferenceVisibility(
  final Session session,
  final WorkspaceMember member,
  final Transaction? transaction,
) {
  ObjectAttachmentProjection get _attachments =>
      .new(session, member, transaction);

  Future<WorkspaceResource> record(WorkspaceResource row) async {
    final data = _data(row);
    final table = await _table(data['tableId'] as String);
    if (table == null) return row;
    final restricted = await _restricted(_columns(table));
    restricted.addAll(await _recordAttachments(table, data));

    return _project(row, data, restricted);
  }

  Future<WorkspaceResource> table(WorkspaceResource row) async {
    final restricted = await _restricted(_columns(row));
    final data = _data(row);
    restricted.addAll(await _defaultAttachments(data));
    data['columns'] = _visibleColumns(data, restricted);

    return row.copyWith(data: jsonEncode(data));
  }

  Future<List<String>> _recordAttachments(
    WorkspaceResource table,
    Map<String, dynamic> data,
  ) => _attachments.restricted(_allColumns(_data(table)), _values(data));

  Future<List<String>> _defaultAttachments(Map<String, dynamic> data) =>
      _attachments.restricted(_allColumns(data), _defaultValues(data));

  Future<List<String>> _restricted(
    Iterable<Map<String, dynamic>> columns,
  ) async {
    final restricted = <String>[];
    for (final column in columns) {
      if (!await _visible(column['targetTableId'] as String)) {
        restricted.add(column['id'] as String);
      }
    }

    return restricted;
  }

  Future<bool> _visible(String id) async {
    final table = await _table(id);
    if (table == null) return false;

    return await WorkspaceTableAccess(transaction: transaction)
        .canReadTable(session, member, table, includeDeleted: true);
  }

  Future<WorkspaceResource?> _table(String id) =>
      WorkspaceResource.db.findFirstRow(
        session,
        where: (row) => _matches(row, id),
        transaction: transaction,
      );
  Expression _matches(WorkspaceResourceTable row, String id) =>
      row.workspaceId.equals(member.workspaceId) &
      row.resourceKind.equals(.table) &
      row.resourceId.equals(id);
}

Iterable<Map<String, dynamic>> _columns(WorkspaceResource row) =>
    _allColumns(_data(row)).where(
      (column) => column['type'] == 'reference',
    );
List<Map<String, dynamic>> _allColumns(Map<String, dynamic> data) =>
    (data['columns'] as List).cast<Map<String, dynamic>>();
Map<String, Object?> _values(Map<String, dynamic> data) =>
    (data['values'] as Map).cast<String, Object?>();
Map<String, Object?> _defaultValues(Map<String, dynamic> data) => {
  for (final column in _allColumns(data))
    if (column['defaultValue'] != null)
      column['id'] as String: column['defaultValue'],
};
WorkspaceResource _project(
  WorkspaceResource row,
  Map<String, dynamic> data,
  List<String> restricted,
) => row.copyWith(
  data: jsonEncode({
    ...data,
    'values': _visibleValues(data, restricted),
    'restrictedReferenceColumns': restricted,
  }),
);
Map<String, Object?> _visibleValues(
  Map<String, dynamic> data,
  List<String> restricted,
) => _values(data)..removeWhere((key, _) => restricted.contains(key));
Map<String, dynamic> _data(WorkspaceResource resource) =>
    jsonDecode(resource.data) as Map<String, dynamic>;

List<Map<String, dynamic>> _visibleColumns(
  Map<String, dynamic> data,
  List<String> restricted,
) => (data['columns'] as List)
    .cast<Map<String, dynamic>>()
    .map((column) => _visibleColumn(column, restricted))
    .toList();
Map<String, dynamic> _visibleColumn(
  Map<String, dynamic> column,
  List<String> restricted,
) {
  final visible = {...column, 'required': false};
  if (restricted.contains(column['id'])) visible.remove('defaultValue');

  return visible;
}
