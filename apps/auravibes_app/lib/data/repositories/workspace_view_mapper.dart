import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class WorkspaceViewMapper {
  static Map<String, Object?> toJson(WorkspaceView view) => {
    'id': view.id,
    'name': view.name,
    'tableId': view.tableId,
    'parentId': view.parentId,
    'bindings': view.bindings,
    'columnTypes': view.columnTypes,
    'definition': view.definition.toJson(),
    'revision': view.revision,
  };
  static WorkspaceView fromJson(Map<String, dynamic> data) =>
      _view(_identity(data), _content(data));
}

typedef _ViewIdentity = ({
  String id,
  String name,
  String tableId,
  String? parentId,
  int revision,
});
typedef _ViewContent = ({
  Map<String, String> bindings,
  Map<String, String> columnTypes,
  A2uiSavedDefinition definition,
});

_ViewIdentity _identity(Map<String, dynamic> data) => (
  id: data['id'] as String,
  name: data['name'] as String,
  tableId: data['tableId'] as String,
  parentId: data['parentId'] as String?,
  revision: data['revision'] as int,
);
_ViewContent _content(Map<String, dynamic> data) => (
  bindings: _strings(data, 'bindings'),
  columnTypes: _strings(data, 'columnTypes'),
  definition: _definition(data),
);
Map<String, String> _strings(Map<String, dynamic> data, String key) =>
    Map<String, String>.from(data[key] as Map);
A2uiSavedDefinition _definition(Map<String, dynamic> data) =>
    A2uiSavedDefinition.fromJson(
      Map<String, Object?>.from(data['definition'] as Map),
    );
WorkspaceView _view(_ViewIdentity identity, _ViewContent content) => .new(
  id: identity.id,
  name: identity.name,
  tableId: identity.tableId,
  bindings: content.bindings,
  columnTypes: content.columnTypes,
  definition: content.definition,
  revision: identity.revision,
  parentId: identity.parentId,
);
