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
    final ids = <String>{};
    for (final message in messages) {
      final calls = message['tool_calls'];
      if (calls is! List<Object?>) continue;
      for (final call in calls.whereType<Map<String, dynamic>>()) {
        final function = call['function'];
        if (function is Map<String, dynamic> &&
            function['name'] == workspaceCommandToolName &&
            call['id'] is String) {
          ids.add(call['id'] as String);
        }
      }
    }
    if (ids.isEmpty) return messages;
    final projection = <String, String>{};
    for (final id in ids) {
      projection[id] = await _fresh(session, turn, id);
    }

    return [for (final message in messages) _message(message, projection)];
  }

  Future<String> _fresh(
    Session session,
    ConversationTurn turn,
    String id,
  ) async {
    final call = await ConversationToolCall.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(turn.workspaceId) &
          row.conversationId.equals(turn.conversationId) &
          row.stableId.equals(id) &
          row.name.equals(workspaceCommandToolName),
    );
    if (call == null) return workspaceContextUnavailable;
    try {
      final input = jsonDecode(call.argumentsJson) as Map<String, dynamic>;
      final result = jsonDecode(call.resultJson ?? '{}');
      final fresh = await const WorkspaceConversationCommands().call(
        session,
        turn,
        'context-projection',
        workspaceContextReadArguments(input, result),
      );

      return projectToolOutput(jsonEncode(fresh)).text;
    } on Object {
      // Deleted, revoked, inaccessible, or unavailable records never replay.
      return workspaceContextUnavailable;
    }
  }

  Map<String, dynamic> _message(
    Map<String, dynamic> message,
    Map<String, String> projection,
  ) {
    final id = message['tool_call_id'];
    if (message['role'] == 'tool' &&
        id is String &&
        projection.containsKey(id)) {
      return {...message, 'content': projection[id]};
    }
    final calls = message['tool_calls'];
    if (calls is! List<Object?>) return message;

    return {
      ...message,
      'tool_calls': [
        for (final value in calls)
          if (value is Map<String, dynamic> &&
              projection.containsKey(value['id']))
            {
              ...value,
              'function': {
                ...value['function'] as Map<String, dynamic>,
                'arguments': '{"action":"read"}',
              },
            }
          else
            value,
      ],
    };
  }
}
