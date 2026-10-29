import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;

class const CloudWorkspaceItemDuplicationRepository(
  final cloud.Client client,
  final int workspaceId,
) implements WorkspaceItemDuplicationRepository {
  @override
  Future<void> copy(WorkspaceItemDuplication request) async {
    request.validate();
    try {
      await _copy(request);
    } on CloudAppException catch (error, stackTrace) {
      if (error.code != 'validationFailed') rethrow;
      Error.throwWithStackTrace(
        const WorkspaceTableException(unsupportedCopy: true),
        stackTrace,
      );
    }
  }

  Future<void> _copy(WorkspaceItemDuplication request) =>
      CloudAppErrors.guardCall(.state, () => _execute(request));

  Future<void> _execute(WorkspaceItemDuplication request) async {
    final input = _input(request, workspaceId);
    if (request.kind == .table) {
      final _ = await client.workspaceState.duplicateTable(input);
    } else {
      final _ = await client.workspaceView.duplicate(input);
    }
  }
}

cloud.DuplicateWorkspaceItemRequest _input(
  WorkspaceItemDuplication request,
  int workspaceId,
) => .new(
  workspaceId: workspaceId,
  requestId: request.requestId,
  sourceId: request.sourceId,
  expectedRevision: request.expectedRevision,
  targetId: request.targetId,
  name: request.name,
  parentId: request.parentId,
  copyRecords: request.copyRecords,
);
