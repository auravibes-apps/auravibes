import 'package:auravibes_engine/src/agent_tool_execution_service.dart';

/// Applies conversation auto-approval only after normal permission checks.
AgentToolPermissionResult applyAgentToolAutoApproval(
  AgentToolPermissionResult result, {
  required bool autoApproveTools,
}) => autoApproveTools && result == AgentToolPermissionResult.needsConfirmation
    ? AgentToolPermissionResult.granted
    : result;
