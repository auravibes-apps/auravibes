import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudWorkspaceRecordQueryRepository(
  final CloudWorkspaceStateGateway gateway,
) implements WorkspaceRecordQueryRepository {
  @override
  Future<WorkspaceRecordPage> query(
    String tableId,
    WorkspaceRecordQuery query,
  ) async {
    final rows = await _read(tableId, query);

    return WorkspaceRecordPage(
      records: rows.take(query.limit).map(_record).toList(),
      hasMore: rows.length > query.limit,
    );
  }

  Future<List<WorkspaceResource>> _read(
    String tableId,
    WorkspaceRecordQuery query,
  ) => CloudAppErrors.guardCall(
    .state,
    () => gateway.client.workspaceState.queryRecords(
      gateway.workspace.cloudWorkspaceId,
      tableId,
      jsonEncode(query.toJson()),
    ),
  );
}

WorkspaceRecord _record(WorkspaceResource row) {
  final data = CloudResourceMapper.decode(row);

  return WorkspaceRecord(
    id: row.resourceId,
    tableId: data['tableId'] as String,
    values: _values(data),
    revision: row.revision,
    restrictedReferenceColumns: _restricted(data),
  );
}

Map<String, Object?> _values(Map<String, dynamic> data) =>
    (data['values'] as Map<String, dynamic>).cast<String, Object?>();
List<String> _restricted(Map<String, dynamic> data) =>
    (data['restrictedReferenceColumns'] as List<dynamic>? ?? const [])
        .cast<String>();
