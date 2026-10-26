import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import 'workspace_conversation_commands.dart';

/// Refreshes selected authorized data at the provider boundary, not from
/// history.
class const WorkspacePromptProjection() {
  Future<List<Map<String, dynamic>>> call(
    Session session,
    ConversationTurn turn,
    List<Map<String, dynamic>> messages,
  ) async {
    final ids = _workspaceCallIds(messages);
    if (ids.isEmpty) return messages;
    final projection = await _freshProjection(session, turn, ids);

    return [for (final message in messages) _message(message, projection)];
  }

  Future<Map<String, String>> _freshProjection(
    Session session,
    ConversationTurn turn,
    Set<String> ids,
  ) async {
    final projection = <String, String>{};
    for (final id in ids) {
      projection[id] = await _fresh(session, turn, id);
    }

    return projection;
  }

  Future<String> _fresh(
    Session session,
    ConversationTurn turn,
    String id,
  ) async {
    final call = await _findCall(session, turn, id);
    if (call == null) return workspaceContextUnavailable;
    try {
      return await _freshFromCall(session, turn, call);
    } on Object {
      // Deleted, revoked, inaccessible, or unavailable records never replay.
      return workspaceContextUnavailable;
    }
  }

  Future<ConversationToolCall?> _findCall(
    Session session,
    ConversationTurn turn,
    String id,
  ) {
    final workspaceId = turn.workspaceId;
    final conversationId = turn.conversationId;
    final toolName = workspaceCommandToolName;

    return ConversationToolCall.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) &
          row.conversationId.equals(conversationId) &
          row.stableId.equals(id) &
          row.name.equals(toolName),
    );
  }

  Future<String> _freshFromCall(
    Session session,
    ConversationTurn turn,
    ConversationToolCall call,
  ) async {
    final input = jsonDecode(call.argumentsJson) as Map<String, dynamic>;
    final result = jsonDecode(call.resultJson ?? '{}');
    final fresh = await const WorkspaceConversationCommands().call(
      session,
      turn,
      'context-projection',
      workspaceContextReadArguments(input, result),
    );

    return projectToolOutput(jsonEncode(fresh)).text;
  }

  Map<String, dynamic> _message(
    Map<String, dynamic> message,
    Map<String, String> projection,
  ) {
    final id = message['tool_call_id'];
    if (message['role'] == 'tool' &&
        id is String &&
        projection.containsKey(id)) {
      return _projectToolMessage(message, projection[id]);
    }
    final calls = message['tool_calls'];
    if (calls is! List<Object?>) return message;

    return _projectToolCalls(message, calls, projection);
  }
}

Set<String> _workspaceCallIds(List<Map<String, dynamic>> messages) {
  final ids = <String>{};
  for (final message in messages) {
    final calls = message['tool_calls'];
    if (calls is List<Object?>) {
      ids.addAll(
        calls
            .whereType<Map<String, dynamic>>()
            .map(_workspaceCallId)
            .whereType<String>(),
      );
    }
  }

  return ids;
}

String? _workspaceCallId(Map<String, dynamic> call) {
  final function = call['function'];
  if (function is! Map<String, dynamic> ||
      function['name'] != workspaceCommandToolName ||
      call['id'] is! String) {
    return null;
  }

  return call['id'] as String;
}

Map<String, dynamic> _projectToolMessage(
  Map<String, dynamic> message,
  String? content,
) => {...message, 'content': content};

Map<String, dynamic> _projectToolCalls(
  Map<String, dynamic> message,
  List<Object?> calls,
  Map<String, String> projection,
) => {
  ...message,
  'tool_calls': [
    for (final value in calls) _projectToolCall(value, projection),
  ],
};

Object? _projectToolCall(Object? value, Map<String, String> projection) {
  if (value is! Map<String, dynamic> || !projection.containsKey(value['id'])) {
    return value;
  }

  return {
    ...value,
    'function': {
      ...value['function'] as Map<String, dynamic>,
      'arguments': '{"action":"read"}',
    },
  };
}
