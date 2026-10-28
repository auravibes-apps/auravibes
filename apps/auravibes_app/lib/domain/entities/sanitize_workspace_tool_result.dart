import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Stored tool history is not an enduring grant to workspace data.
MessageToolCallEntity sanitizeWorkspaceToolResult(MessageToolCallEntity call) {
  if (!isWorkspaceToolName(call.name) ||
      !{
        'read',
        'readDirectory',
      }.contains(workspaceActionForTool(call.name, call.arguments)) ||
      (call.responseRaw == null &&
          call.responseContextRaw == null &&
          call.appData == null)) {
    return call;
  }

  if (call.resultStatus?.isFailure() ?? false) {
    final response = jsonEncode(
      workspaceFailureContext(call.responseContextRaw ?? call.responseRaw),
    );

    return call.copyWith(
      responseRaw: response,
      responseContextRaw: response,
      appData: null,
      outputTruncated: false,
      originalResponseBytes: null,
      fullOutputForContext: false,
    );
  }

  final response = call.name == workspaceReadTableToolName
      ? _safeTableSchemaResult(call)
      : _safeDirectoryResult(call);

  return call.copyWith(
    responseRaw: response,
    responseContextRaw: response,
    appData: null,
    outputTruncated: false,
    originalResponseBytes: null,
    fullOutputForContext: false,
  );
}

String _safeTableSchemaResult(MessageToolCallEntity call) {
  try {
    final raw = call.responseContextRaw ?? call.responseRaw;
    if (raw == null) return '{"redacted":true}';
    final value = jsonDecode(raw);
    if (value is! Map || value['columns'] is! List) {
      return '{"redacted":true}';
    }

    return jsonEncode({
      if (value['id'] is String) 'id': value['id'],
      'kind': 'table',
      if (value['name'] is String) 'name': value['name'],
      if (value['revision'] is int) 'revision': value['revision'],
      if (value['schemaRevision'] is int)
        'schemaRevision': value['schemaRevision'],
      if (value['labelColumnId'] is String)
        'labelColumnId': value['labelColumnId'],
      'columns': value['columns'],
    });
  } on FormatException {
    return '{"redacted":true}';
  }
}

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
          call.copyWith(
            argumentsRaw: jsonEncode(
              workspaceToolArgumentsForContext(call.name, call.arguments),
            ),
            responseRaw: call.isPending ? null : workspaceContextUnavailable,
            responseContextRaw: call.isPending
                ? null
                : workspaceContextUnavailable,
            appData: null,
            outputTruncated: false,
            originalResponseBytes: null,
            fullOutputForContext: false,
          )
        else
          call,
    ],
  );
}
