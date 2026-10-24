import 'dart:convert';
import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;

class const CloudWorkspaceViewRepository(final cloud.Client client, final int workspaceId)
    implements WorkspaceViewRepository {
  @override
  Future<List<WorkspaceView>> list({String? parentId}) => CloudAppErrors.guardCall(.state,() async =>
    (await client.workspaceView.list(workspaceId,parentId)).map(_view).toList());
  @override
  Future<WorkspaceView> read(String id) => CloudAppErrors.guardCall(.state,() async => _view(await client.workspaceView.read(workspaceId,id)));
  @override
  Future<WorkspaceView> save(WorkspaceView view) => CloudAppErrors.guardCall(.state,() async => _view(await client.workspaceView.save(workspaceId,view.id,view.revision,jsonEncode(workspaceViewJson(view)))));
  @override
  Future<List<WorkspaceView>> history(String id) => CloudAppErrors.guardCall(.state,() async =>
    (await client.workspaceView.history(workspaceId,id)).map((data) => workspaceViewFromJson(jsonDecode(data) as Map<String,dynamic>)).toList());
}
WorkspaceView _view(cloud.WorkspaceView value) => workspaceViewFromJson(jsonDecode(value.data) as Map<String,dynamic>);
