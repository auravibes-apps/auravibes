import 'dart:convert';

import 'package:auravibes_engine/src/connector_command.dart';
import 'package:auravibes_engine/src/connectors/connector_definition.dart';
import 'package:auravibes_engine/src/connectors/connector_tool_definition.dart';
import 'package:auravibes_engine/src/connectors/execution/connector_write_executor.dart';
import 'package:auravibes_engine/src/connectors/execution/resolve_connector_request_template.dart';
import 'package:auravibes_engine/src/connectors/execution/run_connector_tool_template.dart';
import 'package:auravibes_engine/src/connectors/models/url_request_method.dart';
import 'package:auravibes_engine/src/connectors/models/url_response.dart';
import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';
import 'package:crypto/crypto.dart';

class const ConnectorRequestExecution({
  required final ConnectorToolTemplateExecutor executor,
  required final ConnectorDefinition connector,
  required final ConnectorToolDefinition tool,
  required final Map<String, dynamic> inputs,
  required final Map<String, String> credentials,
  required final String connectionId,
  required final String operationId,
  required final ConnectorWriteJournal journal,
}) {
  Future<Object> call() async {
    _validate();
    if (!connectorToolWrites(tool)) return await _read();
    if (operationId.isEmpty) {
      throw const FormatException('A write operation ID is required.');
    }
    return await _write();
  }

  void _validate() {
    final definition = tool.definition;
    if (definition == null) {
      throw const FormatException('Connector request is unavailable.');
    }
    const ResolveConnectorRequestTemplate()(
      template: definition.request,
      inputs: inputs,
      credentials: credentials,
      inputDefinitions: definition.inputs,
      schema: tool.inputJsonSchema,
      credentialDefinitions: definition.credentialDefinitions,
    );
  }

  Future<UrlResponse> _send() => executor
      .call(
        definition: tool.definition,
        inputs: inputs,
        credentials: credentials,
        schema: tool.inputJsonSchema,
      )
      .value;

  Future<String> _read() async {
    final response = await _send();
    if (response.isOk) return response.body;
    throw AgentToolExecutionFailure(
      responseRaw: jsonEncode({
        'outcome': 'failed',
        'statusCode': response.statusCode,
      }),
      error: const FormatException('Connector read did not complete.'),
      stackTrace: StackTrace.current,
      failurePhase: 'connector.read',
    );
  }

  Future<Object> _write() async {
    String? body;
    final receipt = await ConnectorWriteExecutor(journal).call(
      operationId: operationId,
      requestDigest: _digest(),
      execute: () async {
        final response = await _send();
        body = response.body;
        return response;
      },
    );
    return _result(receipt, body);
  }

  String _digest() => sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'tool': connectorToolId(connector, tool),
            'revision': connectorToolRevision(connector, tool),
            'connection': connectionId,
            'inputs': _canonical(inputs),
          }),
        ),
      )
      .toString();
}

bool connectorToolWrites(ConnectorToolDefinition tool) => !const {
  UrlRequestMethod.get,
  UrlRequestMethod.head,
}.contains(tool.urlTemplate?.template.method);

Object _result(ConnectorWriteReceipt receipt, String? body) {
  final result = <String, Object?>{
    ...receipt.toJson(),
    if (receipt.outcome == ConnectorWriteOutcome.completed && body != null)
      'response': body,
    'replayed': body == null,
  };
  if (receipt.outcome == ConnectorWriteOutcome.completed) return result;
  throw _failure(receipt, result);
}

AgentToolExecutionFailure _failure(
  ConnectorWriteReceipt receipt,
  Map<String, Object?> result,
) => AgentToolExecutionFailure(
  responseRaw: jsonEncode({...result, 'message': _message(receipt.outcome)}),
  error: const FormatException('Connector write did not complete.'),
  stackTrace: StackTrace.current,
  failurePhase: 'connector.write',
  resultStatus: receipt.outcome == ConnectorWriteOutcome.uncertain
      ? AgentToolResultStatus.uncertain
      : AgentToolResultStatus.executionError,
);

String _message(ConnectorWriteOutcome outcome) =>
    outcome == ConnectorWriteOutcome.uncertain
    ? 'Write outcome is uncertain. Retry is blocked until the provider '
          'confirms the result. Check the source; undo requires a '
          'supported compensating operation.'
    : 'The provider rejected the write. No automatic retry was performed.';

Object? _canonical(Object? value) => switch (value) {
  final Map<String, dynamic> map => {
    for (final key in map.keys.toList()..sort()) key: _canonical(map[key]),
  },
  final List<Object?> list => list.map(_canonical).toList(),
  _ => value,
};
