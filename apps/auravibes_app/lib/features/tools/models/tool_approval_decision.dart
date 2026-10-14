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

  ToolApprovalDecision withToolAccessMode({
    required agent.ConversationToolAccessMode mode,
  }) {
    if (permissionResult != ToolPermissionResult.needsConfirmation) return this;
    final result = agent.applyConversationToolAccessMode(
      .needsConfirmation,
      mode: mode,
    );
    if (result != agent.AgentToolPermissionResult.granted) return this;

    return ToolApprovalDecision(
      toolCallId: toolCallId,
      permissionResult: .granted,
      permissionTableId: permissionTableId,
    );
  }
}
