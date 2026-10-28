import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Stored tool history is not an enduring grant to workspace data.
MessageToolCallEntity sanitizeWorkspaceToolResult(MessageToolCallEntity call) {
  if (!_isReadWithOutput(call)) return call;
  final response = _safeResponse(call);

  return call.copyWith(
    responseRaw: response,
    responseContextRaw: response,
    appData: null,
    outputTruncated: false,
    originalResponseBytes: null,
    fullOutputForContext: false,
  );
}

bool _isReadWithOutput(MessageToolCallEntity call) {
  if (!isWorkspaceToolName(call.name)) return false;
  if (!{
    'read',
    'readDirectory',
  }.contains(workspaceActionForTool(call.name, call.arguments))) {
    return false;
  }

  return call.responseRaw != null ||
      call.responseContextRaw != null ||
      call.appData != null;
}

String _safeResponse(MessageToolCallEntity call) {
  if (call.resultStatus?.isFailure() ?? false) {
    return jsonEncode(
      workspaceFailureContext(call.responseContextRaw ?? call.responseRaw),
    );
  }

  return call.name == workspaceReadTableToolName
      ? _safeTableSchemaResult(call)
      : _safeDirectoryResult(call);
}

String _safeTableSchemaResult(MessageToolCallEntity call) {
  try {
    final raw = call.responseContextRaw ?? call.responseRaw;
    if (raw == null) return '{"redacted":true}';
    final value = jsonDecode(raw);
    if (value is! Map || value['columns'] is! List) {
      return '{"redacted":true}';
    }

    return jsonEncode(_tableSchema(value));
  } on FormatException {
    return '{"redacted":true}';
  }
}

Map<String, Object?> _tableSchema(Map<dynamic, dynamic> value) => {
  if (value['id'] is String) 'id': value['id'],
  'kind': 'table',
  if (value['name'] is String) 'name': value['name'],
  if (value['revision'] is int) 'revision': value['revision'],
  if (value['schemaRevision'] is int) 'schemaRevision': value['schemaRevision'],
  if (value['labelColumnId'] is String) 'labelColumnId': value['labelColumnId'],
  'columns': value['columns'],
};

String _safeDirectoryResult(MessageToolCallEntity call) {
  try {
    final raw = call.responseContextRaw ?? call.responseRaw;
    if (raw == null) return '{"redacted":true}';
    final result = workspaceDirectoryResultForContext(jsonDecode(raw));
    if (result != null) return jsonEncode(result);
  } on FormatException {
    // Invalid tool output stays redacted.
  }

  return '{"redacted":true}';
}

MessageMetadataEntity sanitizeWorkspaceToolMetadata(
  MessageMetadataEntity metadata,
) => metadata.copyWith(
  toolCalls: [
    for (final call in metadata.toolCalls) sanitizeWorkspaceToolResult(call),
  ],
);

/// Materialized fork history cannot grant access to its source tool results.
MessageMetadataEntity redactInheritedWorkspaceToolMetadata(
  MessageMetadataEntity metadata,
) {
  if (!metadata.toolCalls.any((call) => isWorkspaceToolName(call.name))) {
    return metadata;
  }

  return metadata.copyWith(
    toolCalls: [
      for (final call in metadata.toolCalls)
        if (isWorkspaceToolName(call.name))
          _redactInheritedCall(call)
        else
          call,
    ],
  );
}

MessageToolCallEntity _redactInheritedCall(MessageToolCallEntity call) {
  final response = call.isPending ? null : workspaceContextUnavailable;

  return call.copyWith(
    argumentsRaw: jsonEncode(
      workspaceToolArgumentsForContext(call.name, call.arguments),
    ),
    responseRaw: response,
    responseContextRaw: response,
    appData: null,
    outputTruncated: false,
    originalResponseBytes: null,
    fullOutputForContext: false,
  );
}
