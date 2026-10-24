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
  Future<WorkspaceResource> record(WorkspaceResource row) async {
    final data = _data(row);
    final table = await _table(data['tableId'] as String);
    if (table == null) return row;
    final restricted = await _restricted(_columns(table));
    restricted.addAll(
      await ObjectAttachmentProjection(session, member, transaction).restricted(
        (_data(table)['columns'] as List).cast<Map<String, dynamic>>(),
        (data['values'] as Map).cast<String, Object?>(),
      ),
    );

    return _project(row, data, restricted);
  }

  Future<WorkspaceResource> table(WorkspaceResource row) async {
    final restricted = await _restricted(_columns(row));
    final data = _data(row);
    final columns = (data['columns'] as List).cast<Map<String, dynamic>>();
    restricted.addAll(
      await ObjectAttachmentProjection(session, member, transaction).restricted(
        columns,
        {
          for (final column in columns)
            if (column['defaultValue'] != null)
              column['id'] as String: column['defaultValue'],
        },
      ),
    );
    data['columns'] = _visibleColumns(data, restricted);

    return row.copyWith(data: jsonEncode(data));
  }

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
    (_data(row)['columns'] as List).cast<Map<String, dynamic>>().where(
      (column) => column['type'] == 'reference',
    );
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
) =>
    (data['values'] as Map).cast<String, Object?>()
      ..removeWhere((key, _) => restricted.contains(key));
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
  if (!restricted.contains(column['id'])) return column;

  return {...column}..remove('defaultValue');
}
