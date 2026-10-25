import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
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
  final BrowseWorkspaceReferencesUsecase _references, {
  final bool canManageConnected = true,
  final Future<void> Function(WorkspaceConnectedBinding)? validateConnected,
}) {
  Future<List<WorkspaceView>> list({
    String? parentId,
    bool allFolders = false,
  }) async {
    final views = await _views.list(parentId: parentId, allFolders: allFolders);

    return await _visibleViews(views);
  }

  Future<WorkspaceViewData> open(String id, {int offset = 0}) async {
    final view = await _views.read(id);
    if (view.isConnectedOnly) {
      return _connectedSnapshot(view.withManagement(value: canManageConnected));
    }
    final table = await _tables.table(view.tableId);
    if (WorkspaceViewValidation.needsRepair(view, table)) {
      return _snapshot(view, table, []);
    }

    return await _readPage(view, table, offset);
  }

  Future<WorkspaceView> create({
    required String name,
    required WorkspaceTable table,
    required List<String> columnIds,
    String? parentId,
  }) => save(
    .create(name: name, table: table, columnIds: columnIds, parentId: parentId),
  );

  Future<WorkspaceView> save(WorkspaceView view, {String? requestId}) async {
    if (view.isConnectedOnly && !canManageConnected) {
      throw const WorkspaceTableException(denied: true);
    }
    final table = view.isConnectedOnly
        ? _connectedSnapshot(view).table
        : await _tables.table(view.tableId);
    WorkspaceViewValidation.check(view, table);
    if (view.connected case final binding?) {
      final authorize = validateConnected;
      if (authorize == null) throw const WorkspaceTableException(denied: true);
      await authorize(binding);
    }

    return await _views.save(view, requestId: _operationId(requestId));
  }

  Future<List<WorkspaceView>> history(String id) async {
    final current = await _views.read(id);
    if (!current.isConnectedOnly) {
      final _ = await _tables.table(current.tableId);
    }

    return await _views.history(id);
  }

  Future<WorkspaceView> restore(
    WorkspaceView current,
    WorkspaceView previous, {
    required String requestId,
  }) {
    if (current.id != previous.id) throw const WorkspaceTableException();

    return save(previous.withRevision(current.revision), requestId: requestId);
  }

  Future<WorkspaceViewData> _readPage(
    WorkspaceView view,
    WorkspaceTable table,
    int offset,
  ) async {
    final page = await _query(view.tableId, view.query.change(offset: offset));
    final records = await _project(view, page.records);
    final info = await _pageInfo(_query, view, page.hasMore, offset);

    return _snapshot(view, table, records, info);
  }

  Future<List<WorkspaceRecord>> _project(
    WorkspaceView view,
    List<WorkspaceRecord> records,
  ) => WorkspaceViewProjection(_tables, _references).records(view, records);
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
      if (view.isConnectedOnly) {
        return view.withManagement(value: canManageConnected);
      }
      final table = await _tables.table(view.tableId);

      return view.withManagement(value: table.canManage);
    } on Object {
      return null;
    }
  }
}

typedef _ViewPageInfo = ({
  bool hasMore,
  int offset,
  Map<String, Object?> summary,
});
WorkspaceViewData _snapshot(
  WorkspaceView view,
  WorkspaceTable table,
  List<WorkspaceRecord> records, [
  _ViewPageInfo? page,
]) => .new(
  view: view,
  table: table,
  records: records,
  needsRepair: page == null,
  hasMore: page?.hasMore ?? false,
  offset: page?.offset ?? 0,
  summary: page?.summary ?? const {},
);

String _operationId(String? requested) {
  final id = requested ?? const UuidV7().generate();
  if (id.isEmpty || id.length > _maximumOperationIdLength) {
    throw const WorkspaceTableException();
  }

  return id;
}

const _maximumOperationIdLength = 100;

Future<_ViewPageInfo> _pageInfo(
  QueryWorkspaceRecordsUsecase query,
  WorkspaceView view,
  bool hasMore,
  int offset,
) async => (
  hasMore: hasMore,
  offset: offset,
  summary: await query.repository.summarize(
    view.tableId,
    view.query,
    view.summaryColumnIds,
  ),
);

WorkspaceViewData _connectedSnapshot(WorkspaceView view) => .new(
  view: view,
  table: .new(
    id: '',
    name: view.name,
    labelColumnId: '',
    columns: const [],
    revision: view.revision,
    schemaRevision: 0,
    canManage: view.canManage,
  ),
  records: const [],
  needsRepair: false,
);
