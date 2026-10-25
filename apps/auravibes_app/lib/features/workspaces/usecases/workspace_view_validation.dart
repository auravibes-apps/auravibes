import 'package:auravibes_app/features/workspaces/models/workspace_query_filter_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/project_connected_workspace_view_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/read_connected_workspace_view_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

const _maximumName = 200;
const _maximumBindings = 50;
const _maximumPageSize = 100;
const _maximumSearchLength = 200;
final _bindingName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,63}$');

abstract final class WorkspaceViewValidation {
  static void check(WorkspaceView view, WorkspaceTable table) {
    if (view.isConnectedOnly) {
      if (view.connected == null ||
          !_validName(view.name) ||
          !_validSourceBindings(view.bindings)) {
        _invalid();
      }
      ReadConnectedWorkspaceViewUsecase.validate(view.connected!);
      ProjectConnectedWorkspaceViewUsecase.validate(view.bindings);
      final _ = A2uiSavedDefinition.fromJson(view.definition.toJson());
      return;
    }
    if (!table.canManage) throw const WorkspaceTableException(denied: true);
    if (!_validConfiguration(view, table)) _invalid();
    _checkQuery(view, table);
    if (view.connected case final connected?) {
      ReadConnectedWorkspaceViewUsecase.validate(connected);
    }
    final _ = A2uiSavedDefinition.fromJson(view.definition.toJson());
  }

  static bool needsRepair(WorkspaceView view, WorkspaceTable table) =>
      view.columnTypes.keys.any((id) => !_typeMatches(view, id, table)) ||
      !_dependencies(view).every(view.columnTypes.containsKey) ||
      !_queryCompatible(view, table);
}

bool _typeMatches(WorkspaceView view, String id, WorkspaceTable table) {
  final column = table.columns.where((column) => column.id == id).firstOrNull;

  return column != null && view.columnTypes[id] == column.type.name;
}

bool _validName(String name) =>
    name.trim().isNotEmpty && name.length <= _maximumName;
bool _validBindings(Map<String, String> bindings) =>
    bindings.isNotEmpty &&
    bindings.length <= _maximumBindings &&
    bindings.keys.every(_validBindingName);
bool _validBindingName(String name) =>
    _bindingName.hasMatch(name) && name != 'columns' && name != 'rows';
Never _invalid() => throw const WorkspaceTableException();

bool _validConfiguration(WorkspaceView view, WorkspaceTable table) =>
    _validName(view.name) &&
    _validBindings(view.bindings) &&
    _validSummary(view) &&
    !WorkspaceViewValidation.needsRepair(view, table) &&
    _validCount(view);
bool _validCount(WorkspaceView view) =>
    view.columnTypes.length == _dependencies(view).length;

void _checkQuery(WorkspaceView view, WorkspaceTable table) {
  _checkPage(view.query);
  _checkSort(view.query, table);
  _checkFilter(view.query, table);
}

void _checkPage(WorkspaceRecordQuery query) {
  if (query.offset != 0 ||
      query.limit < 1 ||
      query.limit > _maximumPageSize ||
      query.search.length > _maximumSearchLength) {
    _invalid();
  }
}

void _checkSort(WorkspaceRecordQuery query, WorkspaceTable table) {
  final sort = _queryColumn(table, query.sortColumnId ?? table.labelColumnId);
  if (!WorkspaceQueryFilterValidation.supports(sort)) _invalid();
}

void _checkFilter(WorkspaceRecordQuery query, WorkspaceTable table) {
  final id = query.filterColumnId;
  if (id == null) return;
  final column = _queryColumn(table, id);
  final _ = WorkspaceQueryFilterValidation.parse(
    column,
    query.filterValue ?? '',
    contains: query.filterOperator == .contains,
  );
}

WorkspaceColumn _queryColumn(WorkspaceTable table, String id) {
  final column = table.columns.where((column) => column.id == id).firstOrNull;
  if (column == null) _invalid();

  return column;
}

Set<String> _dependencies(WorkspaceView view) => {
  ...view.bindings.values,
  ...view.summaryColumnIds,
  ?view.query.filterColumnId,
  ?view.query.sortColumnId,
};

bool _validSummary(WorkspaceView view) =>
    view.summaryColumnIds.length <= _maximumBindings &&
    view.summaryColumnIds.length == view.summaryColumnIds.toSet().length;

bool _queryCompatible(WorkspaceView view, WorkspaceTable table) {
  try {
    _checkQuery(view, table);

    return true;
  } on WorkspaceTableException {
    return false;
  }
}

bool _validSourceBindings(Map<String, String> bindings) =>
    bindings.isNotEmpty &&
    bindings.length <= _maximumBindings &&
    bindings.keys.every(_bindingName.hasMatch);
