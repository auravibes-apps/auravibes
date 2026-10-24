import 'dart:convert';

import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;

class const CloudWorkspaceViewRepository(
  final cloud.Client client,
  final int workspaceId,
) implements WorkspaceViewRepository {
  @override
  Future<List<WorkspaceView>> list({
    String? parentId,
    bool allFolders = false,
  }) => CloudAppErrors.guardCall(
    .state,
    () async => (await client.workspaceView.list(
      .new(
        workspaceId: workspaceId,
        parentId: parentId,
        allFolders: allFolders,
      ),
    )).map(_view).toList(),
  );
  @override
  Future<WorkspaceView> read(String id) => CloudAppErrors.guardCall(
    .state,
    () async => _view(await client.workspaceView.read(workspaceId, id)),
  );
  @override
  Future<WorkspaceView> save(WorkspaceView view, {required String requestId}) =>
      CloudAppErrors.guardCall(.state, () => _save(view, requestId));
  @override
  Future<List<WorkspaceView>> history(String id) =>
      CloudAppErrors.guardCall(.state, () => _history(id));

  Future<WorkspaceView> _save(WorkspaceView view, String requestId) async =>
      _view(
        await client.workspaceView.save(_request(view, workspaceId, requestId)),
      );
  Future<List<WorkspaceView>> _history(String id) async {
    final snapshots = await client.workspaceView.history(workspaceId, id);

    return snapshots.map(_snapshot).toList();
  }
}

cloud.WorkspaceViewSaveRequest _request(
  WorkspaceView view,
  int workspaceId,
  String requestId,
) => .new(
  workspaceId: workspaceId,
  requestId: requestId,
  viewId: view.id,
  expectedRevision: view.revision,
  definition: jsonEncode(WorkspaceViewMapper.toJson(view)),
);
WorkspaceView _view(cloud.WorkspaceView value) => _snapshot(value.data);
WorkspaceView _snapshot(String data) =>
    WorkspaceViewMapper.fromJson(jsonDecode(data) as Map<String, dynamic>);
