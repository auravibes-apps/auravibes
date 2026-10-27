import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import 'workspace_conversation_commands.dart';

typedef _ProjectedTool = ({String content, String action});

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
    final lastUser = messages.lastIndexWhere(
      (message) => message['role'] == 'user',
    );
    final currentIds = lastUser < 0
        ? <String>{}
        : _workspaceCallIds(messages.sublist(lastUser + 1));
    final projection = await _freshProjection(session, turn, ids, currentIds);

    return [for (final message in messages) _message(message, projection)];
  }

  Future<Map<String, _ProjectedTool>> _freshProjection(
    Session session,
    ConversationTurn turn,
    Set<String> ids,
    Set<String> currentIds,
  ) async {
    final projection = <String, _ProjectedTool>{};
    for (final id in ids) {
      projection[id] = await _fresh(session, turn, id, currentIds.contains(id));
    }

    return projection;
  }

  Future<_ProjectedTool> _fresh(
    Session session,
    ConversationTurn turn,
    String id,
    bool current,
  ) async {
    final call = await _findCall(session, turn, id);
    if (call == null)
      return (content: workspaceContextUnavailable, action: 'read');
    try {
      final input = jsonDecode(call.argumentsJson) as Map<String, dynamic>;
      final inCurrentTurn = current && call.turnId == turn.id;
      final action = inCurrentTurn ? workspaceContextAction(input) : 'read';
      if (inCurrentTurn && call.status != 'success') {
        return (content: jsonEncode({'outcome': 'failed'}), action: action);
      }
      final fresh = await _freshFromCall(session, turn, call, input);
      return (
        content: projectToolOutput(
          jsonEncode(inCurrentTurn ? {'outcome': 'success', 'current': fresh} : fresh),
        ).text,
        action: action,
      );
    } on Object {
      // Deleted, revoked, inaccessible, or unavailable records never replay.
      return (content: workspaceContextUnavailable, action: 'read');
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

  Future<Object?> _freshFromCall(
    Session session,
    ConversationTurn turn,
    ConversationToolCall call,
    Map<String, dynamic> input,
  ) async {
    final result = jsonDecode(call.resultJson ?? '{}');
    final fresh = await const WorkspaceConversationCommands().call(
      session,
      turn,
      'context-projection',
      workspaceContextReadArguments(input, result),
    );

    return fresh;
  }

  Map<String, dynamic> _message(
    Map<String, dynamic> message,
    Map<String, _ProjectedTool> projection,
  ) {
    final id = message['tool_call_id'];
    if (message['role'] == 'tool' &&
        id is String &&
        projection.containsKey(id)) {
      return _projectToolMessage(message, projection[id]?.content);
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
  Map<String, _ProjectedTool> projection,
) => {
  ...message,
  'tool_calls': [
    for (final value in calls) _projectToolCall(value, projection),
  ],
};

Object? _projectToolCall(
  Object? value,
  Map<String, _ProjectedTool> projection,
) {
  if (value is! Map<String, dynamic> || !projection.containsKey(value['id'])) {
    return value;
  }

  return {
    ...value,
    'function': {
      ...value['function'] as Map<String, dynamic>,
      'arguments': jsonEncode({'action': projection[value['id']]!.action}),
    },
  };
}
