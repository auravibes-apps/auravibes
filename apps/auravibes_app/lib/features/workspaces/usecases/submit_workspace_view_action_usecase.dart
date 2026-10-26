import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/edit_workspace_records_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_view_action_validation.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:uuid/v7.dart';

typedef WorkspaceConnectorActionExecutor = Future<Object?> Function({
  required String workspaceId,
  required String viewId,
  required int expectedRevision,
  required A2uiSavedAction action,
  required Map<String, Object?> formValues,
  required Map<String, Object?> arguments,
  required String operationId,
});

typedef WorkspaceViewActionApproval = Future<bool> Function({
  required WorkspaceView view,
  required A2uiSavedAction action,
  required Map<String, Object?> values,
});

class const SubmitWorkspaceViewActionUsecase({
  required final WorkspaceViewRepository views,
  required final OrganizeWorkspaceTablesUsecase tables,
  required final EditWorkspaceRecordsUsecase editRecords,
  required final WorkspaceConnectorActionExecutor executeConnector,
}) {
  Future<Object?> call({
    required String workspaceId,
    required String viewId,
    required int expectedRevision,
    required Map<String, Object?> formValues,
    required WorkspaceViewActionApproval approve,
    String? recordId,
    String? requestId,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    final operationId = _operationId(requestId);
    final view = await views.read(viewId);
    if (view.revision != expectedRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
    final action = view.action;
    if (action == null) throw const WorkspaceTableException();
    final normalized = _normalize(view, formValues);
    final table = view.isConnectedOnly
        ? null
        : await tables.table(view.tableId);
    WorkspaceViewActionValidation.check(view, table);
    final inputs = _actionInputs(action, normalized);
    if (action.type == A2uiSavedActionType.updateSelectedRecord) {
      final ownedTable = table;
      if (ownedTable == null) throw const WorkspaceTableException();

      return await _updateOwned(
        view: view,
        table: ownedTable,
        tables: tables,
        action: action,
        inputs: inputs,
        recordId: recordId,
        expectedRevision: expectedRevision,
        operationId: operationId,
        mode: mode,
        approve: approve,
        editRecords: editRecords,
        views: views,
      );
    }

    return await _submitConnector(
      workspaceId: workspaceId,
      view: view,
      action: action,
      viewId: view.id,
      formValues: normalized,
      inputs: inputs,
      expectedRevision: expectedRevision,
      operationId: operationId,
      mode: mode,
      approve: approve,
      views: views,
      executeConnector: executeConnector,
    );
  }
}

Future<Object?> _updateOwned({
  required WorkspaceView view,
  required WorkspaceTable table,
  required OrganizeWorkspaceTablesUsecase tables,
  required A2uiSavedAction action,
  required Map<String, Object?> inputs,
  required String? recordId,
  required int expectedRevision,
  required String operationId,
  required ConversationToolAccessMode mode,
  required WorkspaceViewActionApproval approve,
  required EditWorkspaceRecordsUsecase editRecords,
  required WorkspaceViewRepository views,
}) async {
  if (!table.canEditRecords) throw const WorkspaceTableException(denied: true);
  if (recordId == null || recordId.isEmpty) {
    throw const WorkspaceTableException();
  }
  final record = await tables.record(view.tableId, recordId);
  final normalizedInputs = _normalizeOwnedInputs(table, inputs);
  final nextValues = {...record.values, ...normalizedInputs};
  if (!WorkspaceColumnValidation.accepts(table.columns, nextValues)) {
    throw WorkspaceViewFormValidationException(
      _ownedInputErrors(table, record.values, action, normalizedInputs),
    );
  }
  await _requireCurrentView(views, view.id, expectedRevision);

  return await editRecords.apply(
    [
      WorkspaceRecordChange(
        table: table,
        record: record,
        values: normalizedInputs,
      ),
    ],
    requestId: operationId,
    mode: mode,
    approve: (_) async {
      await _requireCurrentView(views, view.id, expectedRevision);

      return await approve(
        view: view,
        action: action,
        values: normalizedInputs,
      );
    },
  );
}

Future<Object?> _submitConnector({
  required String workspaceId,
  required WorkspaceView view,
  required A2uiSavedAction action,
  required String viewId,
  required Map<String, Object?> formValues,
  required Map<String, Object?> inputs,
  required int expectedRevision,
  required String operationId,
  required ConversationToolAccessMode mode,
  required WorkspaceViewActionApproval approve,
  required WorkspaceViewRepository views,
  required WorkspaceConnectorActionExecutor executeConnector,
}) async {
  _validateConnectorArguments(action, inputs);
  if (mode == .defaultMode &&
      !await approve(view: view, action: action, values: inputs)) {
    return false;
  }
  await _requireCurrentView(views, view.id, expectedRevision);

  return await executeConnector(
    workspaceId: workspaceId,
    viewId: viewId,
    expectedRevision: expectedRevision,
    action: action,
    formValues: formValues,
    arguments: inputs,
    operationId: operationId,
  );
}

Future<void> _requireCurrentView(
  WorkspaceViewRepository views,
  String id,
  int expectedRevision,
) async {
  if ((await views.read(id)).revision != expectedRevision) {
    throw const WorkspaceTableException(conflict: true);
  }
}

void _validateConnectorArguments(
  A2uiSavedAction action,
  Map<String, Object?> arguments,
) {
  final target = _connectorTarget(action);
  try {
    validateToolArguments(
      Map<String, Object?>.from(target.tool.inputJsonSchema),
      arguments,
    );
  } on FormatException catch (_, stackTrace) {
    Error.throwWithStackTrace(
      const WorkspaceViewFormValidationException({'/': 'connectorArguments'}),
      stackTrace,
    );
  }
}

({ConnectorDefinition connector, ConnectorToolDefinition tool})
_connectorTarget(A2uiSavedAction action) {
  for (final connector in connectorDefinitions) {
    for (final tool in connector.tools) {
      if (connectorToolId(connector, tool) == action.toolId) {
        return (connector: connector, tool: tool);
      }
    }
  }
  throw const WorkspaceTableException();
}

Map<String, Object?> _normalize(
  WorkspaceView view,
  Map<String, Object?> values,
) {
  final normalized = normalizeA2uiFormValues(
    components: view.definition.components,
    values: values,
  );
  final validation = validateA2uiFormValues(
    components: view.definition.components,
    values: normalized,
  );
  if (!validation.isValid) {
    throw WorkspaceViewFormValidationException(validation.errorsByPath);
  }

  return normalized;
}

Map<String, Object?> _actionInputs(
  A2uiSavedAction action,
  Map<String, Object?> formValues,
) {
  try {
    return a2uiSavedActionInputs(action, formValues);
  } on FormatException catch (_, stackTrace) {
    Error.throwWithStackTrace(
      WorkspaceViewFormValidationException({
        for (final path in action.inputs.values) path: 'required',
      }),
      stackTrace,
    );
  }
}

Map<String, Object?> _normalizeOwnedInputs(
  WorkspaceTable table,
  Map<String, Object?> inputs,
) => {
  for (final entry in inputs.entries)
    entry.key: _normalizeOwnedValue(
      table.columns.where((column) => column.id == entry.key).firstOrNull,
      entry.value,
    ),
};

Object? _normalizeOwnedValue(WorkspaceColumn? column, Object? value) =>
    switch ((type: column?.type, value: value)) {
      (type: .number, value: final String text) =>
        num.tryParse(text.trim()) ?? value,
      _ => value,
    };

Map<String, String> _ownedInputErrors(
  WorkspaceTable table,
  Map<String, Object?> existing,
  A2uiSavedAction action,
  Map<String, Object?> values,
) {
  final errors = <String, String>{};
  for (final entry in values.entries) {
    if (!WorkspaceColumnValidation.accepts(table.columns, {
      ...existing,
      entry.key: entry.value,
    })) {
      errors[action.inputs[entry.key] ?? '/'] = 'invalidValue';
    }
  }
  if (errors.isNotEmpty) return errors;

  return {for (final path in action.inputs.values) path: 'invalidValue'};
}

String _operationId(String? value) {
  final result = value ?? const UuidV7().generate();
  if (result.isEmpty || result.length > 100) {
    throw const WorkspaceTableException();
  }

  return result;
}

class const WorkspaceViewFormValidationException(
  final Map<String, String> errorsByPath,
) implements Exception;
