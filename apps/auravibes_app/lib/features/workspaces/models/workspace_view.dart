import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:uuid/v7.dart';

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
}) {
  factory create({
    required String name,
    required WorkspaceTable table,
    required List<String> columnIds,
    String? parentId,
  }) => .new(
    id: const UuidV7().generate(),
    name: name,
    tableId: table.id,
    bindings: _bindings(columnIds),
    columnTypes: _types(table, columnIds),
    definition: _defaultDefinition(),
    revision: 0,
    parentId: parentId,
  );

  WorkspaceView edited({
    required String name,
    required A2uiSavedDefinition definition,
    required Map<String, String> bindings,
    required Map<String, String> columnTypes,
  }) => .new(
    id: id,
    name: name,
    tableId: tableId,
    bindings: bindings,
    columnTypes: columnTypes,
    definition: definition,
    revision: revision,
    parentId: parentId,
    canManage: canManage,
  );
  WorkspaceView withParent(String? value) => .new(
    id: id,
    name: name,
    tableId: tableId,
    bindings: bindings,
    columnTypes: columnTypes,
    definition: definition,
    revision: revision,
    parentId: value,
    canManage: canManage,
  );

  WorkspaceView withRevision(int value) => .new(
    id: id,
    name: name,
    tableId: tableId,
    bindings: bindings,
    columnTypes: columnTypes,
    definition: definition,
    revision: value,
    parentId: parentId,
    canManage: canManage,
  );
  WorkspaceView withManagement({required bool value}) => .new(
    id: id,
    name: name,
    tableId: tableId,
    bindings: bindings,
    columnTypes: columnTypes,
    definition: definition,
    revision: revision,
    parentId: parentId,
    canManage: value,
  );
}

Map<String, String> _bindings(List<String> ids) => {
  for (var index = 0; index < ids.length; index++) 'field$index': ids[index],
};
Map<String, String> _types(WorkspaceTable table, List<String> ids) => {
  for (final column in table.columns)
    if (ids.contains(column.id)) column.id: column.type.name,
};
A2uiSavedDefinition _defaultDefinition() => A2uiSavedDefinition.fromJson({
  'version': 1,
  'components': [
    {
      'id': 'root',
      'component': 'Table',
      'columns': {'path': '/columns'},
      'rows': {'path': '/rows'},
    },
  ],
});

abstract interface class WorkspaceViewRepository {
  Future<List<WorkspaceView>> list({String? parentId, bool allFolders = false});
  Future<WorkspaceView> read(String id);
  Future<WorkspaceView> save(WorkspaceView view, {required String requestId});
  Future<List<WorkspaceView>> history(String id);
}

class const WorkspaceViewData({
  required final WorkspaceView view,
  required final WorkspaceTable table,
  required final List<WorkspaceRecord> records,
  required final bool needsRepair,
});
