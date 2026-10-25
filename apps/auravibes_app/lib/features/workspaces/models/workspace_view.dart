import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
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
  final WorkspaceConnectedBinding? connected,
  final bool canManage = true,
  final WorkspaceRecordQuery query = const WorkspaceRecordQuery(),
  final List<String> summaryColumnIds = const [],
}) {
  bool get isConnectedOnly => tableId.isEmpty;

  factory connectedDraft({required String name, String? parentId}) => .new(
    id: const UuidV7().generate(),
    name: name,
    tableId: '',
    bindings: const {'source': ''},
    columnTypes: const {},
    definition: A2uiSavedDefinition.fromJson({
      'version': 1,
      'components': [
        {
          'id': 'root',
          'component': 'Text',
          'text': {'path': '/source'},
        },
      ],
    }),
    revision: 0,
    parentId: parentId,
  );

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
    query: query,
    summaryColumnIds: summaryColumnIds,
    connected: connected,
  );
  WorkspaceView withConnected(WorkspaceConnectedBinding? value) => .new(
    id: id,
    name: name,
    tableId: tableId,
    bindings: bindings,
    columnTypes: columnTypes,
    definition: definition,
    revision: revision,
    parentId: parentId,
    canManage: canManage,
    query: query,
    summaryColumnIds: summaryColumnIds,
    connected: value,
  );
  WorkspaceView withSummaryColumns(List<String> ids) => .new(
    id: id,
    name: name,
    tableId: tableId,
    bindings: bindings,
    columnTypes: columnTypes,
    definition: definition,
    revision: revision,
    parentId: parentId,
    canManage: canManage,
    query: query,
    summaryColumnIds: ids,
    connected: connected,
  );
  WorkspaceView withQuery(WorkspaceRecordQuery value) => .new(
    id: id,
    name: name,
    tableId: tableId,
    bindings: bindings,
    columnTypes: columnTypes,
    definition: definition,
    revision: revision,
    parentId: parentId,
    canManage: canManage,
    query: value,
    summaryColumnIds: summaryColumnIds,
    connected: connected,
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
    query: query,
    summaryColumnIds: summaryColumnIds,
    connected: connected,
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
    query: query,
    summaryColumnIds: summaryColumnIds,
    connected: connected,
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
    query: query,
    summaryColumnIds: summaryColumnIds,
    connected: connected,
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
  final bool hasMore = false,
  final int offset = 0,
  final Map<String, Object?> summary = const {},
});
