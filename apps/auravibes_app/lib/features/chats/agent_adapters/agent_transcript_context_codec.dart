import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class AgentTranscriptContextCodec {
  static String encodeUpdate(AgentTranscriptContextUpdate update) =>
      jsonEncode(_updateToJson(update));

  static AgentTranscriptContextUpdate decodeUpdate(String content) {
    final update = _tryDecodeUpdate(content);
    if (update == null) {
      throw const AgentTranscriptContextException('invalid stored update');
    }

    return update;
  }
}

Map<String, Object?> _updateToJson(AgentTranscriptContextUpdate update) => {
  'version': 1,
  'toolsAdded': _encodeTools(update.toolsAdded),
  'toolsRemoved': update.toolsRemoved,
  if (update.contextMessages case final messages?)
    'contextMessages': _encodeMessages(messages),
  'toolOrder': ?update.toolOrder,
  'approvalStates': ?update.approvalStates,
};

List<Map<String, Object?>> _encodeTools(List<ToolSpec> tools) => [
  for (final tool in tools)
    {
      'name': tool.name,
      'description': tool.description,
      'inputJsonSchema': tool.inputJsonSchema,
      'requiresCredential': tool.requiresCredential,
    },
];

List<Map<String, Object?>> _encodeMessages(
  List<AgentContextMessage> messages,
) => [for (final message in messages) _encodeMessage(message)];

Map<String, Object?> _encodeMessage(AgentContextMessage message) => {
  'role': message.role.name,
  'content': message.content,
  'kind': ?message.kind,
};

AgentTranscriptContextUpdate? _tryDecodeUpdate(String content) {
  try {
    final data = jsonDecode(content);
    if (data is! Map<String, Object?> || data['version'] != 1) return null;

    return _decodeUpdate(data);
  } on Object catch (_) {
    return null;
  }
}

AgentTranscriptContextUpdate _decodeUpdate(Map<String, Object?> data) =>
    AgentTranscriptContextUpdate(
      contextMessages: _decodeMessages(data['contextMessages']),
      toolsAdded: _decodeTools(data['toolsAdded']),
      toolsRemoved: _decodeRemovedTools(data['toolsRemoved']),
      toolOrder: _decodeToolOrder(data['toolOrder']),
      approvalStates: _decodeApprovalStates(data['approvalStates']),
    );

List<ToolSpec> _decodeTools(Object? value) => [
  for (final item in _requiredObjectList(value)) _decodeTool(item),
];

List<String> _decodeRemovedTools(Object? value) =>
    List<String>.from(_requiredObjectList(value));

List<Object?> _requiredObjectList(Object? value) {
  if (value is! List<Object?>) throw const FormatException();

  return value;
}

List<AgentContextMessage>? _decodeMessages(Object? value) => value == null
    ? null
    : [for (final item in _asObjectList(value)) _decodeMessage(item)];

List<String>? _decodeToolOrder(Object? value) =>
    value == null ? null : List<String>.from(_asObjectList(value));

Map<String, String>? _decodeApprovalStates(Object? value) =>
    value == null ? null : Map<String, String>.from(_asObjectMap(value));

AgentContextMessage _decodeMessage(Object? value) {
  final data = _asObjectMap(value);

  return AgentContextMessage(
    role: AgentContextMessageRole.values.byName(_requiredString(data, 'role')),
    content: _requiredString(data, 'content'),
    kind: _optionalString(data, 'kind'),
  );
}

ToolSpec _decodeTool(Object? value) {
  final data = _asObjectMap(value);

  return ToolSpec(
    name: _requiredString(data, 'name'),
    description: _requiredString(data, 'description'),
    inputJsonSchema: _requiredObjectMap(data, 'inputJsonSchema'),
    requiresCredential: _requiredBool(data, 'requiresCredential'),
  );
}

Map<String, Object?> _requiredObjectMap(
  Map<String, Object?> data,
  String key,
) => _asObjectMap(data[key]);

Map<String, Object?> _asObjectMap(Object? value) {
  if (value is! Map<String, Object?>) throw const FormatException();

  return value;
}

List<Object?> _asObjectList(Object value) {
  if (value is! List<Object?>) throw const FormatException();

  return value;
}

String _requiredString(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! String) throw const FormatException();

  return value;
}

String? _optionalString(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value == null) return null;
  if (value is! String) throw const FormatException();

  return value;
}

bool _requiredBool(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! bool) throw const FormatException();

  return value;
}
