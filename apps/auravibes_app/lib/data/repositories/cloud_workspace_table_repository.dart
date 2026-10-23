import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class const CloudWorkspaceTableRepository(
  final CloudWorkspaceResourceStore _store,
) implements WorkspaceTableRepository {
  @override
  Future<List<WorkspaceTable>> list({String? parentId}) async {
    return (await _rows(
        _store,
        .table,
      )).map(_table).where((table) => table.parentId == parentId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<WorkspaceTable> table(String id) async {
    final row = (await _rows(
      _store,
      .table,
    )).where((row) => row.resourceId == id).firstOrNull;
    if (row == null) {
      throw const WorkspaceTableException(denied: true);
    }

    return _table(row);
  }

  @override
  Future<WorkspaceTable> create({
    required String name,
    required String labelName,
    String? parentId,
  }) async {
    final id = const UuidV7().generate();
    final columnId = const UuidV7().generate();
    await _store.create(
      kind: .table,
      id: id,
      data: {
        'name': name,
        'parentId': parentId,
        'labelColumnId': columnId,
        'schemaRevision': 1,
        'columns': [
          {'id': columnId, 'name': labelName, 'type': 'text'},
        ],
      },
    );

    return await table(id);
  }

  @override
  Future<WorkspaceTable> updateMetadata({
    required WorkspaceTable table,
    required String name,
    required String? parentId,
  }) async {
    await _store.update(
      kind: .table,
      id: table.id,
      revision: table.revision,
      data: {
        ...await _currentData(_store, table.id),
        'name': name,
        'parentId': parentId,
      },
    );

    return await this.table(table.id);
  }

  @override
  Future<WorkspaceTable> renameLabel({
    required WorkspaceTable table,
    required String name,
  }) => saveColumn(
    table: table,
    column: .new(id: table.labelColumnId, name: name),
  );

  @override
  Future<WorkspaceTable> saveColumn({
    required WorkspaceTable table,
    required WorkspaceColumn column,
  }) async {
    final columns = table.withColumn(column);
    final current = await _currentData(_store, table.id);
    await _store.update(
      kind: .table,
      id: table.id,
      revision: table.revision,
      data: {
        ..._schemaUpdate(table, columns),
        'memberAccess': current['memberAccess'],
      },
    );

    return await this.table(table.id);
  }

  @override
  Future<List<WorkspaceRecord>> records(String tableId) async {
    final _ = await table(tableId);

    return (await _rows(
      _store,
      .tableRecord,
    )).map(_record).where((record) => record.tableId == tableId).toList();
  }

  @override
  Future<WorkspaceRecord> record(String tableId, String id) async {
    final row = (await records(tableId))
        .where((record) => record.id == id)
        .firstOrNull;
    if (row == null) {
      throw const WorkspaceTableException(denied: true);
    }

    return row;
  }

  @override
  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, Object?> values,
  }) async {
    final id = const UuidV7().generate();
    await _store.create(
      kind: .tableRecord,
      id: id,
      data: {
        'tableId': table.id,
        'schemaRevision': table.schemaRevision,
        'values': values,
      },
    );

    return await record(table.id, id);
  }

  @override
  Future<WorkspaceRecord> updateRecord({
    required WorkspaceTable table,
    required WorkspaceRecord record,
    required Map<String, Object?> values,
  }) async {
    await _store.update(
      kind: .tableRecord,
      id: record.id,
      revision: record.revision,
      data: {
        'tableId': table.id,
        'schemaRevision': table.schemaRevision,
        'values': values,
      },
    );

    return await this.record(table.id, record.id);
  }
}

Future<List<WorkspaceResource>> _rows(
  CloudWorkspaceResourceStore store,
  WorkspaceResourceKind kind,
) async {
  final rows = <WorkspaceResource>[];
  String? cursor;
  do {
    final response = await _page(store, kind, cursor);
    rows.addAll(_active(response.pages.single.resources));
    cursor = response.pages.single.nextResourceId;
  } while (cursor != null);

  return rows;
}

WorkspaceTable _table(WorkspaceResource row) =>
    _tableFromData(row, CloudResourceMapper.decode(row));
WorkspaceTable _tableFromData(
  WorkspaceResource row,
  Map<String, dynamic> data,
) => WorkspaceTable(
  id: row.resourceId,
  name: data['name'] as String,
  labelColumnId: data['labelColumnId'] as String,
  columns: _decodeColumns(data),
  revision: row.revision,
  schemaRevision: data['schemaRevision'] as int,
  parentId: data['parentId'] as String?,
  canManage: data['canManageTable'] == true,
  canEditRecords: data['canEditRecords'] == true,
  supportsSharing: true,
);

WorkspaceRecord _record(WorkspaceResource row) {
  final data = CloudResourceMapper.decode(row);

  return WorkspaceRecord(
    id: row.resourceId,
    tableId: data['tableId'] as String,
    values: (data['values'] as Map<String, dynamic>).cast<String, Object?>(),
    revision: row.revision,
  );
}

Map<String, Object?> _schemaUpdate(
  WorkspaceTable table,
  List<WorkspaceColumn> columns,
) => {
  'name': table.name,
  'parentId': table.parentId,
  'labelColumnId': table.labelColumnId,
  'schemaRevision': table.schemaRevision + 1,
  'columns': columns.map((column) => column.toJson()).toList(),
};
Iterable<WorkspaceResource> _active(List<WorkspaceResource> rows) =>
    rows.where((row) => row.deletedAt == null);
Future<ReadWorkspaceStateResponse> _page(
  CloudWorkspaceResourceStore store,
  WorkspaceResourceKind kind,
  String? cursor,
) => store.read(
  pages: [
    WorkspaceResourcePageRequest(
      resourceKind: kind,
      afterResourceId: cursor,
      limit: 100,
    ),
  ],
);
List<WorkspaceColumn> _columns(List<dynamic> values) =>
    values.cast<Map<String, dynamic>>().map(WorkspaceColumn.fromJson).toList();

List<WorkspaceColumn> _decodeColumns(Map<String, Object?> data) =>
    _columns(data['columns']! as List<dynamic>);

Future<Map<String, dynamic>> _currentData(
  CloudWorkspaceResourceStore store,
  String id,
) async {
  final rows = await _rows(store, .table);

  return CloudResourceMapper.decode(
    rows.firstWhere((row) => row.resourceId == id),
  );
}
