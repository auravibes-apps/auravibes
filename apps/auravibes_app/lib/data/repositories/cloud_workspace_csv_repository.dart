import 'dart:convert';

import 'package:auravibes_app/data/repositories/cloud_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_trash_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudWorkspaceCsvRepository(
  final CloudWorkspaceStateGateway gateway,
) implements WorkspaceCsvRepository {
  @override
  Future<bool> readableDeletedReference(
    String tableId,
    String recordId,
  ) async =>
      await CloudWorkspaceTrashRepository(.new(gateway))
          .deletedReference(tableId, recordId) !=
      null;

  @override
  Future<WorkspaceTable> table(String id) =>
      CloudWorkspaceTableRepository(.new(gateway)).table(id);

  @override
  Future<WorkspaceRecordPage> query(String id, WorkspaceRecordQuery query) =>
      CloudWorkspaceRecordQueryRepository(gateway).query(id, query);

  @override
  Future<void> write(
    WorkspaceCsvPreview preview, {
    required bool previewOnly,
  }) async {
    preview.validate();
    final request = _request(preview);
    final _ = await CloudAppErrors.guardCall(
      .state,
      () => previewOnly
          ? gateway.client.workspaceCsv.preview(request)
          : gateway.client.workspaceState.patch(request),
    );
  }

  PatchWorkspaceStateRequest _request(WorkspaceCsvPreview preview) =>
      PatchWorkspaceStateRequest(
        workspaceId: gateway.workspace.cloudWorkspaceId,
        requestId: preview.requestId,
        operations: [
          for (var index = 0; index < preview.values.length; index++)
            _operation(preview, index),
        ],
      );
}

WorkspacePatchOperation _operation(WorkspaceCsvPreview preview, int index) =>
    WorkspacePatchOperation(
      operation: .create,
      resourceKind: .tableRecord,
      resourceId: '${preview.requestId}-$index',
      data: _data(preview, index),
      fieldMask: const [],
    );

String _data(WorkspaceCsvPreview preview, int index) => jsonEncode({
  'tableId': preview.table.id,
  'schemaRevision': preview.table.schemaRevision,
  'values': preview.values[index],
});
