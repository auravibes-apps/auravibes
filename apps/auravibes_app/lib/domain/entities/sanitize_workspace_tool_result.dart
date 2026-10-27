import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Stored tool history is not an enduring grant to workspace data.
MessageToolCallEntity sanitizeWorkspaceToolResult(MessageToolCallEntity call) {
  if (call.name != workspaceCommandToolName ||
      workspaceContextAction(call.arguments) != 'read') {
    return call;
  }

  return call.copyWith(
    responseRaw: '{"redacted":true}',
    responseContextRaw: '{"redacted":true}',
    appData: null,
    outputTruncated: false,
    originalResponseBytes: null,
    fullOutputForContext: false,
  );
}
