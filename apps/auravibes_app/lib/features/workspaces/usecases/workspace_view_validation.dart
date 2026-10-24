import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

const _maximumName = 200;
const _maximumBindings = 50;
final _bindingName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,63}$');

abstract final class WorkspaceViewValidation {
  static void check(WorkspaceView view, WorkspaceTable table) {
    if (!table.canManage) throw const WorkspaceTableException(denied: true);
    if (!_validConfiguration(view, table)) _invalid();
    final _ = A2uiSavedDefinition.fromJson(view.definition.toJson());
  }

  static bool needsRepair(WorkspaceView view, WorkspaceTable table) =>
      view.bindings.values.any((id) => !_typeMatches(view, id, table));
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
    !WorkspaceViewValidation.needsRepair(view, table) &&
    _validCount(view);
bool _validCount(WorkspaceView view) =>
    view.columnTypes.length == view.bindings.values.toSet().length;
