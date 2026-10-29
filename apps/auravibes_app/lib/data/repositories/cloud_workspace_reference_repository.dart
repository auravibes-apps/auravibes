import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

const _pageSize = 50;

class const CloudWorkspaceReferenceRepository(
  final CloudWorkspaceResourceStore store,
) implements WorkspaceReferenceRepository {
  @override
  Future<WorkspaceRecord> record(String tableId, String id) async {
    final connection = await _connection();

    return _record(
      await connection.client.workspaceReference.record(
        .new(
          workspaceId: connection.workspaceId,
          tableId: tableId,
          recordId: id,
        ),
      ),
    );
  }

  @override
  Future<WorkspaceReferencePage> targets(
    WorkspaceReferenceSource source, {
    required String search,
    String? afterId,
    String? parentId,
  }) async {
    final connection = await _connection();

    return _page(
      await connection.client.workspaceReference.targets(
        .new(
          workspaceId: connection.workspaceId,
          sourceTableId: source.tableId,
          columnId: source.columnId,
          parentId: parentId,
          search: search,
          afterId: afterId,
        ),
      ),
    );
  }

  @override
  Future<WorkspaceReferencePage> tableTargets(
    String tableId, {
    required String search,
    String? afterId,
  }) async {
    final connection = await _connection();

    return _page(
      await connection.client.workspaceReference.tableTargets(
        .new(
          workspaceId: connection.workspaceId,
          tableId: tableId,
          search: search,
          afterId: afterId,
        ),
      ),
    );
  }

  @override
  Future<WorkspaceReferencePage> reverse({
    required String tableId,
    required String recordId,
    String? afterId,
  }) async {
    final connection = await _connection();

    return _page(
      await connection.client.workspaceReference.reverse(
        .new(
          workspaceId: connection.workspaceId,
          tableId: tableId,
          recordId: recordId,
          afterId: afterId,
        ),
      ),
    );
  }

  Future<({Client client, int workspaceId})> _connection() async {
    final client = await store.client;
    final workspaceId = await store.cloudWorkspaceId;
    if (client == null || workspaceId == null) {
      throw const WorkspaceTableException(denied: true);
    }

    return (client: client, workspaceId: workspaceId);
  }
}

WorkspaceReferencePage _page(List<WorkspaceResource> rows) =>
    WorkspaceReferencePage(
      records: rows.take(_pageSize).map(_record).toList(),
      nextId: rows.length > _pageSize ? rows[_pageSize - 1].resourceId : null,
    );

WorkspaceRecord _record(WorkspaceResource row) {
  final data = CloudResourceMapper.decode(row);

  return WorkspaceRecord(
    id: row.resourceId,
    tableId: data['tableId'] as String,
    values: (data['values'] as Map).cast<String, Object?>(),
    revision: row.revision,
    restrictedReferenceColumns: _restricted(data),
  );
}

List<String> _restricted(Map<String, dynamic> data) =>
    (data['restrictedReferenceColumns'] as List<dynamic>? ?? const [])
        .cast<String>();
