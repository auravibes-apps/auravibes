import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudWorkspaceRecordBatchRepository(
  final CloudWorkspaceStateGateway gateway,
) implements WorkspaceRecordBatchRepository {
  @override
  Future<void> apply(
    List<WorkspaceRecordChange> changes, {
    required String requestId,
  }) async {
    WorkspaceRecordChange.validate(changes);
    final _ = await gateway.patch(
      requestId: requestId,
      operations: changes.map(_operation).toList(),
    );
  }

  WorkspacePatchOperation _operation(WorkspaceRecordChange change) => .new(
    operation: .update,
    resourceKind: .tableRecord,
    resourceId: change.record.id,
    expectedRevision: change.record.revision,
    data: jsonEncode(change.toJson()),
    fieldMask: const [],
  );
}
