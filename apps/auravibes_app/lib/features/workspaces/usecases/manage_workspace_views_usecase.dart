import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/query_workspace_records_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_view_projection.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_view_validation.dart';
import 'package:uuid/v7.dart';

class const ManageWorkspaceViewsUsecase(
  final WorkspaceViewRepository _views,
  final OrganizeWorkspaceTablesUsecase _tables,
  final QueryWorkspaceRecordsUsecase _query,
  final BrowseWorkspaceReferencesUsecase _references,
) {
  Future<List<WorkspaceView>> list({
    String? parentId,
    bool allFolders = false,
  }) async {
    final views = await _views.list(parentId: parentId, allFolders: allFolders);

    return await _visibleViews(views);
  }

  Future<WorkspaceViewData> open(String id) async {
    final view = await _views.read(id);
    final table = await _tables.table(view.tableId);
    final repair = WorkspaceViewValidation.needsRepair(view, table);
    final records = repair ? <WorkspaceRecord>[] : await _records(view);

    return _snapshot(view, table, records, needsRepair: repair);
  }

  Future<WorkspaceView> create({
    required String name,
    required WorkspaceTable table,
    required List<String> columnIds,
    String? parentId,
  }) => save(
    WorkspaceView.create(
      name: name,
      table: table,
      columnIds: columnIds,
      parentId: parentId,
    ),
  );

  Future<WorkspaceView> save(WorkspaceView view, {String? requestId}) async {
    final table = await _tables.table(view.tableId);
    WorkspaceViewValidation.check(view, table);

    return await _views.save(view, requestId: _operationId(requestId));
  }

  Future<List<WorkspaceView>> history(String id) async {
    final current = await _views.read(id);
    final _ = await _tables.table(current.tableId);

    return await _views.history(id);
  }

  Future<WorkspaceView> restore(
    WorkspaceView current,
    WorkspaceView previous, {
    String? requestId,
  }) {
    if (current.id != previous.id) throw const WorkspaceTableException();

    return save(previous.withRevision(current.revision), requestId: requestId);
  }

  Future<List<WorkspaceRecord>> _records(WorkspaceView view) async {
    final page = await _query(
      view.tableId,
      const WorkspaceRecordQuery(limit: 100),
    );

    return await WorkspaceViewProjection(
      _tables,
      _references,
    ).records(view, page.records);
  }

  Future<List<WorkspaceView>> _visibleViews(List<WorkspaceView> views) async {
    final result = <WorkspaceView>[];
    for (final view in views) {
      final visible = await _visibleView(view);
      if (visible != null) result.add(visible);
    }

    return result;
  }

  Future<WorkspaceView?> _visibleView(WorkspaceView view) async {
    try {
      final table = await _tables.table(view.tableId);

      return view.withManagement(value: table.canManage);
    } on Object {
      return null;
    }
  }
}

WorkspaceViewData _snapshot(
  WorkspaceView view,
  WorkspaceTable table,
  List<WorkspaceRecord> records, {
  required bool needsRepair,
}) =>
    .new(view: view, table: table, records: records, needsRepair: needsRepair);

String _operationId(String? requested) {
  final id = requested ?? const UuidV7().generate();
  if (id.isEmpty || id.length > 100) throw const WorkspaceTableException();
  return id;
}
