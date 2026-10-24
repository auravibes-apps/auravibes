import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const WorkspaceView({
  required final String id,
  required final String name,
  required final String tableId,
  required final Map<String, String> bindings,
  required final Map<String, String> columnTypes,
  required final A2uiSavedDefinition definition,
  required final int revision,
  final String? parentId,
  final bool canManage = true,
});

abstract interface class WorkspaceViewRepository {
  Future<List<WorkspaceView>> list({String? parentId});
  Future<WorkspaceView> read(String id);
  Future<WorkspaceView> save(WorkspaceView view);
  Future<List<WorkspaceView>> history(String id);
}

class const WorkspaceViewData({
  required final WorkspaceView view,
  required final WorkspaceTable table,
  required final List<WorkspaceRecord> records,
  required final bool needsRepair,
});
