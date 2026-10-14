import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;

class const ToolApprovalDecision({
  required final String toolCallId,
  required final ToolPermissionResult permissionResult,
  final String? permissionTableId,
}) {
  bool get needsConfirmation =>
      permissionResult == ToolPermissionResult.needsConfirmation;

  bool isGranted() => permissionResult == ToolPermissionResult.granted;

  ToolApprovalDecision withAutoApproval({required bool autoApproveTools}) {
    if (permissionResult != ToolPermissionResult.needsConfirmation) return this;
    final result = agent.applyAgentToolAutoApproval(
      .needsConfirmation,
      autoApproveTools: autoApproveTools,
    );
    if (result != agent.AgentToolPermissionResult.granted) return this;

    return ToolApprovalDecision(
      toolCallId: toolCallId,
      permissionResult: .granted,
      permissionTableId: permissionTableId,
    );
  }
}
