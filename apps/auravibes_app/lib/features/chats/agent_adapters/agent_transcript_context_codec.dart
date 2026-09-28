import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';

String encodeAgentTranscriptContextUpdate(AgentTranscriptContextUpdate update) {
  final data = <String, Object?>{
    'version': 1,
    'toolsAdded': [
      for (final tool in update.toolsAdded)
        {
          'name': tool.name,
          'description': tool.description,
          'inputJsonSchema': tool.inputJsonSchema,
          'requiresCredential': tool.requiresCredential,
        },
    ],
    'toolsRemoved': update.toolsRemoved,
  };
  if (update.contextMessages case final messages?) {
    data['contextMessages'] = [
      for (final message in messages) _encodeMessage(message),
    ];
  }
  if (update.toolOrder case final order?) data['toolOrder'] = order;
  if (update.approvalStates case final states?) {
    data['approvalStates'] = states;
  }

  return jsonEncode(data);
}

Map<String, Object?> _encodeMessage(AgentContextMessage message) {
  final data = <String, Object?>{
    'role': message.role.name,
    'content': message.content,
  };
  if (message.kind case final kind?) data['kind'] = kind;

  return data;
}

AgentTranscriptContextUpdate decodeAgentTranscriptContextUpdate(
  String content,
) {
  final update = _tryDecodeUpdate(content);
  if (update == null) {
    throw const AgentTranscriptContextException('invalid stored update');
  }

  return update;
}

AgentTranscriptContextUpdate? _tryDecodeUpdate(String content) {
  try {
    final data = jsonDecode(content);
    if (data is! Map<String, Object?> || data['version'] != 1) return null;
    final messages = data['contextMessages'];
    final order = data['toolOrder'];
    final approvals = data['approvalStates'];
    final added = data['toolsAdded'];
    final removed = data['toolsRemoved'];
    if (added is! List<Object?> || removed is! List<Object?>) return null;
    List<AgentContextMessage>? decodedMessages;
    if (messages != null) {
      if (messages is! List<Object?>) return null;
      decodedMessages = [for (final value in messages) _decodeMessage(value)];
    }
    List<String>? decodedOrder;
    if (order != null) {
      if (order is! List<Object?>) return null;
      decodedOrder = List<String>.from(order);
    }
    Map<String, String>? decodedApprovals;
    if (approvals != null) {
      if (approvals is! Map<String, Object?>) return null;
      decodedApprovals = Map<String, String>.from(approvals);
    }

    return AgentTranscriptContextUpdate(
      contextMessages: decodedMessages,
      toolsAdded: [for (final value in added) _decodeTool(value)],
      toolsRemoved: List<String>.from(removed),
      toolOrder: decodedOrder,
      approvalStates: decodedApprovals,
    );
  } on Object catch (_) {
    return null;
  }
}

AgentContextMessage _decodeMessage(Object? value) {
  if (value is! Map<String, Object?>) throw const FormatException();
  final role = value['role'];
  final content = value['content'];
  final kindValue = value['kind'];
  if (role is! String || content is! String) {
    throw const FormatException();
  }
  String? kind;
  if (kindValue != null) {
    if (kindValue is! String) throw const FormatException();
    kind = kindValue;
  }

  return AgentContextMessage(
    role: AgentContextMessageRole.values.byName(role),
    content: content,
    kind: kind,
  );
}

ToolSpec _decodeTool(Object? value) {
  if (value is! Map<String, Object?>) throw const FormatException();
  final name = value['name'];
  final description = value['description'];
  final schema = value['inputJsonSchema'];
  final requiresCredential = value['requiresCredential'];
  if (name is! String ||
      description is! String ||
      schema is! Map<String, Object?> ||
      requiresCredential is! bool) {
    throw const FormatException();
  }

  return ToolSpec(
    name: name,
    description: description,
    inputJsonSchema: schema,
    requiresCredential: requiresCredential,
  );
}
