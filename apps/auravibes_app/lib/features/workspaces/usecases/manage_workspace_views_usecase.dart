import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:uuid/v7.dart';

class const ManageWorkspaceViewsUsecase(
  final WorkspaceViewRepository _views,
  final OrganizeWorkspaceTablesUsecase _tables,
) {
  Future<List<WorkspaceView>> list({String? parentId}) => _views.list(parentId: parentId);

  Future<WorkspaceViewData> open(String id) async {
    final view = await _views.read(id);
    final table = await _tables.table(view.tableId);
    final columnIds = table.columns.map((column) => column.id).toSet();
    final repair = !view.bindings.values.every(columnIds.contains) || view.columnTypes.entries.any((entry) => table.columns.where((column) => column.id == entry.key).firstOrNull?.type.name != entry.value);
    return WorkspaceViewData(view: view, table: table,
      records: repair ? const [] : await _tables.records(table.id), needsRepair: repair);
  }

  Future<WorkspaceView> create({required String name, required WorkspaceTable table,
    required List<String> columnIds, String? parentId}) => save(WorkspaceView(
      id: const UuidV7().generate(), name: name, tableId: table.id,
      parentId: parentId, revision: 0,
      bindings: {for (var i = 0; i < columnIds.length; i++) 'field$i': columnIds[i]},
      columnTypes:{for(final column in table.columns) if(columnIds.contains(column.id)) column.id:column.type.name},
      definition: A2uiSavedDefinition.fromJson({'version': 1, 'components': [
        {'id': 'root', 'component': 'Table', 'columns': {'path': '/columns'},
          'rows': {'path': '/rows'}},
      ]}),
    ));

  Future<WorkspaceView> save(WorkspaceView view) async {
    final table = await _tables.table(view.tableId);
    if (!table.canManage || view.name.trim().isEmpty || view.name.length > 200 ||
        view.bindings.isEmpty || view.bindings.length > 50 ||
        !view.bindings.values.every((id) => table.columns.any((column) => column.id == id))) {
      throw const WorkspaceTableException();
    }
    if (view.columnTypes.length != view.bindings.values.toSet().length || !view.bindings.values.every((id) => view.columnTypes[id] == table.columns.firstWhere((column) => column.id == id).type.name)) throw const WorkspaceTableException();
    final _ = A2uiSavedDefinition.fromJson(view.definition.toJson());
    return _views.save(view);
  }

  Future<List<WorkspaceView>> history(String id) async {
    final current = await _views.read(id);
    final _ = await _tables.table(current.tableId);
    return _views.history(id);
  }

  Future<WorkspaceView> restore(WorkspaceView current, WorkspaceView previous) {
    if (current.id != previous.id) throw const WorkspaceTableException();
    return save(WorkspaceView(id: current.id, name: previous.name,
      tableId: previous.tableId, bindings: previous.bindings, columnTypes:previous.columnTypes, definition: previous.definition,
      revision: current.revision, parentId: previous.parentId));
  }
}
