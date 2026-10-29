import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';

import '../../../generated/protocol.dart';

String safeWorkspaceResult(ConversationToolCall call, String result) {
  if (!isWorkspaceToolName(call.name)) return result;
  Object? arguments;
  try {
    arguments = jsonDecode(call.argumentsJson);
  } on FormatException {
    return '{}';
  }
  if (arguments is! Map<String, dynamic>) return '{}';
  final action = workspaceActionForTool(call.name, arguments);
  if (action != 'read' && action != 'readDirectory') {
    return result;
  }
  Object? value;
  try {
    value = jsonDecode(result);
  } on FormatException {
    return '{}';
  }
  return jsonEncode(workspaceDirectoryResultForContext(value) ?? {});
}
