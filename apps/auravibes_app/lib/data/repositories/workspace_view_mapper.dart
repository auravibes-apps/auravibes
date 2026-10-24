import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

Map<String, Object?> workspaceViewJson(WorkspaceView view) => {
  'id': view.id, 'name': view.name, 'tableId': view.tableId,
  'parentId': view.parentId, 'bindings': view.bindings, 'columnTypes': view.columnTypes,
  'definition': view.definition.toJson(), 'revision': view.revision,
};

WorkspaceView workspaceViewFromJson(Map<String, dynamic> data, {bool canManage = true}) => WorkspaceView(
  id: data['id'] as String, name: data['name'] as String, tableId: data['tableId'] as String,
  parentId: data['parentId'] as String?, revision: data['revision'] as int,
  bindings: Map<String, String>.from(data['bindings'] as Map),
  columnTypes: Map<String, String>.from(data['columnTypes'] as Map),
  definition: A2uiSavedDefinition.fromJson(Map<String, Object?>.from(data['definition'] as Map)),
  canManage: canManage,
);
