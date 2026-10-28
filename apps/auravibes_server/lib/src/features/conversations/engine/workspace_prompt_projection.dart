import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

typedef _ProjectedTool = ({String content, String argumentsJson});

/// Redacts archived workspace calls and keeps only results from the active
/// turn that the server tool executor already persisted.
class const WorkspacePromptProjection() {
  Future<List<Map<String, dynamic>>> call(
    Session session,
    ConversationTurn turn,
    List<Map<String, dynamic>> messages,
  ) async {
    final ids = _workspaceCallIds(messages);
    if (ids.isEmpty) return messages;
    final names = _workspaceCallNames(messages);
    final lastUser = messages.lastIndexWhere(
      (message) => message['role'] == 'user',
    );
    final currentIds = lastUser < 0
        ? <String>{}
        : _workspaceCallIds(messages.sublist(lastUser + 1));
    final projection = await _freshProjection(
      session,
      turn,
      ids,
      names,
      currentIds,
    );

    return [for (final message in messages) _message(message, projection)];
  }

  Future<Map<String, _ProjectedTool>> _freshProjection(
    Session session,
    ConversationTurn turn,
    Set<String> ids,
    Map<String, String> names,
    Set<String> currentIds,
  ) async {
    final projection = <String, _ProjectedTool>{};
    for (final id in ids) {
      projection[id] = await _fresh(
        session,
        turn,
        id,
        names[id] ?? workspaceReadDirectoryToolName,
        currentIds.contains(id),
      );
    }

    return projection;
  }

  Future<_ProjectedTool> _fresh(
    Session session,
    ConversationTurn turn,
    String id,
    String toolName,
    bool current,
  ) async {
    final call = await _findCall(session, turn, id);
    if (call == null) {
      return (
        content: workspaceContextUnavailable,
        argumentsJson: jsonEncode(
          workspaceToolArgumentsForContext(toolName, {}),
        ),
      );
    }
    try {
      final rawInput = jsonDecode(call.argumentsJson) as Map<String, dynamic>;
      final input = workspaceCommandArgumentsForTool(call.name, rawInput);
      final inCurrentTurn = current && call.turnId == turn.id;
      if (!inCurrentTurn) {
        return (
          content: workspaceContextUnavailable,
          argumentsJson: jsonEncode(
            workspaceToolArgumentsForContext(call.name, input),
          ),
        );
      }
      if (inCurrentTurn && call.status != 'success') {
        return (
          content: jsonEncode(workspaceFailureContext(call.resultJson)),
          argumentsJson: jsonEncode(
            workspaceToolArgumentsForContext(
              call.name,
              input,
              preserveAction: inCurrentTurn,
            ),
          ),
        );
      }
      final storedResult = jsonDecode(call.resultJson ?? '{}');
      return (
        content: projectToolOutput(
          jsonEncode({'outcome': 'success', 'current': storedResult}),
        ).text,
        argumentsJson: jsonEncode(
          workspaceToolArgumentsForContext(
            call.name,
            input,
            preserveAction: inCurrentTurn,
            preserveTargetIdentifiers: inCurrentTurn,
          ),
        ),
      );
    } on Object {
      // Deleted, revoked, inaccessible, or unavailable records never replay.
      return (
        content: workspaceContextUnavailable,
        argumentsJson: jsonEncode(
          workspaceToolArgumentsForContext(toolName, {}),
        ),
      );
    }
  }

  Future<ConversationToolCall?> _findCall(
    Session session,
    ConversationTurn turn,
    String id,
  ) {
    final workspaceId = turn.workspaceId;
    final conversationId = turn.conversationId;
    return ConversationToolCall.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) &
          row.conversationId.equals(conversationId) &
          row.stableId.equals(id) &
          row.name.inSet(workspaceToolNames),
    );
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

Map<String, String> _workspaceCallNames(List<Map<String, dynamic>> messages) {
  final names = <String, String>{};
  for (final message in messages) {
    final calls = message['tool_calls'];
    if (calls is! List<Object?>) continue;
    for (final value in calls.whereType<Map<String, dynamic>>()) {
      final function = value['function'];
      final id = value['id'];
      if (function is Map<String, dynamic> &&
          id is String &&
          function['name'] is String &&
          isWorkspaceToolName(function['name'] as String)) {
        names[id] = function['name'] as String;
      }
    }
  }

  return names;
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
      function['name'] is! String ||
      !isWorkspaceToolName(function['name'] as String) ||
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
      'arguments': projection[value['id']]!.argumentsJson,
    },
  };
}
