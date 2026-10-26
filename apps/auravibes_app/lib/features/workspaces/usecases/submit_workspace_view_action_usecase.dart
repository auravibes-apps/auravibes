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

typedef WorkspaceConnectorActionRequest = ({
  String workspaceId,
  String viewId,
  int expectedRevision,
  A2uiSavedAction action,
  Map<String, Object?> formValues,
  Map<String, Object?> arguments,
  String operationId,
});

typedef WorkspaceConnectorActionExecutor = Future<Object?> Function(
  WorkspaceConnectorActionRequest request,
);

typedef _WorkspaceViewActionValues = ({
  A2uiSavedAction action,
  Map<String, Object?> formValues,
  WorkspaceTable? table,
  Map<String, Object?> inputs,
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
    required WorkspaceViewActionRequest request,
    required WorkspaceViewActionApproval approve,
  }) async {
    final submission = await _WorkspaceViewActionPreparation(
      views: views,
      tables: tables,
    ).prepare(request, approve);

    return await switch (submission.action.type) {
      .updateSelectedRecord => _WorkspaceViewOwnedActionSubmission(
        views: views,
        tables: tables,
        editRecords: editRecords,
      ).submit(submission),
      .connectorWrite => _WorkspaceViewConnectorActionSubmission(
        views: views,
        executeConnector: executeConnector,
      ).submit(submission),
    };
  }
}

class const _WorkspaceViewActionPreparation({
  required final WorkspaceViewRepository views,
  required final OrganizeWorkspaceTablesUsecase tables,
}) {
  Future<_PreparedWorkspaceViewAction> prepare(
    WorkspaceViewActionRequest request,
    WorkspaceViewActionApproval approve,
  ) async {
    final view = await _readCurrentView(request);
    final action = view.action;
    if (action == null) throw const WorkspaceTableException();
    final values = await _prepareValues(view, action, request.formValues);

    return _prepared(request, view, values, approve);
  }

  _PreparedWorkspaceViewAction _prepared(
    WorkspaceViewActionRequest request,
    WorkspaceView view,
    _WorkspaceViewActionValues values,
    WorkspaceViewActionApproval approve,
  ) => _PreparedWorkspaceViewAction(
    request: request,
    operationId: _operationId(request.requestId),
    view: view,
    action: values.action,
    formValues: values.formValues,
    table: values.table,
    inputs: values.inputs,
    approve: approve,
  );

  Future<_WorkspaceViewActionValues> _prepareValues(
    WorkspaceView view,
    A2uiSavedAction action,
    Map<String, Object?> values,
  ) async {
    final formValues = _normalize(view, values);
    final table = await _tableFor(view);
    WorkspaceViewActionValidation.check(view, table);

    return (
      action: action,
      formValues: formValues,
      table: table,
      inputs: _actionInputs(action, formValues),
    );
  }

  Future<WorkspaceView> _readCurrentView(
    WorkspaceViewActionRequest request,
  ) async {
    final view = await views.read(request.viewId);
    if (view.revision != request.expectedRevision) {
      throw const WorkspaceTableException(conflict: true);
    }

    return view;
  }

  Future<WorkspaceTable?> _tableFor(WorkspaceView view) async =>
      view.isConnectedOnly ? null : await tables.table(view.tableId);
}

class const _WorkspaceViewOwnedActionSubmission({
  required final WorkspaceViewRepository views,
  required final OrganizeWorkspaceTablesUsecase tables,
  required final EditWorkspaceRecordsUsecase editRecords,
}) {
  Future<Object?> submit(_PreparedWorkspaceViewAction submission) async {
    final change = await _change(submission);

    return await editRecords.apply(
      [change],
      requestId: submission.operationId,
      mode: submission.request.mode,
      approve: (_) => _approve(submission, change),
    );
  }

  Future<bool> _approve(
    _PreparedWorkspaceViewAction submission,
    WorkspaceRecordChange change,
  ) async {
    await _requireSubmissionView(submission);

    return await submission.approve(
      view: submission.view,
      action: submission.action,
      values: change.values,
    );
  }

  Future<WorkspaceRecordChange> _change(
    _PreparedWorkspaceViewAction submission,
  ) async {
    final table = _editableTable(submission.table);
    final recordId = _requiredRecordId(submission.request.recordId);
    final record = await tables.record(submission.view.tableId, recordId);
    final values = _values(table, record, submission);
    await _requireSubmissionView(submission);

    return WorkspaceRecordChange(table: table, record: record, values: values);
  }

  Future<void> _requireSubmissionView(
    _PreparedWorkspaceViewAction submission,
  ) => _requireCurrentView(
    views,
    submission.request.viewId,
    submission.request.expectedRevision,
  );

  WorkspaceTable _editableTable(WorkspaceTable? table) {
    if (table == null) throw const WorkspaceTableException();
    if (!table.canEditRecords) {
      throw const WorkspaceTableException(denied: true);
    }

    return table;
  }

  String _requiredRecordId(String? recordId) {
    if (recordId == null || recordId.isEmpty) {
      throw const WorkspaceTableException();
    }

    return recordId;
  }

  Map<String, Object?> _values(
    WorkspaceTable table,
    WorkspaceRecord record,
    _PreparedWorkspaceViewAction submission,
  ) {
    final values = _normalizeOwnedInputs(table, submission.inputs);
    if (!WorkspaceColumnValidation.accepts(table.columns, {
      ...record.values,
      ...values,
    })) {
      throw WorkspaceViewFormValidationException(
        _ownedInputErrors(table, record.values, submission.action, values),
      );
    }

    return values;
  }
}

class const _WorkspaceViewConnectorActionSubmission({
  required final WorkspaceViewRepository views,
  required final WorkspaceConnectorActionExecutor executeConnector,
}) {
  Future<Object?> submit(_PreparedWorkspaceViewAction submission) async {
    _validateConnectorArguments(submission.action, submission.inputs);
    if (!await _approve(submission)) return false;
    await _requireCurrentView(
      views,
      submission.request.viewId,
      submission.request.expectedRevision,
    );

    return await executeConnector(_request(submission));
  }

  Future<bool> _approve(_PreparedWorkspaceViewAction submission) async {
    if (submission.request.mode != .defaultMode) return true;

    return await submission.approve(
      view: submission.view,
      action: submission.action,
      values: submission.inputs,
    );
  }

  WorkspaceConnectorActionRequest _request(
    _PreparedWorkspaceViewAction submission,
  ) => (
    workspaceId: submission.request.workspaceId,
    viewId: submission.request.viewId,
    expectedRevision: submission.request.expectedRevision,
    action: submission.action,
    formValues: submission.formValues,
    arguments: submission.inputs,
    operationId: submission.operationId,
  );
}

class const WorkspaceViewActionRequest({
  required final String workspaceId,
  required final String viewId,
  required final int expectedRevision,
  required final Map<String, Object?> formValues,
  final String? recordId,
  final String? requestId,
  final ConversationToolAccessMode mode = .defaultMode,
});

class const _PreparedWorkspaceViewAction({
  required final WorkspaceViewActionRequest request,
  required final String operationId,
  required final WorkspaceView view,
  required final A2uiSavedAction action,
  required final Map<String, Object?> formValues,
  required final WorkspaceTable? table,
  required final Map<String, Object?> inputs,
  required final WorkspaceViewActionApproval approve,
});

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
  final connector = _connectorForAction(action);
  final tool = _toolForAction(connector, action);

  return (connector: connector, tool: tool);
}

ConnectorDefinition _connectorForAction(A2uiSavedAction action) {
  final connector = connectorDefinitions
      .where((connector) => _containsAction(connector, action))
      .firstOrNull;
  if (connector == null) throw const WorkspaceTableException();

  return connector;
}

bool _containsAction(ConnectorDefinition connector, A2uiSavedAction action) =>
    connector.tools.any(
      (tool) => connectorToolId(connector, tool) == action.toolId,
    );

ConnectorToolDefinition _toolForAction(
  ConnectorDefinition connector,
  A2uiSavedAction action,
) {
  final tool = connector.tools
      .where((tool) => connectorToolId(connector, tool) == action.toolId)
      .firstOrNull;
  if (tool == null) throw const WorkspaceTableException();

  return tool;
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
