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
  static WorkspaceView fromJson(Map<String, dynamic> data) => data._view();
}

extension _ViewFields on Map<String, dynamic> {
  String get id => this['id'] as String;
  String get name => this['name'] as String;
  String get tableId => this['tableId'] as String;
  String? get parentId => this['parentId'] as String?;
  int get revision => this['revision'] as int;
  Map<String, String> get bindings =>
      Map<String, String>.from(this['bindings'] as Map);
  Map<String, String> get columnTypes =>
      Map<String, String>.from(this['columnTypes'] as Map);
  A2uiSavedDefinition get definition => A2uiSavedDefinition.fromJson(
    Map<String, Object?>.from(this['definition'] as Map),
  );
  WorkspaceView _view() => .new(
    id: id,
    name: name,
    tableId: tableId,
    bindings: bindings,
    columnTypes: columnTypes,
    definition: definition,
    revision: revision,
    parentId: parentId,
  );
}
