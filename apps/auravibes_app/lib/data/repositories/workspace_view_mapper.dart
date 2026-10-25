import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
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
    'query': view.query.toJson(),
    'summaryColumnIds': view.summaryColumnIds,
    if (view.connected case final connected?) 'connected': connected.toJson(),
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
  WorkspaceRecordQuery query,
  List<String> summaryColumnIds,
  WorkspaceConnectedBinding? connected,
});

_ViewIdentity _identity(Map<String, dynamic> data) => (
  id: data['id'] as String,
  name: data['name'] as String,
  tableId: data['tableId'] as String,
  parentId: data['parentId'] as String?,
  revision: data['revision'] as int,
);
_ViewContent _content(Map<String, dynamic> data) => (
  connected: _connected(data['connected']),
  bindings: _strings(data, 'bindings'),
  columnTypes: _strings(data, 'columnTypes'),
  definition: _definition(data),
  summaryColumnIds: (data['summaryColumnIds'] as List? ?? const [])
      .cast<String>(),
  query: _query(data['query']),
);
WorkspaceRecordQuery _query(Object? data) => WorkspaceRecordQuery.fromJson(
  Map<String, dynamic>.from(data as Map? ?? const {}),
);
WorkspaceConnectedBinding? _connected(Object? data) => data == null
    ? null
    : WorkspaceConnectedBinding.fromJson(
        Map<String, dynamic>.from(data as Map),
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
  query: content.query,
  summaryColumnIds: content.summaryColumnIds,
  connected: content.connected,
  revision: identity.revision,
  parentId: identity.parentId,
);
