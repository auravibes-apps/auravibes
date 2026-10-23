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
    return (await _rows(.table))
        .map(_table)
        .where((table) => table.parentId == parentId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<WorkspaceTable> table(String id) async {
    final row = (await _rows(.table))
        .where((row) => row.resourceId == id)
        .firstOrNull;
    if (row == null) {
      throw const WorkspaceTableException();
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
  Future<WorkspaceTable> renameLabel({
    required WorkspaceTable table,
    required String name,
  }) async {
    await _store.update(
      kind: .table,
      id: table.id,
      revision: table.revision,
      data: {
        'name': table.name,
        'parentId': table.parentId,
        'labelColumnId': table.labelColumnId,
        'schemaRevision': table.schemaRevision + 1,
        'columns': [
          for (final column in table.columns)
            {
              'id': column.id,
              'name': column.id == table.labelColumnId ? name : column.name,
              'type': 'text',
            },
        ],
      },
    );

    return await this.table(table.id);
  }

  @override
  Future<List<WorkspaceRecord>> records(String tableId) async {
    final _ = await table(tableId);

    return (await _rows(.tableRecord))
        .map(_record)
        .where((record) => record.tableId == tableId)
        .toList();
  }

  @override
  Future<WorkspaceRecord> record(String tableId, String id) async {
    final row = (await records(tableId))
        .where((record) => record.id == id)
        .firstOrNull;
    if (row == null) {
      throw const WorkspaceTableException();
    }

    return row;
  }

  @override
  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, String> values,
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
    required Map<String, String> values,
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

  Future<List<WorkspaceResource>> _rows(WorkspaceResourceKind kind) async {
    final rows = <WorkspaceResource>[];
    String? cursor;
    do {
      final response = await _store.read(
        pages: [
          WorkspaceResourcePageRequest(
            resourceKind: kind,
            afterResourceId: cursor,
            limit: 100,
          ),
        ],
      );
      rows.addAll(
        response.pages.single.resources.where((row) => row.deletedAt == null),
      );
      cursor = response.pages.single.nextResourceId;
    } while (cursor != null);

    return rows;
  }

  WorkspaceTable _table(WorkspaceResource row) {
    final data = CloudResourceMapper.decode(row);

    return WorkspaceTable(
      id: row.resourceId,
      name: data['name'] as String,
      labelColumnId: data['labelColumnId'] as String,
      columns: [
        for (final column
            in (data['columns'] as List<dynamic>).cast<Map<String, dynamic>>())
          WorkspaceColumn(
            id: column['id'] as String,
            name: column['name'] as String,
          ),
      ],
      revision: row.revision,
      schemaRevision: data['schemaRevision'] as int,
      parentId: data['parentId'] as String?,
    );
  }

  WorkspaceRecord _record(WorkspaceResource row) {
    final data = CloudResourceMapper.decode(row);

    return WorkspaceRecord(
      id: row.resourceId,
      tableId: data['tableId'] as String,
      values: (data['values'] as Map<String, dynamic>).cast<String, String>(),
      revision: row.revision,
    );
  }
}
