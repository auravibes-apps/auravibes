import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class WorkspaceViewActionValidation {
  static void check(WorkspaceView view, [WorkspaceTable? table]) {
    final action = view.action;
    if (action == null) return;
    validateA2uiSavedActionInputs(action, view.definition.components);
    switch (action.type) {
      case .updateSelectedRecord:
        _owned(view, table, action);
      case .connectorWrite:
        validateA2uiSavedActionConnector(action, connectorDefinitions);
    }
  }

  static void _owned(
    WorkspaceView view,
    WorkspaceTable? table,
    A2uiSavedAction action,
  ) {
    if (!_ownsTable(view, table) ||
        !_inputsAreBound(view, action) ||
        !_inputColumnsExist(table, action)) {
      throw const WorkspaceTableException();
    }
  }

  static bool _ownsTable(WorkspaceView view, WorkspaceTable? table) =>
      !view.isConnectedOnly && table != null && table.id == view.tableId;

  static bool _inputsAreBound(WorkspaceView view, A2uiSavedAction action) =>
      view.bindings.values.toSet().containsAll(action.inputs.keys);

  static bool _inputColumnsExist(
    WorkspaceTable? table,
    A2uiSavedAction action,
  ) =>
      table != null &&
      action.inputs.keys.every(
        (id) => table.columns.any((column) => column.id == id),
      );
}
