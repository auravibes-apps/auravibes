import 'package:auravibes_app/features/workspaces/models/workspace_reference.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudWorkspaceReferenceRepository(
  final CloudWorkspaceResourceStore store,
) implements WorkspaceReferenceRepository {
  @override
  Future<WorkspaceReferencePage> targets({
    required String sourceTableId,
    required String columnId,
    required String search,
    String? afterId,
  }) async {
    final connection = await _connection();
    return _page(
      await connection.client.workspaceReference.targets(
        connection.workspaceId,
        sourceTableId,
        columnId,
        search,
        afterId,
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
        connection.workspaceId,
        tableId,
        recordId,
        afterId,
      ),
    );
  }

  Future<({Client client, int workspaceId})> _connection() async {
    final client = await store.client;
    final workspaceId = await store.cloudWorkspaceId;
    if (client == null || workspaceId == null)
      throw const WorkspaceTableException(denied: true);
    return (client: client, workspaceId: workspaceId);
  }
}

WorkspaceReferencePage _page(List<WorkspaceResource> rows) =>
    WorkspaceReferencePage(
      records: rows.take(50).map(_record).toList(),
      nextId: rows.length > 50 ? rows[49].resourceId : null,
    );

WorkspaceRecord _record(WorkspaceResource row) {
  final data = CloudResourceMapper.decode(row);
  return WorkspaceRecord(
    id: row.resourceId,
    tableId: data['tableId'] as String,
    values: (data['values'] as Map).cast<String, Object?>(),
    revision: row.revision,
  );
}
