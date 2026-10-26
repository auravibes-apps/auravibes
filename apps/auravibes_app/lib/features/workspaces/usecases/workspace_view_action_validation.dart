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
    if (view.isConnectedOnly ||
        table == null ||
        table.id != view.tableId ||
        !view.bindings.values.toSet().containsAll(action.inputs.keys) ||
        action.inputs.keys.any(
          (id) => !table.columns.any((column) => column.id == id),
        )) {
      throw const WorkspaceTableException();
    }
  }
}
