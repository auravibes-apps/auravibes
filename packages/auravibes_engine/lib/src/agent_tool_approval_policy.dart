import 'package:auravibes_engine/src/agent_tool_execution_service.dart';
import 'package:auravibes_engine/src/conversation_tool_access_mode.dart';

/// Applies conversation tool access mode after normal permission checks.
AgentToolPermissionResult applyConversationToolAccessMode(
  AgentToolPermissionResult result, {
  required ConversationToolAccessMode mode,
}) =>
    mode == ConversationToolAccessMode.allowAll &&
        result == AgentToolPermissionResult.needsConfirmation
    ? AgentToolPermissionResult.granted
    : result;
